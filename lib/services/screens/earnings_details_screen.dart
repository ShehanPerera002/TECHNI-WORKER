import 'package:flutter/material.dart';

import '../../models/job_model.dart';
import '../job_service.dart';

class EarningsDetailsScreen extends StatelessWidget {
  const EarningsDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Job>>(
      stream: JobService().streamCompletedJobs(),
      builder: (context, snapshot) {
        final completedJobs = snapshot.data ?? [];
        return _buildContent(context, completedJobs);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<Job> completedJobs) {
    final now = DateTime.now();

    final todayTotal = _sumByPeriod(
      jobs: completedJobs,
      predicate: (date) => _isSameDay(date, now),
    );
    final weekTotal = _sumByPeriod(
      jobs: completedJobs,
      predicate: (date) => _isInCurrentWeek(date, now),
    );
    final monthTotal = _sumByPeriod(
      jobs: completedJobs,
      predicate: (date) => date.year == now.year && date.month == now.month,
    );
    final allCompletedTotal = completedJobs.fold<double>(
      0,
      (sum, job) => sum + job.estimatedPrice,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Earnings Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _summaryCard("Today's Earnings", _currency(todayTotal)),
          _summaryCard("This Week's Earnings", _currency(weekTotal)),
          _summaryCard("This Month's Earnings", _currency(monthTotal)),
          const SizedBox(height: 20),
          const Text(
            'Completed Jobs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (completedJobs.isEmpty)
            _emptyCompletedState()
          else
            ...completedJobs.map((job) {
              return _jobTile(
                title: job.title,
                location: job.address,
                price: _currency(job.estimatedPrice),
                date: _dateLabel(job.completedAt),
              );
            }),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: const Row(
              // Keep this section visually stable for quick scanning.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Completed Earnings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _currency(allCompletedTotal),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _emptyCompletedState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: Colors.black38),
          SizedBox(height: 8),
          Text(
            'No completed jobs yet',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  static Widget _summaryCard(String title, String amount) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          amount,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static Widget _jobTile({
    required String title,
    required String location,
    required String price,
    required String date,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text('$location  •  $date'),
        trailing: Text(
          price,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isInCurrentWeek(DateTime date, DateTime now) {
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return !date.isBefore(weekStart) && date.isBefore(weekEnd);
  }

  static double _sumByPeriod({
    required List<Job> jobs,
    required bool Function(DateTime date) predicate,
  }) {
    return jobs.fold<double>(0, (sum, job) {
      final date = job.completedAt;
      if (date == null || !predicate(date)) {
        return sum;
      }
      return sum + job.estimatedPrice;
    });
  }

  static String _currency(double amount) {
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }

  static String _dateLabel(DateTime? date) {
    if (date == null) {
      return 'Unknown date';
    }
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
