import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/primary_button.dart';

// Testing auto-sync functionality - Real test
class SelectCategoryScreen extends StatefulWidget {
  const SelectCategoryScreen({super.key});

  @override
  State<SelectCategoryScreen> createState() => _SelectCategoryScreenState();
}

class _SelectCategoryScreenState extends State<SelectCategoryScreen> {
  String selected = "Plumber";

  final categories = const [
    "Plumber",
    "Electrician",
    "Gardener",
    "Carpenter",
    "Painter",
    "AC Tech",
    "Mobile Tech",
  ];

  Widget categoryTile(String name) {
    final isSelected = selected == name;

    return GestureDetector(
      onTap: () => setState(() => selected = name),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.black12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handyman, color: isSelected ? const Color(0xFF2563EB) : Colors.black45),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF2563EB) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget uploadCertBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Upload Certifications", style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF7F9FF),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Color(0xFF2563EB)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text("PDF / JPG / PNG (Max 10MB)", style: TextStyle(color: Colors.black54)),
                ),
                TextButton(onPressed: () {}, child: const Text("Upload")),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text("Example: Master_plumber_cert.pdf", style: TextStyle(fontSize: 12, color: Colors.black45)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(title: "Create Your Profile"),
              const Text("Complete your profile to connect with clients.", style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),

              const Text("Select your service category", style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: categories.map(categoryTile).toList(),
              ),

              const SizedBox(height: 16),
              uploadCertBox(),
              const SizedBox(height: 18),

              PrimaryButton(
                text: "Save Profile",
                onPressed: () {
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile saved (UI only). Connect backend later.")),
                    
                  );
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
