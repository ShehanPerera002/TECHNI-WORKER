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
  final DateTime? completedAt;

  String status;

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
  });
}
