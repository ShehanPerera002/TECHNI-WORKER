import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/primary_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> otpCtrls = List.generate(4, (_) => TextEditingController());

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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(title: "Worker Verification"),
              const Text("Enter the verification code sent to your phone.", style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: otpCtrls.map(otpBox).toList(),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text("Resend Code"),
                ),
              ),
              const SizedBox(height: 10),
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
