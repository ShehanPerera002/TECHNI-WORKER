import 'package:flutter/material.dart';
import '../core/assets.dart';
import '../widgets/primary_button.dart';

class VerifiedScreen extends StatelessWidget {
  const VerifiedScreen({super.key});

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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                AppAssets.workerVerificationPage2,
                height: 200,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 24),
              const Icon(Icons.verified, size: 90, color: Color(0xFF2563EB)),
              const SizedBox(height: 12),
              const Text(
                "Successfully Verified",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: "Continue",
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
