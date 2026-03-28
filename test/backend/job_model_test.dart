import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/job_model.dart';

void main() {
  group('Job model', () {
    test('toMap should include all provided fields and optional completedAt', () {
      final job = Job(
        id: 'jobId',
        title: 'Fix Sink',
        category: 'plumbing',
        description: 'Pipe blocked',
        address: '123 Main St',
        distance: 5.2,
        estimatedPrice: 50.0,
        rating: 4.5,
        urgency: 'High',
        customerLat: 10.0,
        customerLng: 20.0,
        customerName: 'John',
        customerPhone: '1234567890',
        status: 'inProgress',
        completedAt: DateTime.parse('2026-03-28T12:00:00Z'),
      );

      final map = job.toMap();
      expect(map['title'], 'Fix Sink');
      expect(map['category'], 'plumbing');
      expect(map['status'], 'inProgress');
      expect(map['completedAt'], '2026-03-28T12:00:00.000Z');
    });

    test('fromFirestore should parse numbers and dates correctly', () {
      final data = {
        'title': 'Fix Sink',
        'category': 'plumbing',
        'description': 'Pipe blocked',
        'address': '123 Main St',
        'distance': 5.2,
        'estimatedPrice': 50,
        'rating': 4,
        'urgency': 'High',
        'status': 'completed',
        'customerLat': 10,
        'customerLng': 20,
        'customerName': 'John',
        'customerPhone': '1234567890',
        'completedAt': '2026-03-28T12:00:00Z',
      };

      final job = Job.fromFirestore('jobId', data);

      expect(job.id, 'jobId');
      expect(job.status, 'completed');
      expect(job.completedAt, DateTime.parse('2026-03-28T12:00:00Z'));
    });
  });
}
