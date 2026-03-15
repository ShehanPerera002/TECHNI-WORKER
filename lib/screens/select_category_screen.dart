import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

// Ensure these paths match your folder structure exactly
import '../widgets/app_header.dart';
import '../widgets/primary_button.dart';
import '../services/upload_service.dart';

class SelectCategoryScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String birthDate; // Updated field
  final String language;
  final PlatformFile profilePhoto;
  final PlatformFile nicFront;
  final PlatformFile nicBack;
  final PlatformFile policeReport;

  const SelectCategoryScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.birthDate, // Updated here
    required this.language,
    required this.profilePhoto,
    required this.nicFront,
    required this.nicBack,
    required this.policeReport,
  });

  @override
  State<SelectCategoryScreen> createState() => _SelectCategoryScreenState();
}

class _SelectCategoryScreenState extends State<SelectCategoryScreen> {
  String selectedCategory = "Plumber";
  final List<String> categories = const [
    "Plumber", "Electrician", "Gardener", 
    "Carpenter", "Painter", "AC Tech"
  ];

  final List<PlatformFile> _certFiles = []; // Changed to final as per lint warning
  bool _isSaving = false;
  String _loadingMessage = "";

  Future<void> _handleSaveProfile() async {
    // Validation: Check if certificates are uploaded
    if (_certFiles.isEmpty) {
      _showError("Please upload at least one professional certificate.");
      return;
    }

    setState(() {
      _isSaving = true;
      _loadingMessage = "Fetching your location...";
    });

    try {
      // 1. Get Location with updated settings to avoid deprecation warning
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final uploadService = UploadService();

      // 2. Upload Mandatory Identity Documents
      setState(() => _loadingMessage = "Uploading profile & identity docs...");
      String? profileUrl = await uploadService.uploadToCloudinary(widget.profilePhoto);
      String? nicFrontUrl = await uploadService.uploadToCloudinary(widget.nicFront);
      String? nicBackUrl = await uploadService.uploadToCloudinary(widget.nicBack);
      String? policeUrl = await uploadService.uploadToCloudinary(widget.policeReport);

      // 3. Upload Multiple Certificates
      List<String> certUrls = [];
      for (int i = 0; i < _certFiles.length; i++) {
        setState(() => _loadingMessage = "Uploading certificate ${i + 1} of ${_certFiles.length}...");
        String? url = await uploadService.uploadToCloudinary(_certFiles[i]);
        if (url != null) certUrls.add(url);
      }

      // 4. Save Worker Data to Firestore
      setState(() => _loadingMessage = "Finalizing your profile...");
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final workerRef = FirebaseFirestore.instance.collection('workers').doc(uid);

      await workerRef.set({
        'name': widget.name,
        'phoneNumber': widget.phone,
        'dob': widget.birthDate, // Added Date of Birth
        'language': widget.language,
        'category': selectedCategory,
        'location': GeoPoint(position.latitude, position.longitude),
        'profileUrl': profileUrl,
        'nicFrontUrl': nicFrontUrl,
        'nicBackUrl': nicBackUrl,
        'policeReportUrl': policeUrl,
        'certificates': certUrls,
        'ratingCount': 0,
        'averageRating': 0.0,
        'verificationStatus': 'pending',
        'isOnline': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 5. Initialize Reviews
      await workerRef.collection('reviews').add({
        'reviewerName': 'System',
        'rating': 5,
        'comment': 'Welcome to the platform! Your profile is pending verification.',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return; // Async check
      Navigator.pushNamedAndRemoveUntil(context, '/pending', (route) => false);

    } catch (e) {
      if (!mounted) return;
      _showError("Failed to save profile: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.black)
      ),
      body: _isSaving ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(title: "Complete Profile"),
            const SizedBox(height: 10),
            const Text(
              "Select your primary service and upload certificates.", 
              style: TextStyle(color: Colors.black54, fontSize: 13)
            ),
            const SizedBox(height: 25),
            const Text("Service Category", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildCategoryGrid(),
            const SizedBox(height: 30),
            _buildCertificateHeader(),
            const SizedBox(height: 10),
            _buildUploadBox(),
            if (_certFiles.isNotEmpty) ...[
              const SizedBox(height: 15),
              ..._certFiles.map((file) => _filePreviewTile(file)),
            ],
            const SizedBox(height: 40),
            PrimaryButton(text: "Save & Finish", onPressed: _handleSaveProfile),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: categories.map((c) => _categoryTile(c)).toList(),
    );
  }

  Widget _buildCertificateHeader() {
    return const Row(
      children: [
        Text("Professional Certificates", style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(width: 4),
        Text("*", style: TextStyle(color: Colors.red)),
      ],
    );
  }

  Widget _categoryTile(String name) {
    final bool isSelected = selectedCategory == name;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = name),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.black12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, color: isSelected ? const Color(0xFF2563EB) : Colors.black38),
            const SizedBox(height: 5),
            Text(
              name, 
              style: TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.bold, 
                color: isSelected ? const Color(0xFF2563EB) : Colors.black87
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadBox() {
    return GestureDetector(
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
          withData: true,
        );
        if (result != null) setState(() => _certFiles.addAll(result.files));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: const Column(
          children: [
            Icon(Icons.upload_file_outlined, color: Color(0xFF2563EB), size: 30),
            SizedBox(height: 8),
            Text("Click to upload documents", style: TextStyle(fontWeight: FontWeight.w600)),
            Text("NVQ, Diploma, or Training Certs", style: TextStyle(fontSize: 12, color: Colors.black45)),
          ],
        ),
      ),
    );
  }

  Widget _filePreviewTile(PlatformFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.description, size: 20, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(child: Text(file.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            onPressed: () => setState(() => _certFiles.remove(file)),
          )
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF2563EB)),
          const SizedBox(height: 20),
          Text(_loadingMessage, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}