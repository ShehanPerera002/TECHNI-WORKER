import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart'; 
import '../../widgets/app_header.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import 'select_category_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final nameCtrl = TextEditingController();
  final nicCtrl = TextEditingController();
  
  DateTime? selectedBirthDate;
  
  // Multi-language Logic
  List<String> selectedLanguages = []; 
  final List<String> availableLanguages = ["Sinhala", "Tamil", "English"];

  bool _isLoading = false;

  PlatformFile? _profilePhoto;
  PlatformFile? _nicFrontFile;
  PlatformFile? _nicBackFile;
  PlatformFile? _policeCertFile;

  @override
  void dispose() {
    nameCtrl.dispose();
    nicCtrl.dispose();
    super.dispose();
  }

  // --- Sign Out and Go Back to Welcome Logic ---
  Future<void> _handleBackNavigation() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedBirthDate = picked);
  }

  Future<void> _pickFile(String type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          if (type == 'front') _nicFrontFile = result.files.first;
          if (type == 'back') _nicBackFile = result.files.first;
          if (type == 'police') _policeCertFile = result.files.first;
          if (type == 'profile') _profilePhoto = result.files.first;
        });
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _handleNext() async {
    if (nameCtrl.text.isEmpty || 
        selectedBirthDate == null || 
        selectedLanguages.isEmpty || 
        nicCtrl.text.isEmpty || 
        _profilePhoto == null || 
        _nicFrontFile == null || 
        _nicBackFile == null || 
        _policeCertFile == null) {
      _showError('Please fill all fields and upload all documents');
      return;
    }

    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          _showError('Location permissions are required');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();

      final user = FirebaseAuth.instance.currentUser;

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SelectCategoryScreen(
              name: nameCtrl.text.trim(),
              nic: nicCtrl.text.trim(),
              birthDate: DateFormat('yyyy-MM-dd').format(selectedBirthDate!),
              phone: user?.phoneNumber ?? "",
              languages: selectedLanguages, 
              profilePhoto: _profilePhoto!,
              nicFront: _nicFrontFile!,
              nicBack: _nicBackFile!,
              policeReport: _policeCertFile!,
              latitude: position.latitude,
              longitude: position.longitude,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Could not fetch location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Disables default back behavior to use custom logic
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _handleBackNavigation,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppHeader(title: "Create Your Profile"),
                const SizedBox(height: 25),

                Center(
                  child: GestureDetector(
                    onTap: () => _pickFile('profile'),
                    child: Column(
                      children: [
                        Container(
                          height: 110, width: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[100],
                            border: Border.all(color: Colors.black12),
                            image: _profilePhoto != null 
                              ? DecorationImage(
                                  image: MemoryImage(_profilePhoto!.bytes!), 
                                  fit: BoxFit.cover
                                )
                              : null,
                          ),
                          child: _profilePhoto == null 
                            ? const Icon(Icons.camera_alt, size: 40, color: Colors.black26) 
                            : null,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Upload Profile Photo", 
                          style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600)
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),
                InputField(label: "Full Name", controller: nameCtrl),
                const SizedBox(height: 15),

                const Text("Date of Birth", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedBirthDate == null 
                            ? "Select Date" 
                            : DateFormat('yyyy-MM-dd').format(selectedBirthDate!)
                        ),
                        const Icon(Icons.calendar_month, color: Color(0xFF2563EB)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),
                
                const Text("Languages You Can Speak", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: availableLanguages.map((lang) {
                    final bool isSelected = selectedLanguages.contains(lang);
                    return FilterChip(
                      label: Text(lang),
                      selected: isSelected,
                      // FIXED: Used .withValues() instead of .withOpacity() to resolve the warning
                      selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.2),
                      checkmarkColor: const Color(0xFF2563EB),
                      onSelected: (bool value) {
                        setState(() {
                          if (value) {
                            selectedLanguages.add(lang);
                          } else {
                            selectedLanguages.remove(lang);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 15),
                InputField(label: "NIC Number", controller: nicCtrl),
                const SizedBox(height: 20),

                const Text("Required Documents", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _uploadBox("NIC Front Photo", _nicFrontFile, () => _pickFile('front')),
                const SizedBox(height: 10),
                _uploadBox("NIC Back Photo", _nicBackFile, () => _pickFile('back')),
                const SizedBox(height: 10),
                _uploadBox("Police Report", _policeCertFile, () => _pickFile('police')),

                const SizedBox(height: 30),
                
                PrimaryButton(
                  text: _isLoading ? "Fetching Location..." : "Next Step", 
                  onPressed: _isLoading ? () {} : _handleNext
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _uploadBox(String label, PlatformFile? file, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: file != null ? const Color(0xFFF0F7FF) : Colors.white,
          border: Border.all(
            color: file != null ? const Color(0xFF2563EB) : Colors.black12
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              file != null ? Icons.check_circle : Icons.upload_file, 
              color: const Color(0xFF2563EB)
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                file != null ? file.name : label, 
                overflow: TextOverflow.ellipsis
              )
            ),
            Text(
              file != null ? "Change" : "Upload", 
              style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }
}