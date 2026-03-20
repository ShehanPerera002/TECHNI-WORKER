class Job {
  final String id;
  final String title;
  final String category;
  final String description;
  final String address;
  final double distance;
  final double estimatedPrice;
  final double rating;
  final String urgency;
  final double customerLat;
  final double customerLng;
  final String customerName;
  final String customerPhone;

  String status;
  DateTime? completedAt;

  Job({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.address,
    required this.distance,
    required this.estimatedPrice,
    required this.rating,
    required this.urgency,
    this.status = "pending",
    this.completedAt,
    this.customerLat = 6.9271,
    this.customerLng = 79.8612,
    this.customerName = '',
    this.customerPhone = '',
  });

  /// Create a Job from a Firestore document snapshot
  factory Job.fromFirestore(String id, Map<String, dynamic> data) {
    return Job(
      id: id,
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      distance: (data['distance'] as num?)?.toDouble() ?? 0.0,
      estimatedPrice: (data['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      urgency: data['urgency'] ?? 'Normal',
      status: data['status'] ?? 'pending',
      customerLat: (data['customerLat'] as num?)?.toDouble() ?? 6.9271,
      customerLng: (data['customerLng'] as num?)?.toDouble() ?? 79.8612,
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      completedAt: data['completedAt'] != null
          ? DateTime.tryParse(data['completedAt'].toString())
          : null,
    );
  }

  /// Convert job to a map for writing back to Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'address': address,
      'distance': distance,
      'estimatedPrice': estimatedPrice,
      'rating': rating,
      'urgency': urgency,
      'status': status,
      'customerLat': customerLat,
      'customerLng': customerLng,
      'customerName': customerName,
      'customerPhone': customerPhone,
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    };
  }
}
