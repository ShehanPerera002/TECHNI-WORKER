import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool isLoading = false;

  @override
  void dispose() {
    phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    String input = phoneCtrl.text.trim();

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your mobile number")),
      );
      return;
    }

    // Remove all non-digit characters (spaces, dashes, etc.)
    String cleaned = input.replaceAll(RegExp(r'\D'), '');

    // Format to E.164 standard (+94XXXXXXXXX)
    String phoneNumber = "";
    if (cleaned.startsWith('94')) {
      phoneNumber = "+$cleaned";
    } else if (cleaned.startsWith('0')) {
      phoneNumber = "+94${cleaned.substring(1)}";
    } else {
      phoneNumber = "+94$cleaned";
    }

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-sign in if possible
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/verified', (route) => false);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Verification Failed: ${e.message}")),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => isLoading = false);
          // Navigate to OTP screen with verificationId
          Navigator.pushNamed(context, '/otp', arguments: verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Auth Error: $e");
    }
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
              const Text(
                "Enter your mobile number to get started.",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 18),
              InputField(
                label: "Mobile Number",
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                text: "Continue",
                onPressed: _sendOtp,
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
