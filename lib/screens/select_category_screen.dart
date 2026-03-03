import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/primary_button.dart';

import '../services/upload_service.dart';

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
    "ELV Repair",
  ];

  final UploadService _uploadService = UploadService();
  String? _uploadedFileName;
  bool _uploading = false;

  Widget categoryTile(String name) {
    final isSelected = selected == name;
    return GestureDetector(
      onTap: () => setState(() => selected = name),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.black12,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.handyman,
              color: isSelected ? const Color(0xFF2563EB) : Colors.black45,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: isSelected ? const Color(0xFF2563EB) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadDocument() async {
    setState(() => _uploading = true);
    try {
      final pickedFile = await _uploadService.pickDocument();
      if (pickedFile != null) {
        setState(() {
          _uploadedFileName = pickedFile.name;
        });
        // Optionally upload to backend here:
        // await _uploadService.uploadDocument(pickedFile, 'your_token');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick document: $e')),
      );
    } finally {
      setState(() => _uploading = false);
    }
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
          const Text(
            "Upload Certifications",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _uploading ? null : _pickAndUploadDocument,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF7F9FF),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 28,
                    color: _uploading ? Colors.grey : const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _uploading ? "Uploading..." : "Click to upload documents",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "PDF, JPG, PNG (Max 10MB)",
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_uploadedFileName != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF7F9FF),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_uploadedFileName!)),
                  GestureDetector(
                    onTap: () => setState(() => _uploadedFileName = null),
                    child: const Icon(Icons.delete, size: 18),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(title: "Create Your Profile"),
              const SizedBox(height: 10),

              /// PROFILE IMAGE
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundImage: const AssetImage(
                        'assets/images/create_your_profile_page.png',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Complete your profile to connect with clients",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Select your service category",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: categories.map(categoryTile).toList(),
              ),

              const SizedBox(height: 20),
              uploadCertBox(),
              const SizedBox(height: 22),

              PrimaryButton(
                text: "Save Profile",
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
