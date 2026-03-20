import 'package:cloud_firestore/cloud_firestore.dart';

class JobSummary {
  final String jobRequestId;
  final String workerId;
  final String customerId;
  final String customerName;
  final String jobType;
  final double fare;
  final double platformFee;
  final double workerEarnings;
  final int duration;
  final DateTime completedAt;
  final String? reviewId;
  final double? rating;

  JobSummary({
    required this.jobRequestId,
    required this.workerId,
    required this.customerId,
    required this.customerName,
    required this.jobType,
    required this.fare,
    required this.platformFee,
    required this.workerEarnings,
    required this.duration,
    required this.completedAt,
    this.reviewId,
    this.rating,
  });

  factory JobSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    DateTime parseTimestamp(dynamic field) {
      if (field is Timestamp) return field.toDate();
      if (field is String) return DateTime.tryParse(field) ?? DateTime.now();
      return DateTime.now();
    }

    return JobSummary(
      jobRequestId: doc.id,
      workerId: data['workerId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      jobType: data['jobType'] ?? '',
      fare: (data['fare'] as num?)?.toDouble() ?? 0.0,
      platformFee: (data['platformFee'] as num?)?.toDouble() ?? 0.0,
      workerEarnings: (data['workerEarnings'] as num?)?.toDouble() ?? 0.0,
      duration: data['duration'] as int? ?? 0,
      completedAt: parseTimestamp(data['completedAt']),
      reviewId: data['reviewId'],
      rating: (data['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workerId': workerId,
      'customerId': customerId,
      'customerName': customerName,
      'jobType': jobType,
      'fare': fare,
      'platformFee': platformFee,
      'workerEarnings': workerEarnings,
      'duration': duration,
      'completedAt': Timestamp.fromDate(completedAt),
      'reviewId': reviewId,
      'rating': rating,
    };
  }
}
