/*
Build a fully functional Worker Home Screen for the TECHNI technician marketplace app.

UI layout requirements:

1. Weekly earnings card
   - Show text: "This Week's Earnings"
   - Show amount like Rs. 5000.00
   - Show growth indicator "+15% from last week"
   - Include "View Details" button

2. Tab switcher
   - Tab 1: New Job Requests
   - Tab 2: Scheduled Jobs
   - New Job Requests should show a badge with number of jobs

3. Job request card
   - Show category and urgency (example: Plumbing • Emergency)
   - Job title
   - Distance from worker
   - Estimated price
   - Customer rating with stars
   - Image placeholder on right

4. Job Information section
   - Description
   - Address
   - Map preview placeholder container

5. Accept and Decline buttons
   - Accept button should mark job as accepted
   - Decline button should remove job
   - Accepted jobs should move to Scheduled Jobs tab

6. Use a Job model and JobService class to manage jobs.

7. Load jobs from JobService.getNewJobs()

8. Use setState to update UI after accept/decline

9. Scheduled jobs tab should show accepted jobs

10. Keep UI modern and similar to technician marketplace apps like Uber or Urban Company.

Do not break existing navigation routes.
Keep the screen responsive.
*/

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'earnings_details_screen.dart';
import 'job_details_screen.dart';
import '../../models/job_model.dart';
import '../job_service.dart';
import '../location_service.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  int tabIndex = 0;
  final double weekEarnings = 5000.00;
  bool _isDndActive = false;

  final JobService jobService = JobService();
  
  List<Job> _newJobs = [];
  List<Job> _scheduledJobs = [];
  StreamSubscription<List<Job>>? _newJobsSub;
  StreamSubscription<List<Job>>? _scheduledJobsSub;

  @override
  void initState() {
    super.initState();
    _loadDndStatus();
    _subscribeToJobs();
  }

  void _subscribeToJobs() {
    _newJobsSub = jobService.streamNewJobs().listen((jobs) {
      if (mounted) setState(() => _newJobs = jobs);
    });
    _scheduledJobsSub = jobService.streamScheduledJobs().listen((jobs) {
      if (mounted) setState(() => _scheduledJobs = jobs);
    });
  }

  Future<void> _loadDndStatus() async {
    final workerId = FirebaseAuth.instance.currentUser?.uid;
    if (workerId == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance.collection('workers').doc(workerId).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _isDndActive = doc.data()!['doNotDisturb'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error loading DND status: $e');
    }
  }

  Future<void> _toggleDnd(bool value) async {
    setState(() {
      _isDndActive = value;
    });

    final workerId = FirebaseAuth.instance.currentUser?.uid;
    if (workerId == null) return;
    
    try {
      await FirebaseFirestore.instance.collection('workers').doc(workerId).set({
        'doNotDisturb': value,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error setting DND status: $e');
    }
  }

  @override
  void dispose() {
    _newJobsSub?.cancel();
    _scheduledJobsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/category',
                (route) => false,
              );
            }
          },
        ),
        title: const Text('Worker home screen'),
        centerTitle: false,
        actions: [
          Row(
            children: [
              Text(
                'DND',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isDndActive ? Colors.red : Colors.black45,
                ),
              ),
              Switch(
                value: _isDndActive,
                onChanged: _toggleDnd,
                activeThumbColor: Colors.red,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _newJobs.isEmpty
                              ? 'No new notifications'
                              : '${_newJobs.length} new job request notifications',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_none),
                ),
                if (_newJobs.isNotEmpty)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshJobs,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _earningsCard(context),
              const SizedBox(height: 14),
              _tabs(_newJobs.length),
              const SizedBox(height: 14),
              if (tabIndex == 0)
                _jobsSection(jobs: _newJobs, isNewJobs: true)
              else
                _jobsSection(jobs: _scheduledJobs, isNewJobs: false),
            ],
          ),
        ),
      ),
    );
  }

  // Pull-to-refresh just forces the stream to re-evaluate (streams auto-update, nothing needed)
  Future<void> _refreshJobs() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  /*
    Add functionality to the "View Details" button in the weekly earnings card.

    When the button is pressed:
    - Navigate to a new screen called EarningsDetailsScreen.

    Create a clean earnings dashboard screen that shows:

    1. Header: "Earnings Details"

    2. Summary cards:
      - Today's earnings
      - This week's earnings
      - This month's earnings

    3. Earnings breakdown list showing example jobs:
      - Job title
      - Location
      - Price earned
      - Date

    4. Total earnings section at bottom.

    Use Flutter Material UI.
    Keep the design consistent with the TECHNI worker app theme.

    Add navigation using:
    Navigator.push()

    Create the new screen inside:
    screens/earnings_details_screen.dart
    */
  Widget _earningsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            color: Color(0x12000000),
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "This Week's Earnings",
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rs. ${weekEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.green, size: 18),
                    SizedBox(width: 6),
                    Text(
                      '+15% from last week',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EarningsDetailsScreen(),
                  ),
                );
              },
              child: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs(int newJobCount) {
    return Row(
      children: [
        Expanded(
          child: _tabButton(
            'New Job Requests',
            tabIndex == 0,
            badge: newJobCount,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _tabButton('Scheduled Jobs', tabIndex == 1)),
      ],
    );
  }

  Widget _tabButton(String text, bool active, {int? badge}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () =>
          setState(() => tabIndex = (text == 'New Job Requests') ? 0 : 1),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? const Color(0xFF2563EB) : Colors.black12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: active ? const Color(0xFF2563EB) : Colors.black87,
                ),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _jobsSection({required List<Job> jobs, required bool isNewJobs}) {
    if (jobs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Icon(
              isNewJobs ? Icons.work_outline : Icons.calendar_month_outlined,
              color: Colors.black38,
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              isNewJobs
                  ? 'No job requests available right now'
                  : 'No scheduled jobs yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
          ],
        ),
      );
    }

    return Column(
      children: jobs.map((job) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            children: [
              _jobRequestCard(job),
              const SizedBox(height: 12),
              _jobInformation(job),
              const SizedBox(height: 12),
              _actionButtons(job, isNewJobs),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _jobRequestCard(Job job) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => JobDetailsScreen(job: job)),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
            color: Colors.white,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${job.category} • ${job.urgency}',
                      style: TextStyle(
                        color: job.urgency == 'Emergency'
                            ? Colors.red
                            : const Color(0xFF2563EB),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${job.distance.toStringAsFixed(1)} km away  •  Est. Rs. ${job.estimatedPrice.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Customer Rating: ',
                          style: TextStyle(color: Colors.black54),
                        ),
                        ..._buildStars(job.rating),
                        const SizedBox(width: 4),
                        Text(
                          job.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: const Icon(Icons.image, color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStars(double rating) {
    final stars = <Widget>[];
    for (var i = 1; i <= 5; i++) {
      if (rating >= i) {
        stars.add(const Icon(Icons.star, color: Colors.orange, size: 16));
      } else if (rating >= i - 0.5) {
        stars.add(const Icon(Icons.star_half, color: Colors.orange, size: 16));
      } else {
        stars.add(
          const Icon(Icons.star_border, color: Colors.orange, size: 16),
        );
      }
    }
    return stars;
  }

  Widget _jobInformation(Job job) {
    return Container(
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
            'Job Information',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.description, color: Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.description,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Address',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.address,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFEF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: const Center(
              child: Text(
                'Map Preview (Google Map later)',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(Job job, bool isNewJobs) {
    if (isNewJobs) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  await jobService.acceptJob(job.id);
                  LocationService.instance.startSharing();
                  // Stream auto-updates UI — no setState needed
                },
                child: const Text(
                  'Accept',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black26),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  await jobService.declineJob(job.id);
                  // Stream auto-updates UI — no setState needed
                },
                child: const Text(
                  'Decline',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  await jobService.completeJob(job.id);
                  LocationService.instance.stopSharing();
                  // Stream auto-updates UI — no setState needed
                },
                child: const Text(
                  'Complete Job',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}
