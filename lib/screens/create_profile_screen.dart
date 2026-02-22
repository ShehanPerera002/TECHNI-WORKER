import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/input_field.dart';
import '../widgets/primary_button.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final nameCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final nicCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    ageCtrl.dispose();
    nicCtrl.dispose();
    super.dispose();
  }

  Widget uploadBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.upload_file, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.black54)),
          ),
          TextButton(onPressed: () {}, child: const Text("Upload")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(title: "Create Your Profile"),
              const SizedBox(height: 20),

              /// 🔵 EMPTY PROFILE CIRCLE (same as prototype)
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 110,
                      width: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Upload Profile Photo",
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              InputField(label: "Full Name", controller: nameCtrl),
              const SizedBox(height: 12),

              InputField(
                label: "Age",
                controller: ageCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              InputField(label: "NIC Number", controller: nicCtrl),
              const SizedBox(height: 12),

              uploadBox("Upload a photo of NIC (JPG/PNG)"),
              const SizedBox(height: 12),

              const Text(
                "Your Location",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.my_location, color: Color(0xFF2563EB)),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text("Use your current location"),
                        ),
                        Switch(value: true, onChanged: (_) {}),
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Icon(
                          Icons.edit_location_alt,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text("Or enter address manually"),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text("Enter"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              PrimaryButton(
                text: "Save and Continue",
                onPressed: () => Navigator.pushNamed(context, '/category'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
