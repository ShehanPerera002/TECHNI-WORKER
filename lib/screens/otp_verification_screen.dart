import 'package:flutter/material.dart';
import '../core/assets.dart';
import '../widgets/app_header.dart';
import '../widgets/primary_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> otpCtrls = List.generate(
    4,
    (_) => TextEditingController(),
  );

  @override
  void dispose() {
    for (final c in otpCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Widget otpBox(TextEditingController c) {
    return SizedBox(
      width: 56,
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: "",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        ),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),

              // 🔵 APP LOGO ADDED ONLY
              Center(
                child: Image.asset(
                  AppAssets.welcomeLogo,
                  height: 130,
                  alignment: Alignment.topLeft,
                ),
              ),

              const SizedBox(height: 10),

              const AppHeader(title: "Worker Verification"),
              const SizedBox(height: 12),

              Center(
                child: Image.asset(
                  AppAssets.workerVerificationPage1,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "A four digit code has been sent to your phone number. Please enter the code below to verify your account.",
                style: TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: otpCtrls.map(otpBox).toList(),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive the code? ",
                    style: TextStyle(color: Colors.black54),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Resend Code",
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              PrimaryButton(
                text: "Verify",
                onPressed: () => Navigator.pushNamed(context, '/verified'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
