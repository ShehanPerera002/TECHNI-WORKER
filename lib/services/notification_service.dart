import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/job_request.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  GlobalKey<NavigatorState>? _navigatorKey;

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    // 1. Request Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else {
      debugPrint('User declined or has not accepted notification permission');
      return;
    }

    // 2. Get FCM Token
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }
    });

    // 4. Handle notification taps when app is in background (but not killed)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped (background): ${message.data}');
      _handleNotificationTap(message.data);
    });

    // 5. Handle notification taps when app was killed (cold start)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from killed state via notification: ${initialMessage.data}');
      // Delay slightly to ensure navigator is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage.data);
      });
    }
  }

  /// Navigate the worker to the dashboard (home screen) when they tap a job notification
  void _handleNotificationTap(Map<String, dynamic> data) {
    if (_navigatorKey?.currentState == null) return;
    _navigatorKey!.currentState!.pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _saveTokenToFirestore(String token) async {
    String? workerId = FirebaseAuth.instance.currentUser?.uid;
    if (workerId == null) return;

    await FirebaseFirestore.instance.collection('workers').doc(workerId).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }
}
