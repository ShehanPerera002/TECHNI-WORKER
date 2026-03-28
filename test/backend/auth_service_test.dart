import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/auth_service.dart';
import 'backend_test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeBackendFirebase();
  });

  group('AuthService', () {
    final authService = AuthService();

    test('Initial verificationId is null', () {
      expect(authService.getVerificationId(), isNull);
    });

    test('setVerificationId sets internal value', () {
      authService.setVerificationId('test-id');
      expect(authService.getVerificationId(), 'test-id');
    });

    test('getCurrentUser is null without Firebase init', () {
      expect(authService.getCurrentUser(), isNull);
    });
  });
}
