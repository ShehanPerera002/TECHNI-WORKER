import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/job_request.dart';

class WorkerTimerScreen extends StatefulWidget {
  final JobRequest job;

  const WorkerTimerScreen({super.key, required this.job});

  @override
  State<WorkerTimerScreen> createState() => _WorkerTimerScreenState();
}

class _WorkerTimerScreenState extends State<WorkerTimerScreen> {
  static const String _baseUrl = 'https://techni-backend.onrender.com';

  int _timerSeconds = 0;
  DateTime? _jobStartedAt;
  late final Ticker _ticker;
  StreamSubscription<DocumentSnapshot>? _jobStatusSub;
  Timer? _syncTimer;
  bool _isEndingJob = false;
  String? _currentWorkerId;
  int? _completedFare;
  int? _completedServiceFee;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker(_onTick);
    _currentWorkerId = FirebaseAuth.instance.currentUser?.uid;
    _listenToJobStatus();
  }

  void _onTick(Duration duration) {
    if (_jobStartedAt != null && mounted) {
      setState(() {
        _timerSeconds = DateTime.now().difference(_jobStartedAt!).inSeconds;
      });
    }
  }

  void _startTimerSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (mounted) {
        _syncTimerWithBackend();
      }
    });
  }

  Future<void> _syncTimerWithBackend() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/job/${widget.job.id}/elapsed-time'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final backendElapsedSeconds = data['elapsedSeconds'] ?? 0;
          if ((_timerSeconds - backendElapsedSeconds).abs() > 2) {
            setState(() {
              _timerSeconds = backendElapsedSeconds;
              debugPrint('[TIMER_SYNC] Synced with backend: $_timerSeconds seconds');
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[TIMER_SYNC] Error: $e');
    }
  }

  void _listenToJobStatus() {
    _jobStatusSub = FirebaseFirestore.instance
        .collection('jobRequests')
        .doc(widget.job.id)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      // Job document deleted = archived to 'completed jobs' by backend
      if (!doc.exists) {
        if (_ticker.isActive) _ticker.stop();
        _syncTimer?.cancel();
        _showCompletionDialog();
        return;
      }
      final data = doc.data()!;
      final status = data['status'];

      if (status == 'workStarted') {
        final startedAt = data['jobStartedAt'];
        if (startedAt is Timestamp) {
          _jobStartedAt = startedAt.toDate();
          if (!_ticker.isActive) _ticker.start();
          _startTimerSync();
        }
      }
    });
  }

  Future<void> _endJob() async {
    if (_isEndingJob) return;
    setState(() => _isEndingJob = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/worker/complete-job'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jobId': widget.job.id,
          'category_name': widget.job.jobType,
          'workerId': _currentWorkerId,
        }),
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('[COMPLETE_JOB] workerEarnings: ${data['workerEarnings']}, totalEarnings: ${data['totalEarnings']}');
          if (_ticker.isActive) _ticker.stop();
          _syncTimer?.cancel();
          setState(() {
            _completedFare = data['fare'];
            _completedServiceFee = null; // backend deducted already
          });
          // Dialog will be triggered by _listenToJobStatus when doc disappears
          // But also show immediately in case listener misses it
          _showCompletionDialog();
        }
      } else {
        final body = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['error'] ?? 'Failed to complete job'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error — check backend is running'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isEndingJob = false);
    }
  }

  bool _completionDialogShown = false;

  void _showCompletionDialog() {
    if (_completionDialogShown) return;
    _completionDialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Job Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${_formatTimer(_timerSeconds)}', style: const TextStyle(fontSize: 15)),
            if (_completedFare != null) ...
              [
                const SizedBox(height: 8),
                Text('Customer Fare: Rs. $_completedFare', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            const SizedBox(height: 12),
            const Text(
              'Service fee has been deducted from your wallet.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).popUntil((route) => route.isFirst); // back to home
            },
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTimer(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return seconds >= 3600 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _ticker.dispose();
    _jobStatusSub?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Work in Progress'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Timer Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'WORK IN PROGRESS',
                      style: TextStyle(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _formatTimer(_timerSeconds),
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w300,
                        fontFamily: 'monospace',
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Timer is synced with customer',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      widget.job.customerName.isNotEmpty
                          ? 'Working at ${widget.job.customerName}\'s place'
                          : 'Working...',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // End Job Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  onPressed: _isEndingJob ? null : _endJob,
                  icon: _isEndingJob
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.stop_circle),
                  label: Text(
                    _isEndingJob ? 'Ending Job...' : 'End Job',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Back Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Back to Map'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
