import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_model.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns the current worker's UID, or null if not logged in.
  String? get _workerId => FirebaseAuth.instance.currentUser?.uid;

  // ─── Real-time Streams ──────────────────────────────────────────────────────

  /// Stream all "pending" jobs (new job requests not yet claimed by any worker).
  Stream<List<Job>> streamNewJobs() {
    return _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Job.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Stream jobs that have been accepted by the current logged-in worker.
  Stream<List<Job>> streamScheduledJobs() {
    final wid = _workerId;
    if (wid == null) return const Stream.empty();

    return _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'accepted')
        .where('workerId', isEqualTo: wid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Job.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Stream jobs that have been completed by the current logged-in worker.
  Stream<List<Job>> streamCompletedJobs() {
    final wid = _workerId;
    if (wid == null) return const Stream.empty();

    return _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'completed')
        .where('workerId', isEqualTo: wid)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Job.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  // ─── Write Operations ────────────────────────────────────────────────────────

  /// Worker accepts a job: stamps workerId and changes status.
  Future<void> acceptJob(String jobId) async {
    final wid = _workerId;
    if (wid == null) return;

    await _firestore.collection('jobs').doc(jobId).update({
      'status': 'accepted',
      'workerId': wid,
    });
  }

  /// Worker declines a job: status stays 'pending' (job goes back to the pool).
  Future<void> declineJob(String jobId) async {
    await _firestore.collection('jobs').doc(jobId).update({
      'status': 'declined',
    });
  }

  /// Worker completes a job: stamps completion timestamp.
  Future<void> completeJob(String jobId) async {
    await _firestore.collection('jobs').doc(jobId).update({
      'status': 'completed',
      'completedAt': DateTime.now().toIso8601String(),
    });
  }
}
