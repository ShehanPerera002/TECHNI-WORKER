import 'package:flutter/material.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  int tabIndex = 0; // 0 = New Job Requests, 1 = Scheduled Jobs

  // Mock data (replace with Firebase/API later)
  final double weekEarnings = 5000.00;
  final double outstandingAmount = 750.00; 
  final int newJobCount = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
       
        leading: GestureDetector(
          onTap: () {
            
          },
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Color(0xFFE8F0FF),
              child: Icon(Icons.person, color: Color(0xFF2563EB), size: 20),
            ),
          ),
        ),
        title: const Text(
          "Worker Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _earningsCard(context),
            const SizedBox(height: 12),
            _payableCard(), // 💳 Outstanding Balance 
            const SizedBox(height: 18),
            _tabs(),
            const SizedBox(height: 18),
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

  // --- 💸 Weekly Earnings Card ---
  Widget _earningsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Color(0x0D000000),
            offset: Offset(0, 4),
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
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  "Rs. ${weekEarnings.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Icon(Icons.trending_up, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "+15% vs last week",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {},
            child: const Text("Details"),
          ),
        ],
      ),
    );
  }

  // --- 💳 Outstanding Balance (Debt) Card ---
  Widget _payableCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1F0), Color(0xFFFFE4E1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, color: Colors.redAccent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Outstanding Balance",
                  style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  "Rs. ${outstandingAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              // Payment logic here
            },
            child: const Text("Pay Now", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- 🗂️ Tabs (New Requests / Scheduled) ---
  Widget _tabs() {
    return Row(
      children: [
        Expanded(
          child: _tabButton(
            "New Requests",
            tabIndex == 0,
            badge: newJobCount,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _tabButton("Scheduled", tabIndex == 1)),
      ],
    );
  }

  Widget _tabButton(String text, bool active, {int? badge}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => tabIndex = (text == "New Requests") ? 0 : 1),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? const Color(0xFF2563EB) : Colors.black12,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: active ? const Color(0xFF2563EB) : Colors.black54,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 9,
                backgroundColor: Colors.red,
                child: Text(
                  "$badge",
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- 🛠️ Job Request UI ---
  Widget _jobRequestCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Plumbing • Emergency",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Leaky Pipe under Kitchen Sink",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  "1.2 km away  •  Est. Rs. 3500",
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.plumbing, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _jobInformation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          _infoRow(Icons.description_outlined, "Description", "Steady drip under the sink, needs quick repair."),
          const Divider(height: 24),
          _infoRow(Icons.location_on_outlined, "Address", "No. 63, 2/8 Cross Street, Athurugiriya"),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              // Accept logic
            },
            child: const Text("Accept Job", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              // Decline logic
            },
            child: const Text("Decline", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _scheduledJobsEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("No scheduled jobs for today", style: TextStyle(color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}