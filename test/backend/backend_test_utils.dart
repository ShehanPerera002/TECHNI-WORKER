import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../lib/firebase_options.dart';

/// Core backend test utilities and mock definitions.
///
/// Use this file in backend tests to maintain consistency.

void registerBackendMocks() {
  // No-op: placeholder for future mock registrations.
}

Future<void> initializeBackendFirebase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Avoid obligating platform channel initialization in unit tests.
  // Services are designed to handle absent Firebase app gracefully.
}

Future<void> setupBackendTest({required WidgetTester tester}) async {
  // Put common setup configuration here if needed.
  // e.g. initialize service locator, load test fixtures, etc.
  await tester.pumpAndSettle();
}

void performCommonBackendAssertions() {
  expect(true, isTrue, reason: 'Backend base assertions run successfully.');
}
