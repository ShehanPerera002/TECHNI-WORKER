import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/job_request.dart';

void main() {
  group('JobRequest model', () {
    test('toMap should include correct keys and values', () {
      final now = DateTime.now();
      final request = JobRequest(
        id: 'req1',
        customerId: 'cust1',
        customerName: 'Alice',
        status: 'searching',
        jobType: 'plumbing',
        customerLat: 6.0,
        customerLng: 7.0,
        createdAt: now,
      );

      final map = request.toMap();

      expect(map['customerId'], 'cust1');
      expect(map['customerName'], 'Alice');
      expect(map['status'], 'searching');
      expect(map['jobType'], 'plumbing');
      expect(map['customerLocation'], isNotNull);
    });

    test('constructor defaults for optional fields', () {
      final request = JobRequest(
        id: 'req2',
        customerId: 'cust2',
        customerName: 'Bob',
        status: 'searching',
        jobType: 'electrical',
        customerLat: 8.0,
        customerLng: 9.0,
        createdAt: DateTime.parse('2026-03-28T10:00:00Z'),
      );

      expect(request.rejectedWorkerIds, isEmpty);
      expect(request.notifiedWorkerIds, isEmpty);
      expect(request.workerId, isNull);
    });
  });
}
