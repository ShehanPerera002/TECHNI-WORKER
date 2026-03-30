import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/location_service.dart';
import 'backend_test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeBackendFirebase();
  });

  group('LocationService core', () {
    test('LocationService singleton instance exists', () {
      final service = LocationService.instance;
      expect(service, isNotNull);
    });

    test('Calling stopSharing does not throw (no location permission mock)', () async {
      final service = LocationService.instance;
      // Should not crash even without active location stream
      await service.stopSharing();
      expect(true, isTrue);
    });
  });
}
