import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job_model.dart';
import '../location_service.dart';

class WorkerNavigationScreen extends StatefulWidget {
  final Job job;

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

  @override
  void initState() {
    super.initState();
    // Start high-frequency navigation tracking
    LocationService.instance.startNavigationTracking();
    _listenToWorkerLocation();
  }

  /// Listen to this worker's own location updates from Firestore
  void _listenToWorkerLocation() {
    final workerId = FirebaseAuth.instance.currentUser?.uid;
    if (workerId == null) return;

    _locationSub = FirebaseFirestore.instance
        .collection('workers')
        .doc(workerId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;

      final lat = data['lat'];
      final lng = data['lng'];

      if (lat != null && lng != null) {
        final workerLatLng = LatLng(
          (lat as num).toDouble(),
          (lng as num).toDouble(),
        );

        setState(() {
          _workerPosition = workerLatLng;
        });

        _updateMarkers(workerLatLng);
        _updatePolyline(workerLatLng);

        // Auto-center the camera on the worker
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(workerLatLng),
        );
      }
    });
  }

  void _updateMarkers(LatLng workerLatLng) {
    final customerLatLng = LatLng(widget.job.customerLat, widget.job.customerLng);

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('worker'),
          position: workerLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
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
    if (apiKey.isEmpty) return;

    final customerLatLng = LatLng(widget.job.customerLat, widget.job.customerLng);
    final polylinePoints = PolylinePoints(apiKey: apiKey);

    try {
      final response = await polylinePoints.getRouteBetweenCoordinatesV2(
        request: RoutesApiRequest(
          origin: PointLatLng(workerLatLng.latitude, workerLatLng.longitude),
          destination: PointLatLng(customerLatLng.latitude, customerLatLng.longitude),
          travelMode: TravelMode.driving,
        ),
      );

      final result = polylinePoints.convertToLegacyResult(response);

      if (result.points.isNotEmpty) {
        final coordinates = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();

        // Extract distance and duration from the response
        if (response.routes.isNotEmpty) {
          final route = response.routes.first;
          final distanceMeters = route.distanceMeters ?? 0;
          final durationSeconds = route.duration ?? 0;

          setState(() {
            _distanceText = distanceMeters > 1000
                ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
                : '$distanceMeters m';
            _etaText = _formatDuration(durationSeconds);
          });
        }

        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('nav_route'),
              color: const Color(0xFF2563EB),
              points: coordinates,
              width: 5,
            ),
          };
        });
      }
    } catch (e) {
      debugPrint('Navigation polyline error: $e');
    }
  }

  /// Format duration in seconds to human-readable
  String _formatDuration(int seconds) {
    if (seconds <= 0) return 'Calculating...';
    if (seconds < 60) return '$seconds sec';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMin = minutes % 60;
    return '${hours}h ${remainingMin}m';
  }

  /// Launch Google Maps with turn-by-turn navigation
  Future<void> _openGoogleMapsNavigation() async {
    final lat = widget.job.customerLat;
    final lng = widget.job.customerLng;
    final url = Uri.parse(
      'google.navigation:q=$lat,$lng&mode=d',
    );
    final fallbackUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    }
  }

  /// Called when worker taps "Arrived"
  Future<void> _markArrived() async {
    setState(() => _isArriving = true);

    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.job.id)
          .update({'status': 'arrived'});

      // Switch back to passive location tracking
      LocationService.instance.stopNavigationTracking();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have arrived! The customer has been notified.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error marking arrived: $e');
      setState(() => _isArriving = false);
    }
  }

  /// Call the customer
  Future<void> _callCustomer() async {
    if (widget.job.customerPhone.isEmpty) return;
    final url = Uri.parse('tel:${widget.job.customerPhone}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerLatLng = LatLng(widget.job.customerLat, widget.job.customerLng);

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
                  // Back button + title row
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
                      // Call button
                      if (widget.job.customerPhone.isNotEmpty)
                        GestureDetector(
                          onTap: _callCustomer,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.phone,
                              color: Colors.green.shade700,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Category + job title
                  Text(
                    '${widget.job.category} • ${widget.job.urgency}',
                    style: TextStyle(
                      color: widget.job.urgency == 'Emergency'
                          ? Colors.red
                          : const Color(0xFF2563EB),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.job.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.job.address,
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  // ETA + Distance
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

          // ─── Bottom Action Buttons ─────────────────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Open Google Maps button
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
                // Arrived button
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
              ],
            ),
          ),
        ],
      ),
    );
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
}
