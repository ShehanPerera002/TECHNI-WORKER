import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WorkerOnTheWayScreen extends StatefulWidget {
  final String workerId;
  final LatLng customerLocation; // Where the customer is waiting

  const WorkerOnTheWayScreen({
    super.key,
    required this.workerId,
    required this.customerLocation,
  });

  @override
  State<WorkerOnTheWayScreen> createState() => _WorkerOnTheWayScreenState();
}

class _WorkerOnTheWayScreenState extends State<WorkerOnTheWayScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<DocumentSnapshot>? _workerLocationSub;
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _lastWorkerLocation;

  @override
  void initState() {
    super.initState();
    _trackWorkerLocation();
  }

  /// Sets up a real-time stream for a specific worker's document
  void _trackWorkerLocation() {
    _workerLocationSub = FirebaseFirestore.instance
        .collection('workers')
        .doc(widget.workerId)
        .snapshots()
        .listen((doc) {
      
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;

      final lat = data['lat'];
      final lng = data['lng'];

      if (lat != null && lng != null) {
        final workerLocation = LatLng((lat as num).toDouble(), (lng as num).toDouble());

        final Set<Marker> newMarkers = {};
        
        // Customer marker
        newMarkers.add(
          Marker(
            markerId: const MarkerId('customer_loc'),
            position: widget.customerLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: 'You'),
          ),
        );

        // Worker marker
        newMarkers.add(
          Marker(
            markerId: const MarkerId('worker_loc'),
            position: workerLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'Worker on the way'),
          ),
        );

        setState(() {
          _markers = newMarkers;
        });

        // Only fetch a new route if the worker has significantly moved from the last known location, or if we don't have one yet.
        if (_lastWorkerLocation == null ||
            _lastWorkerLocation!.latitude != workerLocation.latitude ||
            _lastWorkerLocation!.longitude != workerLocation.longitude) {
          _lastWorkerLocation = workerLocation;
          _getPolyline(workerLocation);
        }
      }
    });
  }

  /// Queries Google Directions API to draw the physical route between worker and customer
  Future<void> _getPolyline(LatLng workerLocation) async {
    String apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      debugPrint('Warning: GOOGLE_API_KEY is not set in .env');
      return;
    }

    // flutter_polyline_points v3+: apiKey is passed to the constructor as a named argument
    PolylinePoints polylinePoints = PolylinePoints(apiKey: apiKey);

    try {
      final response = await polylinePoints.getRouteBetweenCoordinatesV2(
        request: RoutesApiRequest(
          origin: PointLatLng(workerLocation.latitude, workerLocation.longitude),
          destination: PointLatLng(widget.customerLocation.latitude, widget.customerLocation.longitude),
          travelMode: TravelMode.driving,
        ),
      );
      PolylineResult result = polylinePoints.convertToLegacyResult(response);

      if (result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates = [];
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              color: Colors.blueAccent,
              points: polylineCoordinates,
              width: 5,
            )
          };
        });
      }
    } catch (e) {
      debugPrint('Polyline Error: $e');
    }
  }

  @override
  void dispose() {
    // Cancel all streams when screen is disposed
    _workerLocationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker is on the way'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.customerLocation,
          zoom: 14,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        markers: _markers,
        polylines: _polylines,
      ),
    );
  }
}
