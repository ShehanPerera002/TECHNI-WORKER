import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/app_header.dart';
import '../widgets/input_field.dart';
import '../widgets/primary_button.dart';
import 'select_category_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final nameCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final nicCtrl = TextEditingController();

  PlatformFile? _profilePhoto;
  PlatformFile? _nicFrontFile;
  PlatformFile? _nicBackFile;
  PlatformFile? _policeCertFile;

  @override
  void dispose() {
    nameCtrl.dispose();
    ageCtrl.dispose();
    nicCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          if (type == 'front') _nicFrontFile = result.files.first;
          if (type == 'back') _nicBackFile = result.files.first;
          if (type == 'police') _policeCertFile = result.files.first;
          if (type == 'profile') _profilePhoto = result.files.first;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Widget uploadBox(String label, PlatformFile? selectedFile, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selectedFile != null ? const Color(0xFFF0F7FF) : Colors.white,
          border: Border.all(
            color: selectedFile != null ? const Color(0xFF2563EB) : Colors.black12,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              selectedFile != null ? Icons.check_circle : Icons.upload_file,
              color: const Color(0xFF2563EB),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedFile != null ? selectedFile.name : label,
                style: TextStyle(
                  color: selectedFile != null ? Colors.black87 : Colors.black54,
                  fontWeight: selectedFile != null ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selectedFile != null)
              const Icon(Icons.edit, size: 18, color: Colors.grey)
            else
              const Text(
                "Upload",
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _validateFields() {
    if (nameCtrl.text.trim().isEmpty) {
      _showError('Please enter your full name');
      return false;
    }
    if (nicCtrl.text.trim().isEmpty) {
      _showError('Please enter your NIC number');
      return false;
    }
    if (_profilePhoto == null) {
      _showError('Please upload a profile photo');
      return false;
    }
    if (_nicFrontFile == null) {
      _showError('NIC Front photo is required');
      return false;
    }
    if (_nicBackFile == null) {
      _showError('NIC Back photo is required');
      return false;
    }
    if (_policeCertFile == null) {
      _showError('Police Character Certificate is required');
      return false;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _handleNext() {
    if (!_validateFields()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.phoneNumber == null) {
      _showError('Auth session error. Please login again.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectCategoryScreen(
          name: nameCtrl.text.trim(),
          phone: user.phoneNumber!,
          profilePhoto: _profilePhoto!,
          nicFront: _nicFrontFile!,
          nicBack: _nicBackFile!,
          policeReport: _policeCertFile!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(title: "Create Your Profile"),
              const SizedBox(height: 30),
              Center(
                child: GestureDetector(
                  onTap: () => _pickFile('profile'),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFFF0F4FF),
                            backgroundImage: _profilePhoto != null && _profilePhoto!.bytes != null
                                ? MemoryImage(_profilePhoto!.bytes!)
                                : null,
                            child: _profilePhoto == null
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Color(0xFF2563EB),
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _profilePhoto != null ? "Change Photo" : "Upload Profile Photo",
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              InputField(label: "Full Name", controller: nameCtrl),
              const SizedBox(height: 12),
              InputField(
                label: "Age",
                controller: ageCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              InputField(label: "NIC Number", controller: nicCtrl),
              const SizedBox(height: 20),
              const Text(
                "Required Documents",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              uploadBox(
                "NIC Front Photo",
                _nicFrontFile,
                () => _pickFile('front'),
              ),
              const SizedBox(height: 12),
              uploadBox(
                "NIC Back Photo",
                _nicBackFile,
                () => _pickFile('back'),
              ),
              const SizedBox(height: 12),
              uploadBox(
                "Police Character Certificate",
                _policeCertFile,
                () => _pickFile('police'),
              ),
              const SizedBox(height: 30),
              PrimaryButton(text: "Next Step", onPressed: _handleNext),
            ],
          ),
        ),
      ),
    );
  }
}