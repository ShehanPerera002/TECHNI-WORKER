import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<Position>? _navigationSub;

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

    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3000, // update every 3 kilometers
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Location is streaming in the background",
          notificationTitle: "TECHNI Background Service",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 3000,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3000,
      );
    }

    // Start streaming location
    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position pos) {
      // Build a GeoFirePoint — this generates the GeoHash + GeoPoint in one call
      final geoPoint = GeoFirePoint(GeoPoint(pos.latitude, pos.longitude));

      FirebaseFirestore.instance.collection('workers').doc(workerId).set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'isOnline': true,
        // 'position' stores {geopoint: GeoPoint, geohash: String}
        // This is the field GeoCollectionReference.subscribeWithin() queries on
        'position': geoPoint.data,
      }, SetOptions(merge: true));
    });
  }

  /// High-frequency tracking for active navigation (10m filter, 5s interval)
  Future<void> startNavigationTracking({String? jobId}) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final workerId = FirebaseAuth.instance.currentUser?.uid;
    if (workerId == null) return;

    // Cancel passive sharing if active
    await _positionSub?.cancel();
    _positionSub = null;

    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // update every 10 meters
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Navigating to customer...",
          notificationTitle: "TECHNI Navigation Active",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }

    _navigationSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position pos) {
      final geoPoint = GeoFirePoint(GeoPoint(pos.latitude, pos.longitude));

      FirebaseFirestore.instance.collection('workers').doc(workerId).set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'isOnline': true,
        'position': geoPoint.data,
      }, SetOptions(merge: true));

      if (jobId != null) {
        FirebaseFirestore.instance.collection('liveLocations').doc(jobId).set({
          'jobRequestId': jobId,
          'workerId': workerId,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'heading': pos.heading,
          'speed': pos.speed,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Stop navigation tracking and switch back to passive sharing
  Future<void> stopNavigationTracking() async {
    await _navigationSub?.cancel();
    _navigationSub = null;
    // Resume passive sharing
    await startSharing();
  }

  Future<void> stopSharing() async {
    await _positionSub?.cancel();
    _positionSub = null;
    await _navigationSub?.cancel();
    _navigationSub = null;

    final workerId = FirebaseAuth.instance.currentUser?.uid;
    if (workerId == null) return;

    await FirebaseFirestore.instance.collection('workers').doc(workerId).set({
      'isOnline': false,
    }, SetOptions(merge: true));
  }
}
