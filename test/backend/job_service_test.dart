import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/job_service.dart';
import 'backend_test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeBackendFirebase();
  });

  group('JobService utility functions', () {
    final service = JobService();

    test('normalizeCategory removes special chars and lowercases', () {
      expect(service.normalizeCategory(' Plumbing & Services '), 'plumbing_and_services');
      expect(service.normalizeCategory('AC Technician!'), 'ac_technician');
      expect(service.normalizeCategory('  test   '), 'test');
    });

    test('resolveWorkerCategoryKey maps categories correctly', () {
      expect(service.resolveWorkerCategoryKey('Plumbing'), 'plumber');
      expect(service.resolveWorkerCategoryKey('ac_services'), 'ac_tech');
      expect(service.resolveWorkerCategoryKey('Gardening Services'), 'gardener');
    });
  });
}
