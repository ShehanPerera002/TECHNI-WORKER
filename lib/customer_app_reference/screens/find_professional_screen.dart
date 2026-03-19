import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import '../models/professional.dart';

class FindProfessionalScreen extends StatefulWidget {
  final LatLng customerLocation;

  const FindProfessionalScreen({
    super.key,
    required this.customerLocation,
  });

  @override
  State<FindProfessionalScreen> createState() => _FindProfessionalScreenState();
}

class _FindProfessionalScreenState extends State<FindProfessionalScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<List<DocumentSnapshot>>? _workersSubscription;
  Set<Marker> _markers = {};

  // Maximum search radius in kilometers
  static const double _radiusKm = 10.0;

  @override
  void initState() {
    super.initState();
    _startLocatingNearbyWorkers();
  }

  void _startLocatingNearbyWorkers() {
    // Create a GeoFirePoint from the customer's location
    final center = GeoFirePoint(
      GeoPoint(widget.customerLocation.latitude, widget.customerLocation.longitude),
    );

    // GeoCollectionReference requires a plain CollectionReference (not a Query),
    // so we pass the base collection and filter isOnline/doNotDisturb client-side.
    final collectionRef = FirebaseFirestore.instance.collection('workers');

    // Use geoflutterfire_plus to stream only docs within the 10km bounding box.
    // This runs the geo-filter on Firestore's side — no client-side full-table scan!
    _workersSubscription = GeoCollectionReference(collectionRef)
        .subscribeWithin(
          center: center,
          radiusInKm: _radiusKm,
          field: 'position', // The GeoHash field we write in location_service.dart
          geopointFrom: (data) =>
              (data['position']['geopoint'] as GeoPoint),
        )
        .listen((List<DocumentSnapshot> docs) {
      // Client-side filter: only show online workers who haven't enabled DND
      final activeDocs = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return false;
        return data['isOnline'] == true && data['doNotDisturb'] != true;
      }).toList();
      final Set<Marker> newMarkers = {};

      // Customer marker
      newMarkers.add(
        Marker(
          markerId: const MarkerId('customer_loc'),
          position: widget.customerLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      );

      for (final doc in activeDocs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final professional = Professional.fromFirestore(doc.id, data);

          if (professional.currentLocation != null) {
            // Still do a precise distance check inside the bounding box
            final distanceInMeters = Geolocator.distanceBetween(
              widget.customerLocation.latitude,
              widget.customerLocation.longitude,
              professional.currentLocation!.latitude,
              professional.currentLocation!.longitude,
            );

            newMarkers.add(
              Marker(
                markerId: MarkerId(professional.id),
                position: professional.currentLocation!,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(
                  title: professional.name,
                  snippet:
                      '${professional.specialization} - ${(distanceInMeters / 1000).toStringAsFixed(1)} km away',
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint('Error parsing worker doc: $e');
        }
      }

      setState(() {
        _markers = newMarkers;
      });
    });
  }

  @override
  void dispose() {
    _workersSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Professionals'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.customerLocation,
          zoom: 13,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
