import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/job_request.dart';
import '../location_service.dart';
import 'worker_timer_screen.dart';

class WorkerNavigationScreen extends StatefulWidget {
  final JobRequest job;

  const WorkerNavigationScreen({super.key, required this.job});

  @override
  State<WorkerNavigationScreen> createState() => _WorkerNavigationScreenState();
}

class _WorkerNavigationScreenState extends State<WorkerNavigationScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<DocumentSnapshot>? _locationSub;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _workerPosition;
  String _etaText = 'Calculating...';
  String _distanceText = '';
  bool _isArriving = false;
  late LatLng _customerLatLng;

  String _jobStatus = 'inProgress';
  StreamSubscription<DocumentSnapshot>? _jobStatusSub;

  bool _isStartingJob = false;
  String? _currentWorkerId;
  String? _resolvedCustomerPhone;

  @override
  void initState() {
    super.initState();
    _currentWorkerId = FirebaseAuth.instance.currentUser?.uid;

    // Convert GeoPoint to LatLng safely
    if (widget.job.customerLocation != null) {
      _customerLatLng = LatLng(
        widget.job.customerLocation!.latitude,
        widget.job.customerLocation!.longitude,
      );
    } else {
      _customerLatLng = LatLng(widget.job.customerLat, widget.job.customerLng);
    }

    // Navigation start logic
    if (widget.job.status == 'customerConfirmed' ||
        widget.job.status == 'searching') {
      FirebaseFirestore.instance
          .collection('jobRequests')
          .doc(widget.job.id)
          .update({
        'status': 'inProgress',
        'navigationStartedAt': FieldValue.serverTimestamp(),
      });
    }

    _jobStatus = widget.job.status;
    LocationService.instance.startNavigationTracking(jobId: widget.job.id);
    _setInitialWorkerPositionFallback();
    _listenToWorkerLocation();
    _listenToJobStatus();
    _resolveCustomerPhone();
  }

  Future<void> _resolveCustomerPhone() async {
    if (_resolvedCustomerPhone != null && _resolvedCustomerPhone!.trim().isNotEmpty) {
      return;
    }

    String? resolved;

    // 1. Try from job model
    final fromJobModel = widget.job.customerPhone?.toString().trim();
    debugPrint('[CALL] Job model customerPhone: "$fromJobModel"');
    debugPrint('[CALL] Job customerId: "${widget.job.customerId}"');
    if (fromJobModel != null && fromJobModel.isNotEmpty) {
      resolved = fromJobModel;
    }

    // 2. Try from customers collection using customerId → field: phone
    if (resolved == null || resolved.isEmpty) {
      String customerId = widget.job.customerId.trim();

      // If customerId is empty, get it from jobRequests doc
      if (customerId.isEmpty) {
        try {
          final jobDoc = await FirebaseFirestore.instance
              .collection('jobRequests')
              .doc(widget.job.id)
              .get();
          customerId = (jobDoc.data()?['customerId'] ?? '').toString().trim();
          debugPrint('[CALL] customerId from jobRequests doc: "$customerId"');
        } catch (e) {
          debugPrint('[CALL] Error reading jobRequests: $e');
        }
      }

      if (customerId.isNotEmpty) {
        try {
          // First try direct doc lookup
          var customerDoc = await FirebaseFirestore.instance
              .collection('customers')
              .doc(customerId)
              .get();
          
          // If not found or no phone, query by uid field
          if (!customerDoc.exists || customerDoc.data()?['phone'] == null) {
            debugPrint('[CALL] Direct doc not found or no phone, querying by uid field...');
            final query = await FirebaseFirestore.instance
                .collection('customers')
                .where('uid', isEqualTo: customerId)
                .limit(1)
                .get();
            if (query.docs.isNotEmpty) {
              customerDoc = query.docs.first;
              debugPrint('[CALL] Found customer by uid query: ${customerDoc.id}');
            }
          }

          final cData = customerDoc.data();
          debugPrint('[CALL] Customer doc exists: ${customerDoc.exists}');
          debugPrint('[CALL] Customer doc keys: ${cData?.keys.toList()}');
          
          if (cData != null && cData.containsKey('phone') && cData['phone'] != null) {
            final phone = cData['phone'].toString().trim();
            debugPrint('[CALL] Resolved phone: "$phone"');
            if (phone.isNotEmpty && phone != 'null') {
              resolved = phone;
            }
          }
        } catch (e) {
          debugPrint('[CALL] Error reading customers doc: $e');
        }
      } else {
        debugPrint('[CALL] No customerId available — cannot look up phone');
      }
    }

    debugPrint('[CALL] Final resolved phone: "$resolved"');
    if (mounted && resolved != null && resolved.isNotEmpty) {
      setState(() => _resolvedCustomerPhone = resolved);
    }
  }

  Future<void> _setInitialWorkerPositionFallback() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;

      final initial = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _workerPosition = initial;
      });
      _updateMarkers(initial);
      _updatePolyline(initial);
    } catch (e) {
      debugPrint('[NAVIGATION] Initial GPS fallback failed: $e');
    }
  }

  void _listenToJobStatus() {
    _jobStatusSub = FirebaseFirestore.instance
        .collection('jobRequests')
        .doc(widget.job.id)
        .snapshots()
        .listen((doc) {
      if (!doc.exists || !mounted) return;
      final data = doc.data()!;
      final status = data['status'];

      if (data['customerLocation'] is GeoPoint) {
        final geo = data['customerLocation'] as GeoPoint;
        final newCustomerLatLng = LatLng(geo.latitude, geo.longitude);

        if (newCustomerLatLng.latitude != _customerLatLng.latitude ||
            newCustomerLatLng.longitude != _customerLatLng.longitude) {
          _customerLatLng = newCustomerLatLng;
          if (_workerPosition != null) {
            _updateMarkers(_workerPosition!);
            _updatePolyline(_workerPosition!);
          }
        }
      }

      setState(() {
        _jobStatus = status;
      });

      // ✅ Navigate to timer screen when work starts
      if (status == 'workStarted' && mounted) {
        _jobStatusSub?.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => WorkerTimerScreen(job: widget.job),
          ),
        );
      }
    });
  }


  void _listenToWorkerLocation() {
    final workerId = _currentWorkerId;
    if (workerId == null) return;

    _locationSub = FirebaseFirestore.instance
        .collection('workers')
        .doc(workerId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists || !mounted) return;
      final data = doc.data();
      if (data == null) return;

      final lat = data['lat'];
      final lng = data['lng'];

      final latValue = lat is num ? lat.toDouble() : double.tryParse(lat?.toString() ?? '');
      final lngValue = lng is num ? lng.toDouble() : double.tryParse(lng?.toString() ?? '');

      if (latValue != null && lngValue != null) {
        final workerLatLng = LatLng(
          latValue,
          lngValue,
        );

        setState(() {
          _workerPosition = workerLatLng;
        });

        _updateMarkers(workerLatLng);
        _updatePolyline(workerLatLng);

        _mapController?.animateCamera(
          CameraUpdate.newLatLng(workerLatLng),
        );
      }
    });
  }

  void _updateMarkers(LatLng workerLatLng) {
    final customerLatLng = _customerLatLng;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('worker'),
          position: workerLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'You'),
        ),
        Marker(
          markerId: const MarkerId('customer'),
          position: customerLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: widget.job.customerName.isNotEmpty
                ? widget.job.customerName
                : 'Customer Location',
          ),
        ),
      };
    });
  }

  Future<void> _updatePolyline(LatLng workerLatLng) async {
    final String apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('[NAVIGATION] GOOGLE_API_KEY not set in .env file');
      if (mounted) {
        setState(() {
          _etaText = 'No API key';
          _distanceText = '';
        });
      }
      return;
    }

    final customerLatLng = _customerLatLng;

    // Skip if coordinates are invalid (0,0 = unset)
    if ((customerLatLng.latitude == 0.0 && customerLatLng.longitude == 0.0) ||
        (workerLatLng.latitude == 0.0 && workerLatLng.longitude == 0.0)) {
      debugPrint('[NAVIGATION] Skipping route — invalid coordinates');
      return;
    }

    final polylinePoints = PolylinePoints(apiKey: apiKey);

    try {
      debugPrint('[NAVIGATION] Route: (${workerLatLng.latitude},${workerLatLng.longitude}) → (${customerLatLng.latitude},${customerLatLng.longitude})');
      
      final response = await polylinePoints.getRouteBetweenCoordinatesV2(
        request: RoutesApiRequest(
          origin:
              PointLatLng(workerLatLng.latitude, workerLatLng.longitude),
          destination: PointLatLng(
              customerLatLng.latitude, customerLatLng.longitude),
          travelMode: TravelMode.driving,
        ),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.routes.isEmpty) {
        debugPrint('[NAVIGATION] No routes in response');
        return;
      }

      final result = polylinePoints.convertToLegacyResult(response);
      if (result.points.isEmpty) {
        debugPrint('[NAVIGATION] Empty polyline points');
        return;
      }
      
      final coordinates = result.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      final route = response.routes.first;
      final distanceMeters = route.distanceMeters ?? 0;
      final durationSeconds = route.duration ?? 0;

      if (mounted) {
        setState(() {
          _distanceText = distanceMeters > 1000
              ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
              : '$distanceMeters m';
          _etaText = _formatDuration(durationSeconds);
          _polylines = {
            Polyline(
              polylineId: const PolylineId('nav_route'),
              color: const Color(0xFF2563EB),
              points: coordinates,
              width: 5,
              geodesic: true,
            ),
          };
        });
        debugPrint('[NAVIGATION] Route OK: $_etaText, $_distanceText');
      }
    } on TimeoutException {
      debugPrint('[NAVIGATION] Route timeout — will retry on next location update');
    } catch (e) {
      debugPrint('[NAVIGATION] Route error: $e');
    }
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return 'Calculating...';
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMin = minutes % 60;
    return '${hours}h ${remainingMin}m';
  }

  Future<void> _openGoogleMapsNavigation() async {
    final lat = _customerLatLng.latitude;
    final lng = _customerLatLng.longitude;
    final url = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final fallbackUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalNonBrowserApplication);
    } else if (await canLaunchUrl(fallbackUrl)) {
      await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Google Maps')),
        );
      }
    }
  }

  Future<void> _markArrived() async {
    setState(() => _isArriving = true);

    try {
      await FirebaseFirestore.instance
          .collection('jobRequests')
          .doc(widget.job.id)
          .update({'status': 'arrived'});

      LocationService.instance.stopNavigationTracking();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have arrived! The customer has been notified.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking arrived: $e');
      setState(() => _isArriving = false);
    }
  }

  /// Worker taps "Start Job" → sets status='workerStartedWork'
  /// Customer must then accept before timer starts (status='workStarted')
  Future<void> _startJob() async {
    if (_isStartingJob) return;
    setState(() => _isStartingJob = true);
    try {
      await FirebaseFirestore.instance
          .collection('jobRequests')
          .doc(widget.job.id)
          .update({
        'status': 'workerStartedWork',
        'workerStartedWorkAt': FieldValue.serverTimestamp(),
      });
      // _listenToJobStatus() will pick up 'workerStartedWork' and update UI
      // When customer accepts → status='workStarted' → navigate to timer screen
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingJob = false);
    }
  }

  Future<void> _callCustomer() async {
    var phone = _resolvedCustomerPhone?.trim();
    if (phone == null || phone.isEmpty) {
      await _resolveCustomerPhone();
      phone = _resolvedCustomerPhone?.trim();
    }

    if (phone == null || phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer phone not available')),
        );
      }
      return;
    }

    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open dialer')),
        );
      }
    }
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2563EB)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _jobStatusSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerLatLng = _customerLatLng;

    return Scaffold(
      body: Stack(
        children: [
          // ─── Full-screen Google Map ─────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _workerPosition ?? customerLatLng,
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // ─── Top Info Card ─────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 20,
                    color: Color(0x30000000),
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Navigating to ${widget.job.customerName.isNotEmpty ? widget.job.customerName : "Customer"}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${widget.job.jobType} • Normal',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.job.jobType} Request',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Customer Location Map Pin',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _infoChip(Icons.access_time, _etaText),
                      const SizedBox(width: 10),
                      if (_distanceText.isNotEmpty)
                        _infoChip(Icons.directions_car, _distanceText),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── Left-Middle Call Button ───────────────────────────
          if (_jobStatus == 'inProgress' ||
              _jobStatus == 'arrived' ||
              _jobStatus == 'workerStartedWork')
            Positioned(
              left: 16,
              top: MediaQuery.of(context).size.height * 0.45,
              child: GestureDetector(
                onTap: _callCustomer,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.phone,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),

          // ─── Bottom Action Buttons / Status ───────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 16,
            right: 16,
            child: Column(
              children: [
                if (_jobStatus == 'inProgress') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _openGoogleMapsNavigation,
                      icon: const Icon(Icons.navigation),
                      label: const Text(
                        'Open Google Maps Navigation',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _isArriving ? null : _markArrived,
                      icon: _isArriving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(
                        _isArriving ? 'Updating...' : "I've Arrived",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  // ─── Arrived: Show "Start Job" button ─────────────
                ] else if (_jobStatus == 'arrived' || _jobStatus == 'workerStartedWork') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      onPressed: (_isStartingJob || _jobStatus == 'workerStartedWork') ? null : _startJob,
                      icon: (_isStartingJob || _jobStatus == 'workerStartedWork')
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(
                        _jobStatus == 'workerStartedWork'
                            ? 'Waiting for customer...'
                            : (_isStartingJob ? 'Starting...' : 'Start Job'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  // ─── Completed ────────────────────────────────────
                ] else if (_jobStatus == 'completed') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.1),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'Job Completed!',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Return Home'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
