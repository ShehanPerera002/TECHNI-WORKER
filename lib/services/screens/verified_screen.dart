import 'package:flutter/material.dart';
import '../../core/assets.dart';
import '../../widgets/primary_button.dart';

class VerifiedScreen extends StatelessWidget {
  const VerifiedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 🔵 Back arrow
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/otp',
                (route) => false,
              );
            }
          },
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // 🔵 APP LOGO (Top Left)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(AppAssets.welcomeLogo, height: 140),
              ),
            ),

            const SizedBox(height: 25),

            // 🔵 CENTER CARD
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 30,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF2563EB),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ❌ Close icon
                        Align(
                          alignment: Alignment.topRight,
                          child: Icon(Icons.close, size: 22),
                        ),

                        const SizedBox(height: 10),

                        // 🔵 Blue check circle
                        Container(
                          height: 85,
                          width: 85,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF2563EB),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 45,
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          "Successfully Verified!",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 22),

                        Image.asset(
                          AppAssets.workerVerificationPage2,
                          height: 200,
                          fit: BoxFit.contain,
                        ),

                        const SizedBox(height: 24),

                        PrimaryButton(
                          text: "Continue",
                          onPressed: () =>
                              Navigator.pushNamed(context, '/profile'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
