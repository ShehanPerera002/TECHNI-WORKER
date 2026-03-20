import 'package:cloud_firestore/cloud_firestore.dart';

class JobRequest {
  final String id;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String? workerId;
  final String status;
  final String jobType;
  final String? description;
  final double customerLat;
  final double customerLng;
  final double? workerLat;
  final double? workerLng;
  final List<String> notifiedWorkerIds;
  final List<String> rejectedWorkerIds;
  final double? fare;
  final int? duration;
  final DateTime createdAt;
  final DateTime? workerAcceptedAt;
  final DateTime? customerConfirmedAt;
  final DateTime? jobStartedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancelReason;

  JobRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.workerId,
    required this.status,
    required this.jobType,
    this.description,
    required this.customerLat,
    required this.customerLng,
    this.workerLat,
    this.workerLng,
    this.notifiedWorkerIds = const [],
    this.rejectedWorkerIds = const [],
    this.fare,
    this.duration,
    required this.createdAt,
    this.workerAcceptedAt,
    this.customerConfirmedAt,
    this.jobStartedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelReason,
  });

  factory JobRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    DateTime parseTimestamp(dynamic field) {
      if (field is Timestamp) return field.toDate();
      if (field is String) return DateTime.tryParse(field) ?? DateTime.now();
      return DateTime.now();
    }
    
    DateTime? parseNullableTimestamp(dynamic field) {
      if (field == null) return null;
      if (field is Timestamp) return field.toDate();
      if (field is String) return DateTime.tryParse(field);
      return null;
    }

    // Handle GeoPoints for location
    double cLat = 0.0;
    double cLng = 0.0;
    double? wLat;
    double? wLng;

    if (data['customerLocation'] is GeoPoint) {
      final geo = data['customerLocation'] as GeoPoint;
      cLat = geo.latitude;
      cLng = geo.longitude;
    }

    if (data['workerLocation'] is GeoPoint) {
      final geo = data['workerLocation'] as GeoPoint;
      wLat = geo.latitude;
      wLng = geo.longitude;
    }

    return JobRequest(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'],
      workerId: data['workerId'],
      status: data['status'] ?? 'searching',
      jobType: data['jobType'] ?? '',
      description: data['description'],
      customerLat: cLat,
      customerLng: cLng,
      workerLat: wLat,
      workerLng: wLng,
      notifiedWorkerIds: List<String>.from(data['notifiedWorkerIds'] ?? []),
      rejectedWorkerIds: List<String>.from(data['rejectedWorkerIds'] ?? []),
      fare: (data['fare'] as num?)?.toDouble(),
      duration: data['duration'] as int?,
      createdAt: parseTimestamp(data['createdAt']),
      workerAcceptedAt: parseNullableTimestamp(data['workerAcceptedAt']),
      customerConfirmedAt: parseNullableTimestamp(data['customerConfirmedAt']),
      jobStartedAt: parseNullableTimestamp(data['jobStartedAt']),
      completedAt: parseNullableTimestamp(data['completedAt']),
      cancelledAt: parseNullableTimestamp(data['cancelledAt']),
      cancelReason: data['cancelReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'workerId': workerId,
      'status': status,
      'jobType': jobType,
      'description': description,
      'customerLocation': GeoPoint(customerLat, customerLng),
      if (workerLat != null && workerLng != null)
        'workerLocation': GeoPoint(workerLat!, workerLng!),
      'notifiedWorkerIds': notifiedWorkerIds,
      'rejectedWorkerIds': rejectedWorkerIds,
      'fare': fare,
      'duration': duration,
      'createdAt': Timestamp.fromDate(createdAt),
      'workerAcceptedAt': workerAcceptedAt != null ? Timestamp.fromDate(workerAcceptedAt!) : null,
      'customerConfirmedAt': customerConfirmedAt != null ? Timestamp.fromDate(customerConfirmedAt!) : null,
      'jobStartedAt': jobStartedAt != null ? Timestamp.fromDate(jobStartedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancelReason': cancelReason,
    };
  }
}
