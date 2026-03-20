import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/app_header.dart';
import '../../widgets/primary_button.dart';
import '../upload_service.dart'; 

class SelectCategoryScreen extends StatefulWidget {
  final String name;
  final String nic;
  final String phone;
  final String birthDate;
  final List<String> languages; // Updated: Now accepts a List of languages
  final PlatformFile profilePhoto;
  final PlatformFile nicFront;
  final PlatformFile nicBack;
  final PlatformFile policeReport;
  final double latitude;
  final double longitude;

  const SelectCategoryScreen({
    super.key,
    required this.name,
    required this.nic,
    required this.phone,
    required this.birthDate,
    required this.languages, // Updated Constructor
    required this.profilePhoto,
    required this.nicFront,
    required this.nicBack,
    required this.policeReport,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<SelectCategoryScreen> createState() => _SelectCategoryScreenState();
}

class _SelectCategoryScreenState extends State<SelectCategoryScreen> {
  String selectedCategory = "Plumber";
  final categories = const [
    "Plumber", "Electrician", "Gardener", 
    "Carpenter", "Painter", "AC Tech", "ELV Repair"
  ];

  final List<PlatformFile> _certFiles = [];
  bool _isSaving = false;
  String _loadingMessage = "";

  // --- Profile Saving Logic with Sub-collection ---
  Future<void> _handleSaveProfile() async {
    if (_certFiles.isEmpty) {
      _showError("Please upload at least one professional certificate.");
      return;
    }

    setState(() {
      _isSaving = true;
      _loadingMessage = "Initializing upload...";
    });

    try {
      final uploadService = UploadService();
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        _showError("User not logged in.");
        return;
      }

      // 1. Upload Identity Documents to Cloudinary
      setState(() => _loadingMessage = "Uploading identity documents...");
      String? profileUrl = await uploadService.uploadToCloudinary(widget.profilePhoto);
      String? nicFrontUrl = await uploadService.uploadToCloudinary(widget.nicFront);
      String? nicBackUrl = await uploadService.uploadToCloudinary(widget.nicBack);
      String? policeUrl = await uploadService.uploadToCloudinary(widget.policeReport);

      // 2. Upload Professional Certificates
      List<String> certUrls = [];
      for (int i = 0; i < _certFiles.length; i++) {
        setState(() => _loadingMessage = "Uploading certificate ${i + 1} of ${_certFiles.length}...");
        String? url = await uploadService.uploadToCloudinary(_certFiles[i]);
        if (url != null) certUrls.add(url);
      }

      // 3. Save to Firestore using Write Batch (Atomic Update)
      setState(() => _loadingMessage = "Finalizing your profile...");
      
      final WriteBatch batch = FirebaseFirestore.instance.batch();
      final DocumentReference workerRef = FirebaseFirestore.instance.collection('workers').doc(uid);

      // Set Main Worker Profile
      batch.set(workerRef, {
        'uid': uid,
        'name': widget.name,
        'nic': widget.nic,
        'phoneNumber': widget.phone,
        'dob': widget.birthDate,
        'languages': widget.languages, // Saving as Array/List
        'category': selectedCategory,
        'location': GeoPoint(widget.latitude, widget.longitude),
        'profileUrl': profileUrl,
        'nicFrontUrl': nicFrontUrl,
        'nicBackUrl': nicBackUrl,
        'policeReportUrl': policeUrl,
        'certificates': certUrls,
        'verificationStatus': 'pending',
        'isOnline': false,
        'averageRating': 5.0,
        'ratingCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add Welcome Review to Sub-collection
      final DocumentReference reviewRef = workerRef.collection('reviews').doc(); // Auto-ID
      batch.set(reviewRef, {
        'reviewerName': 'System',
        'rating': 5,
        'comment': 'Welcome to the platform! Your profile is pending verification.',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Execute Batch
      await batch.commit();

      if (!mounted) return;
      
      Navigator.pushNamedAndRemoveUntil(context, '/pending', (route) => false);

    } catch (e) {
      _showError("Failed to save profile: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent)
    );
  }

  // --- UI Methods (No UI changes, kept as per your request) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0, 
        backgroundColor: Colors.white, 
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
            const AppHeader(title: "Complete Your Profile"),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "Select your service category", 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3, 
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10, 
              crossAxisSpacing: 10,
              children: categories.map(_categoryTile).toList(),
            ),
            const SizedBox(height: 30),
            const Text(
              "Professional Certifications", 
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)
            ),
            const Text(
              "Upload any NVQ or professional certificates you have.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            _buildUploadBox(),
            const SizedBox(height: 15),
            ..._certFiles.map((file) => _filePreviewTile(file)),
            const SizedBox(height: 40),
            PrimaryButton(
              text: "Save & Submit for Review", 
              onPressed: _handleSaveProfile
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
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
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.black12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction, 
              color: isSelected ? const Color(0xFF2563EB) : Colors.black38
            ),
            const SizedBox(height: 5),
            Text(
              name, 
              textAlign: TextAlign.center,
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
          withData: true,
          type: FileType.custom,
          allowedExtensions: ['jpg', 'png', 'pdf'],
        );
        if (result != null) setState(() => _certFiles.addAll(result.files));
      },
      child: Container(
        width: double.infinity, 
        padding: const EdgeInsets.symmetric(vertical: 25),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC), 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid)
        ),
        child: const Column(
          children: [
            Icon(Icons.cloud_upload_outlined, color: Color(0xFF2563EB), size: 35),
            SizedBox(height: 10),
            Text(
              "Tap to upload certificates", 
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)
            )
          ]
        ),
      ),
    );
  }

  Widget _filePreviewTile(PlatformFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: const Icon(Icons.description_outlined, color: Color(0xFF2563EB)),
        title: Text(file.name, style: const TextStyle(fontSize: 13)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red), 
          onPressed: () => setState(() => _certFiles.remove(file))
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          const CircularProgressIndicator(color: Color(0xFF2563EB)), 
          const SizedBox(height: 25), 
          Text(
            _loadingMessage, 
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)
          )
        ]
      )
    );
  }
}