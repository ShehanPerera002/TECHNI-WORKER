import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../core/assets.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../auth_service.dart';

class WorkerSignInScreen extends StatefulWidget {
  const WorkerSignInScreen({super.key});

  @override
  State<WorkerSignInScreen> createState() => _WorkerSignInScreenState();
}

class _WorkerSignInScreenState extends State<WorkerSignInScreen> {
  final phoneCtrl = TextEditingController();
  final AuthService _authService = AuthService();
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.pushNamed(context, '/terms');
      };
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.pushNamed(context, '/privacy');
      };
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    String phoneNumber = phoneCtrl.text.trim();

    if (phoneNumber.isEmpty) {
      setState(() => _error = 'Please enter your phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Format logic: අංකය 0න් පටන් ගත්තොත් ඒක අයින් කරලා +94 දානවා
      if (!phoneNumber.startsWith('+')) {
        if (phoneNumber.startsWith('0')) {
          phoneNumber = '+94${phoneNumber.substring(1)}';
        } else if (phoneNumber.length == 9) {
          phoneNumber = '+94$phoneNumber';
        }
      }

      await _authService.sendOTP(phoneNumber);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully!')),
        );
        Navigator.pushNamed(context, '/otp', arguments: phoneNumber);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error: ${e.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            }
          },
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 450,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.fromARGB(0, 17, 5, 186), Color(0xFFDCE8FF)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView( // Keyboard එකට ඉඩ දෙන්න
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    AppAssets.welcomeLogo,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Welcome!",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Enter your mobile number to get started. We'll send you a code to verify your account.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 35),
                  InputField(
                    label: "Mobile Number",
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: _isLoading ? "Sending..." : "Continue",
                    onPressed: _isLoading ? () {} : _sendOTP,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  
                  const SizedBox(height: 80), // පල්ලෙහාට ඉඩක් තැබීම

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, color: Colors.black45),
                      children: [
                        const TextSpan(text: "By clicking continue, you agree to our "),
                        TextSpan(
                          text: "Terms of Service",
                          style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                          recognizer: _termsRecognizer,
                        ),
                        const TextSpan(text: " and "),
                        TextSpan(
                          text: "Privacy Policy",
                          style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                          recognizer: _privacyRecognizer,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}