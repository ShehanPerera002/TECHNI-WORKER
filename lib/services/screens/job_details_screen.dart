import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job_request.dart';

class JobDetailsScreen extends StatelessWidget {
  const JobDetailsScreen({super.key, required this.job});

  final JobRequest job;

  double _haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = (lat2 - lat1) * (3.141592653589793 / 180.0);
    final dLng = (lng2 - lng1) * (3.141592653589793 / 180.0);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(lat1 * (3.141592653589793 / 180.0)) *
            cos(lat2 * (3.141592653589793 / 180.0)) *
            (sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  String _distanceLabel() {
    if (job.distanceKm != null && job.distanceKm! > 0) {
      return '${job.distanceKm!.toStringAsFixed(1)} km away';
    }
    if (job.distanceKmEstimate != null && job.distanceKmEstimate! > 0) {
      return '${job.distanceKmEstimate!.toStringAsFixed(1)} km away';
    }
    if (job.distanceTextEstimate != null && job.distanceTextEstimate!.trim().isNotEmpty) {
      return '${job.distanceTextEstimate} away';
    }
    if (job.workerLat != null && job.workerLng != null) {
      final km = _haversineKm(
        job.workerLat!,
        job.workerLng!,
        job.customerLat,
        job.customerLng,
      );
      return '${km.toStringAsFixed(1)} km away';
    }
    return 'Distance unavailable';
  }

  void _openImageFullscreen(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Issue Photo', style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 56,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _callCustomer(BuildContext context) async {
    final phone = (job.customerPhone ?? '').trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer phone number is not available.')),
      );
      return;
    }

    final uri = Uri.parse('tel:$phone');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Job Details'),
        actions: [
          if ((job.customerPhone ?? '').trim().isNotEmpty)
            IconButton(
              onPressed: () => _callCustomer(context),
              icon: const Icon(Icons.call),
              tooltip: 'Call Customer',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${job.jobType} • Normal',
                  style: TextStyle(
                    color: const Color(0xFF2563EB),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${job.jobType} Request',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_distanceLabel()} • Est. Rs. ${job.fare?.toStringAsFixed(0) ?? '0'}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '4.5 Customer Rating',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if ((job.customerPhone ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: () => _callCustomer(context),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Call Customer'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  job.description ?? 'No description provided',
                  style: const TextStyle(color: Colors.black54),
                ),
                if ((job.issueImageUrl ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Attached Photo',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _openImageFullscreen(context, job.issueImageUrl!.trim()),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Image.network(
                          job.issueImageUrl!.trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFF2F2F2),
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image, color: Colors.black45),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap image to view full screen',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Address',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Customer Location Map Pin',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(job.customerLat, job.customerLng),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('customer'),
                          position: LatLng(job.customerLat, job.customerLng),
                          infoWindow: const InfoWindow(
                            title: 'Customer Location',
                          ),
                        ),
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
