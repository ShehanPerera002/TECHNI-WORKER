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
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'earnings_details_screen.dart';
import 'job_details_screen.dart';
import 'worker_navigation_screen.dart';
import '../../models/job_request.dart';
import '../job_service.dart';
import '../location_service.dart';
import 'worker_profile_screen.dart';

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
  
  List<JobRequest> _newJobs = [];
  List<JobRequest> _scheduledJobs = [];
  List<JobRequest> _ongoingJobs = [];
  List<JobRequest> _completedJobs = [];
  
  StreamSubscription<List<JobRequest>>? _newJobsSub;
  StreamSubscription<List<JobRequest>>? _scheduledJobsSub;
  StreamSubscription<List<JobRequest>>? _ongoingJobsSub;
  StreamSubscription<List<JobRequest>>? _completedJobsSub;
  StreamSubscription<QuerySnapshot>? _confirmedJobSub;
  bool _hasNavigatedToJob = false;
  String? _streamError;
  Map<String, dynamic>? _workerProfile;

  @override
  void initState() {
    super.initState();
    _loadDndStatus();
    _subscribeToJobs();
    _listenForConfirmedJobs();
    _fetchWorkerProfile();
  }

  Future<void> _fetchWorkerProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _workerProfile = doc.data();
        });
      }
    }
  }

  void _subscribeToJobs() {
    _newJobsSub = jobService.streamNewJobs().listen(
      (jobs) { if (mounted) setState(() { _newJobs = jobs; _streamError = null; }); },
      onError: (e) => _handleStreamError('New', e),
    );
    _scheduledJobsSub = jobService.streamScheduledJobs().listen(
      (jobs) { if (mounted) setState(() { _scheduledJobs = jobs; _streamError = null; }); },
      onError: (e) => _handleStreamError('Scheduled', e),
    );
    _ongoingJobsSub = jobService.streamOngoingJobs().listen(
      (jobs) { if (mounted) setState(() { _ongoingJobs = jobs; _streamError = null; }); },
      onError: (e) => _handleStreamError('Ongoing', e),
    );
    _completedJobsSub = jobService.streamCompletedJobs().listen(
      (jobs) { if (mounted) setState(() { _completedJobs = jobs; _streamError = null; }); },
      onError: (e) => _handleStreamError('Completed', e),
    );
  }

  void _handleStreamError(String source, Object e) {
    debugPrint('$source jobs stream error: $e');
    if (mounted) {
      setState(() {
        _streamError = e.toString();
      });
    }
  }

  /// Listens for jobs where the customer has confirmed this worker.
  /// When detected, auto-navigates to the WorkerNavigationScreen.
  void _listenForConfirmedJobs() {
    final workerId = FirebaseAuth.instance.currentUser?.uid;
    if (workerId == null) return;

    _confirmedJobSub?.cancel();
    _confirmedJobSub = FirebaseFirestore.instance
        .collection('jobRequests')
        .where('status', isEqualTo: 'customerConfirmed')
        .where('workerId', isEqualTo: workerId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty && !_hasNavigatedToJob && mounted) {
        final doc = snapshot.docs.first;
        final job = JobRequest.fromFirestore(doc);
        _hasNavigatedToJob = true;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkerNavigationScreen(job: job),
          ),
        ).then((_) {
          // Reset flag when returning from navigation screen
          _hasNavigatedToJob = false;
        });
      }
    });
  }

  Future<void> _loadDndStatus() async {
    final workerId = FirebaseAuth.instance.currentUser?.uid;
    if (workerId == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance.collection('workers').doc(workerId).get();
      if (doc.exists && doc.data() != null) {
        final isDnd = doc.data()!['doNotDisturb'] ?? false;
        final isAvailable = doc.data()!['isAvailable'];
        
        setState(() {
          _isDndActive = isDnd;
        });

        // Ensure isAvailable matches DND status if unset or incorrectly set
        if (isAvailable != !isDnd) {
           _toggleDnd(isDnd);
        }
      } else {
        _toggleDnd(false);
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
        'isAvailable': !value,
        'fcmToken': 'dummy-token', // Prevent null errors if not initialized previously
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error setting DND status: $e');
    }
  }

  String _formatTime(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return seconds >= 3600 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _newJobsSub?.cancel();
    _scheduledJobsSub?.cancel();
    _ongoingJobsSub?.cancel();
    _completedJobsSub?.cancel();
    _confirmedJobSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
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
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkerProfileScreen()),
                ).then((_) => _fetchWorkerProfile());
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue.shade50,
                backgroundImage: (_workerProfile?['profileUrl'] != null && _workerProfile!['profileUrl'].toString().isNotEmpty)
                    ? (_workerProfile!['profileUrl'].toString().startsWith('http')
                        ? NetworkImage(_workerProfile!['profileUrl'])
                        : FileImage(File(_workerProfile!['profileUrl']))) as ImageProvider
                    : null,
                child: (_workerProfile?['profileUrl'] == null || _workerProfile!['profileUrl'].toString().isEmpty)
                    ? const Icon(Icons.person, size: 18, color: Colors.blue)
                    : null,
              ),
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
                _jobsSection(jobs: _newJobs, type: 'new')
              else if (tabIndex == 1)
                _jobsSection(jobs: _scheduledJobs, type: 'scheduled')
              else if (tabIndex == 2)
                _jobsSection(jobs: _ongoingJobs, type: 'ongoing')
              else
                _jobsSection(jobs: _completedJobs, type: 'completed'),
            ],
          ),
        ),
      ),
    );
  }

  // Pull-to-refresh just forces the stream to re-evaluate (streams auto-update, nothing needed)
  Future<void> _refreshJobs() async {
    setState(() {
      _hasNavigatedToJob = false; // Reset navigation flag on manual refresh
      _streamError = null;
    });
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabButton(
            'New Jobs',
            tabIndex == 0,
            index: 0,
            badge: newJobCount,
          ),
          const SizedBox(width: 8),
          _tabButton('Scheduled', tabIndex == 1, index: 1),
          const SizedBox(width: 8),
          _tabButton('Ongoing', tabIndex == 2, index: 2),
          const SizedBox(width: 8),
          _tabButton('Completed', tabIndex == 3, index: 3),
        ],
      ),
    );
  }

  Widget _tabButton(String text, bool active, {required int index, int? badge}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => tabIndex = index),
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
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: active ? const Color(0xFF2563EB) : Colors.black87,
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

  Widget _jobsSection({required List<JobRequest> jobs, required String type}) {
    if (_streamError != null && ((type == 'completed' && _completedJobs.isEmpty) || (type == 'ongoing' && _ongoingJobs.isEmpty) || (type == 'scheduled' && _scheduledJobs.isEmpty) || (type == 'new' && _newJobs.isEmpty))) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 12),
            const Text(
              'Sync Error',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              _streamError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade800, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _refreshJobs,
              child: const Text('Retry Sync'),
            ),
          ],
        ),
      );
    }

    if (jobs.isEmpty) {
      IconData icon;
      String message;
      switch (type) {
        case 'new':
          icon = Icons.work_outline;
          message = 'No job requests available right now';
          break;
        case 'scheduled':
          icon = Icons.calendar_month_outlined;
          message = 'No scheduled jobs yet.';
          break;
        case 'ongoing':
          icon = Icons.running_with_errors;
          message = 'No ongoing jobs at the moment.';
          break;
        default:
          icon = Icons.check_circle_outline;
          message = 'No completed jobs yet.';
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.black38, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (type == 'completed' && jobs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear History'),
                    content: const Text('Are you sure you want to delete all completed job records?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await jobService.clearCompletedJobs();
                }
              },
              icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 20),
              label: const Text('Delete All Completed', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ),
        
        if (type == 'ongoing' && jobs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cleanup Ongoing'),
                    content: const Text('This will remove all stuck or stale active jobs from your list and reset your status to Available. Continue?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cleanup', style: TextStyle(color: Colors.orange))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await jobService.clearOngoingJobs();
                }
              },
              icon: const Icon(Icons.cleaning_services, color: Colors.orange, size: 20),
              label: const Text('Clear All Ongoing (Cleanup)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
          ),
        ...jobs.map((job) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                _jobRequestCard(job),
                const SizedBox(height: 12),
                _actionButtons(job, type),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _jobRequestCard(JobRequest job) {
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
                      '${job.jobType} • Normal',
                      style: TextStyle(
                        color: const Color(0xFF2563EB),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${job.jobType} Request',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '2.5 km away  •  Est. Rs. ${job.fare?.toStringAsFixed(0) ?? '0'}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Customer Rating: ',
                          style: TextStyle(color: Colors.black54),
                        ),
                        ..._buildStars(job.rating?.toDouble() ?? 5.0),
                        const SizedBox(width: 4),
                        Text(
                          job.rating?.toString() ?? '5.0',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    if (job.status == 'completed' && job.review != null && job.review!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.format_quote, color: Colors.blue, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                job.review!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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


  Widget _actionButtons(JobRequest job, String type) {
    if (type == 'new') {
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
    } else if (type == 'ongoing') {
      return SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton.icon(
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
                builder: (context) => WorkerNavigationScreen(job: job),
              ),
            );
          },
          icon: Icon(
            job.status == 'workStarted' ? Icons.timer : Icons.navigation,
            size: 18,
          ),
          label: Text(
            job.status == 'workStarted'
                ? 'View Active Timer'
                : 'Continue to Customer',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
    } else if (type == 'completed') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Job Completed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Duration: ${job.durationSeconds != null ? _formatTime(job.durationSeconds!) : "N/A"}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  'Earned: Rs. ${job.fare?.toStringAsFixed(2) ?? "0.00"}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      );
    } else {
      // Scheduled (workerFound or customerConfirmed)
      if (job.status == 'customerConfirmed') {
        return SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkerNavigationScreen(job: job),
                ),
              );
            },
            icon: const Icon(Icons.navigation, size: 18),
            label: const Text(
              'Start Navigation',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Text(
          'Waiting for customer confirmation...',
          style: TextStyle(
            color: Colors.amber.shade900,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      );
    }
  }
}
