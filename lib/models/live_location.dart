import 'package:cloud_firestore/cloud_firestore.dart';

class LiveLocation {
  final String jobRequestId;
  final String workerId;
  final double latitude;
  final double longitude;
  final double heading;
  final double? speed;
  final DateTime updatedAt;

  LiveLocation({
    required this.jobRequestId,
    required this.workerId,
    required this.latitude,
    required this.longitude,
    required this.heading,
    this.speed,
    required this.updatedAt,
  });

  factory LiveLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    DateTime parseTimestamp(dynamic field) {
      if (field is Timestamp) return field.toDate();
      if (field is String) return DateTime.tryParse(field) ?? DateTime.now();
      return DateTime.now();
    }

    return LiveLocation(
      jobRequestId: doc.id,
      workerId: data['workerId'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      heading: (data['heading'] as num?)?.toDouble() ?? 0.0,
      speed: (data['speed'] as num?)?.toDouble(),
      updatedAt: parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workerId': workerId,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed': speed,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
