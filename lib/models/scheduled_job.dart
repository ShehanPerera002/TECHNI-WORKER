import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a calendar-scheduled job created by a customer.
/// Stored in the Firestore `scheduledJobs` collection.
class ScheduledJob {
  final String id;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final double customerLat;
  final double customerLng;
  final String serviceTitle;
  final String category;
  final String scheduledDateStr;
  final String scheduledTimeStr;
  final DateTime? scheduledAt;

  /// pending → accepted → completed / cancelled
  final String status;
  final String? workerId;
  final String? workerName;
  final DateTime createdAt;

  const ScheduledJob({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.customerLat,
    required this.customerLng,
    required this.serviceTitle,
    required this.category,
    required this.scheduledDateStr,
    required this.scheduledTimeStr,
    this.scheduledAt,
    required this.status,
    this.workerId,
    this.workerName,
    required this.createdAt,
  });

  factory ScheduledJob.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final locationGeo = data['customerLocation'] as GeoPoint?;
    final scheduledAtTs = data['scheduledAt'];
    final createdAtTs = data['createdAt'];

    return ScheduledJob(
      id: doc.id,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Customer',
      customerPhone: data['customerPhone'] as String?,
      customerLat: locationGeo?.latitude ?? 0.0,
      customerLng: locationGeo?.longitude ?? 0.0,
      serviceTitle: data['serviceTitle'] as String? ?? '',
      category: data['category'] as String? ?? '',
      scheduledDateStr: data['scheduledDateStr'] as String? ?? '',
      scheduledTimeStr: data['scheduledTimeStr'] as String? ?? '',
      scheduledAt:
          scheduledAtTs is Timestamp ? scheduledAtTs.toDate() : null,
      status: data['status'] as String? ?? 'pending',
      workerId: data['workerId'] as String?,
      workerName: data['workerName'] as String?,
      createdAt:
          createdAtTs is Timestamp ? createdAtTs.toDate() : DateTime.now(),
    );
  }
}
