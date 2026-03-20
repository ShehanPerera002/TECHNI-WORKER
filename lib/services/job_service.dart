import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_request.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns the current worker's UID, or null if not logged in.
  String? get _workerId => FirebaseAuth.instance.currentUser?.uid;

  // ─── Real-time Streams ──────────────────────────────────────────────────────

  /// Stream all "pending" jobs (new job requests where this worker is notified and status is searching).
  Stream<List<JobRequest>> streamNewJobs() {
    final wid = _workerId;
    if (wid == null) return const Stream.empty();

    return _firestore
        .collection('jobRequests')
        .where('notifiedWorkerIds', arrayContains: wid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => JobRequest.fromFirestore(doc))
            .where((req) => req.status == 'searching' && !req.rejectedWorkerIds.contains(wid))
            .toList());
  }

  /// Stream jobs that have been accepted by the current logged-in worker.
  Stream<List<JobRequest>> streamScheduledJobs() {
    final wid = _workerId;
    if (wid == null) return const Stream.empty();

    return _firestore
        .collection('jobRequests')
        .where('workerId', isEqualTo: wid)
        .where('status', whereIn: ['workerFound', 'customerConfirmed'])
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => JobRequest.fromFirestore(doc))
            .toList());
  }

  /// Stream jobs that have been completed by the current logged-in worker.
  Stream<List<JobRequest>> streamCompletedJobs() {
    final wid = _workerId;
    if (wid == null) return const Stream.empty();

    return _firestore
        .collection('jobRequests')
        .where('status', isEqualTo: 'completed')
        .where('workerId', isEqualTo: wid)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => JobRequest.fromFirestore(doc))
            .toList());
  }

  // ─── Write Operations ────────────────────────────────────────────────────────

  /// Worker accepts a job: stamps workerId and changes status.
  Future<void> acceptJob(String jobId) async {
    final wid = _workerId;
    if (wid == null) return;

    await _firestore.collection('jobRequests').doc(jobId).update({
      'status': 'workerFound',
      'workerId': wid,
      'workerAcceptedAt': FieldValue.serverTimestamp(),
    });
    
    await _firestore.collection('workers').doc(wid).update({
      'isAvailable': false,
      'activeJobId': jobId,
    });
  }

  /// Worker declines a job: adds workerId to rejectedWorkerIds array.
  Future<void> declineJob(String jobId) async {
    final wid = _workerId;
    if (wid == null) return;

    await _firestore.collection('jobRequests').doc(jobId).update({
      'rejectedWorkerIds': FieldValue.arrayUnion([wid]),
    });
  }

  /// Worker completes a job: stamps completion timestamp.
  Future<void> completeJob(String jobId) async {
    final wid = _workerId;
    if (wid == null) return;

    await _firestore.collection('jobRequests').doc(jobId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('workers').doc(wid).update({
      'isAvailable': true,
      'activeJobId': FieldValue.delete(),
    });
  }
}
