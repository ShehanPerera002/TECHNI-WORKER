import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A reference model for the Customer app, representing a Trade Professional/Worker.
class Professional {
  final String id;
  final String name;
  final String specialization;
  final double rating;
  final LatLng? currentLocation;
  final bool isOnline;
  final bool doNotDisturb;

  Professional({
    required this.id,
    required this.name,
    required this.specialization,
    required this.rating,
    this.currentLocation,
    this.isOnline = false,
    this.doNotDisturb = false,
  });

  /// Factory constructor to create a Professional from a Firestore document.
  factory Professional.fromFirestore(String id, Map<String, dynamic> data) {
    LatLng? loc;
    if (data['lat'] != null && data['lng'] != null) {
      loc = LatLng(
        (data['lat'] as num).toDouble(),
        (data['lng'] as num).toDouble(),
      );
    }
    
    return Professional(
      id: id,
      name: data['name'] ?? 'Unknown Worker',
      specialization: data['specialization'] ?? 'General',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      currentLocation: loc,
      isOnline: data['isOnline'] ?? false,
      doNotDisturb: data['doNotDisturb'] ?? false,
    );
  }
}
