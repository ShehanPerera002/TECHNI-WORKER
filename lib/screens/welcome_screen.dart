import 'package:flutter/material.dart';
import '../core/assets.dart';
import '../widgets/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 30),

                // LOGO
                Image.asset(
                  AppAssets.welcomeLogo,
                  height: 200,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 8),

                // MAIN TAGLINE
                const Text(
                  "Connect With Clients,  Grow Your Business",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 15),

                // DESCRIPTION
                const Text(
                  "The easiest way for skilled professionals to find local jobs and manage their work.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 50), // Fixed spacing instead of Spacer
                // MAIN ILLUSTRATION
                Image.asset(
                  AppAssets.welcomePage,
                  height: MediaQuery.of(context).size.height * 0.3,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 30),

                // BUTTON
                PrimaryButton(
                  text: "Get Started",
                  onPressed: () => Navigator.pushNamed(context, '/signin'),
                ),

                const SizedBox(height: 20),

                // LOGIN ROW
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.black87),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/signin'),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
