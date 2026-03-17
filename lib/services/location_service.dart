import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  StreamSubscription<Position>? _positionSub;

  Future<void> startSharing() async {
    // Request permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final workerId = FirebaseAuth.instance.currentUser?.uid;
    if (workerId == null) return;

    // Set online status
    await FirebaseFirestore.instance.collection('workers').doc(workerId).set({
      'isOnline': true,
    }, SetOptions(merge: true));

    // Start streaming location
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // update every 10 metres
          ),
        ).listen((Position pos) {
          FirebaseFirestore.instance.collection('workers').doc(workerId).set({
            'lat': pos.latitude,
            'lng': pos.longitude,
            'isOnline': true,
          }, SetOptions(merge: true));
        });
  }

  Future<void> stopSharing() async {
    await _positionSub?.cancel();
    _positionSub = null;

    final workerId = FirebaseAuth.instance.currentUser?.uid;
    if (workerId == null) return;

    await FirebaseFirestore.instance.collection('workers').doc(workerId).set({
      'isOnline': false,
    }, SetOptions(merge: true));
  }
}
