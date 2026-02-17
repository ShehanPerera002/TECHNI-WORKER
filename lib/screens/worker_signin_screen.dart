import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/input_field.dart';
import '../widgets/primary_button.dart';

class WorkerSignInScreen extends StatefulWidget {
  const WorkerSignInScreen({super.key});

  @override
  State<WorkerSignInScreen> createState() => _WorkerSignInScreenState();
}

class _WorkerSignInScreenState extends State<WorkerSignInScreen> {
  final phoneCtrl = TextEditingController();

  @override
  void dispose() {
    phoneCtrl.dispose();
    super.dispose();
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
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(title: "Worker Sign In"),
              const Text("Enter your mobile number to get started.", style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 18),
              InputField(
                label: "Mobile Number",
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: "Continue",
                onPressed: () => Navigator.pushNamed(context, '/otp'),
              ),
              const SizedBox(height: 10),
              const Text(
                "By clicking continue, you agree to our Terms of Service and Privacy Policy",
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
