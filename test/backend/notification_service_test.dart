import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/notification_service.dart';
import 'backend_test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeBackendFirebase();
  });

  group('NotificationService core', () {
    test('singleton instance exists', () {
      final service = NotificationService.instance;
      expect(service, isNotNull);
    });

    test('initialize is available as an async function', () {
      final service = NotificationService.instance;
      expect(service.initialize, isA<Function>());
    });
  });
}
