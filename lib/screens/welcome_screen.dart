import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Icon(Icons.build_circle, size: 72, color: Color(0xFF2563EB)),
              const SizedBox(height: 12),
              const Text("TECHNI", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const Text(
                "Connect With Clients,\nGrow Your Business",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
              ),
              const SizedBox(height: 10),
              const Text(
                "The easiest way for skilled professionals to find local jobs and manage their work.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const Spacer(),
              PrimaryButton(
                text: "Get Started",
                onPressed: () => Navigator.pushNamed(context, '/signin'),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/signin'),
                    child: const Text(
                      "Login",
                      style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}
