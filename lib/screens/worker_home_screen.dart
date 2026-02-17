import 'package:flutter/material.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  int tabIndex = 0; // 0 = New Job Requests, 1 = Scheduled Jobs

  // Mock data (replace with API later)
  final double weekEarnings = 5000.00;
  final int newJobCount = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text("Worker home screen"),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _earningsCard(context),
            const SizedBox(height: 14),
            _tabs(),
            const SizedBox(height: 14),
            if (tabIndex == 0) ...[
              _jobRequestCard(),
              const SizedBox(height: 14),
              _jobInformation(),
              const SizedBox(height: 18),
              _actionButtons(),
            ] else ...[
              _scheduledJobsEmpty(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _earningsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(blurRadius: 10, color: Color(0x11000000), offset: Offset(0, 6)),
        ],
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("This Week's Earnings", style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                Text(
                  "Rs. ${weekEarnings.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.green, size: 18),
                    SizedBox(width: 6),
                    Text(
                      "+15% from last week",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Earnings details (UI only)")),
                );
              },
              child: const Text("View Details"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Row(
      children: [
        Expanded(child: _tabButton("New Job Requests", tabIndex == 0, badge: newJobCount)),
        const SizedBox(width: 10),
        Expanded(child: _tabButton("Scheduled Jobs", tabIndex == 1)),
      ],
    );
  }

  Widget _tabButton(String text, bool active, {int? badge}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => tabIndex = (text == "New Job Requests") ? 0 : 1),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? const Color(0xFF2563EB) : Colors.black12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
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
                  "$badge",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _jobRequestCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 6))],
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Plumbing • Emergency",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  "Leaky Pipe under Kitchen Sink",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                SizedBox(height: 6),
                Text(
                  "1 km away  •  Est. Rs. 3500",
                  style: TextStyle(color: Colors.black54),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text("Customer Rating: ", style: TextStyle(color: Colors.black54)),
                    Icon(Icons.star, color: Colors.orange, size: 16),
                    Icon(Icons.star, color: Colors.orange, size: 16),
                    Icon(Icons.star, color: Colors.orange, size: 16),
                    Icon(Icons.star, color: Colors.orange, size: 16),
                    Icon(Icons.star_half, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Text("4.5", style: TextStyle(fontWeight: FontWeight.w700)),
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
          )
        ],
      ),
    );
  }

  Widget _jobInformation() {
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
          const Text("Job Information", style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),

          // Description
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.description, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Description", style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text(
                      "The main pipe under the kitchen sink has a steady drip. "
                      "It's been getting worse over the last day and we need a quick fix.",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.location_on, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Address", style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text(
                      "No. 63, 2/8 Cross Street, Athurugiriya",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Map placeholder
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
                "Map Preview (Google Map later)",
                style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Accepted (UI only)")),
                );
              },
              child: const Text("Accept", style: TextStyle(fontWeight: FontWeight.w800)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Declined (UI only)")),
                );
              },
              child: const Text("Decline", style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _scheduledJobsEmpty() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
        color: Colors.white,
      ),
      child: const Text(
        "No scheduled jobs yet.\n(Connect backend later)",
        style: TextStyle(color: Colors.black54, height: 1.4),
      ),
    );
  }
}
