import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/app_header.dart';
import '../widgets/primary_button.dart';
import '../services/upload_service.dart';

class SelectCategoryScreen extends StatefulWidget {
  final String name;
  final String phone;
  final PlatformFile profilePhoto;
  final PlatformFile nicFront;
  final PlatformFile nicBack;
  final PlatformFile policeReport;

  const SelectCategoryScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.profilePhoto,
    required this.nicFront,
    required this.nicBack,
    required this.policeReport,
  });

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

  List<PlatformFile> _certFiles = [];
  bool _isSaving = false;
  String _loadingMessage = "";

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

  Future<void> _pickDocuments() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _certFiles.addAll(result.files);
        });
      }
    } catch (e) {
      _showError("Failed to pick documents: $e");
    }
  }

  Future<void> _handleSaveProfile() async {
    setState(() {
      _isSaving = true;
      _loadingMessage = "Getting location...";
    });

    try {
      // 1. Get Location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final uploadService = UploadService();

      // 2. Upload Files to Cloudinary
      setState(() => _loadingMessage = "Uploading Profile Photo...");
      String? profileUrl = await uploadService.uploadToCloudinary(widget.profilePhoto);

      setState(() => _loadingMessage = "Uploading NIC Front...");
      String? nicFrontUrl = await uploadService.uploadToCloudinary(widget.nicFront);

      setState(() => _loadingMessage = "Uploading NIC Back...");
      String? nicBackUrl = await uploadService.uploadToCloudinary(widget.nicBack);

      setState(() => _loadingMessage = "Uploading Police Report...");
      String? policeUrl = await uploadService.uploadToCloudinary(widget.policeReport);

      List<String> certUrls = [];
      for (int i = 0; i < _certFiles.length; i++) {
        setState(() => _loadingMessage = "Uploading Certificate ${i + 1}...");
        String? url = await uploadService.uploadToCloudinary(_certFiles[i]);
        if (url != null) certUrls.add(url);
      }

      // 3. Save to Firestore
      setState(() => _loadingMessage = "Saving Profile...");
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('workers').doc(uid).set({
        'name': widget.name,
        'phoneNumber': widget.phone,
        'category': selected,
        'location': GeoPoint(position.latitude, position.longitude),
        'profileUrl': profileUrl,
        'nicFrontUrl': nicFrontUrl,
        'nicBackUrl': nicBackUrl,
        'policeReportUrl': policeUrl,
        'certificates': certUrls,
        'ratingCount': 0,
        'totalRatingSum': 0.0,
        'averageRating': 0.0,
        'verificationStatus': 'pending', // මුලින්ම pending status එක යනවා
        'isOnline': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // 🔵 වැදගත්: දැන් කෙලින්ම යන්නේ Pending screen එකටයි
        Navigator.pushNamedAndRemoveUntil(context, '/pending', (route) => false);
      }
    } catch (e) {
      _showError("Error saving profile: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isSaving
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF2563EB)),
                  const SizedBox(height: 20),
                  Text(_loadingMessage, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppHeader(title: "Complete Your Profile"),
                    const SizedBox(height: 10),
                    const Text(
                      "Select your service category and upload any professional certificates.",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 25),
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
                    const SizedBox(height: 25),
                    const Text(
                      "Professional Certifications",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    _buildUploadBox(),
                    const SizedBox(height: 30),
                    PrimaryButton(
                      text: "Save & Finish",
                      onPressed: _handleSaveProfile,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUploadBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickDocuments,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF7F9FF),
                border: Border.all(color: Colors.black12, style: BorderStyle.solid),
              ),
              child: const Column(
                children: [
                  Icon(Icons.cloud_upload, size: 28, color: Color(0xFF2563EB)),
                  SizedBox(height: 6),
                  Text("Click to upload documents", style: TextStyle(fontWeight: FontWeight.w600)),
                  Text("Certificates, Diplomas (PDF, JPG)", style: TextStyle(fontSize: 12, color: Colors.black45)),
                ],
              ),
            ),
          ),
          if (_certFiles.isNotEmpty) ...[
            const SizedBox(height: 10),
            ..._certFiles.map((file) => Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(file.name, style: const TextStyle(fontSize: 13))),
                      GestureDetector(
                        onTap: () => setState(() => _certFiles.remove(file)),
                        child: const Icon(Icons.close, size: 18, color: Colors.red),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
