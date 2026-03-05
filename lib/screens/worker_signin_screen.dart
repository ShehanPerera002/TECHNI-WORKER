import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../core/assets.dart';
import '../widgets/input_field.dart';
import '../widgets/primary_button.dart';
import '../services/auth_service.dart';

class WorkerSignInScreen extends StatefulWidget {
  const WorkerSignInScreen({super.key});

  @override
  State<WorkerSignInScreen> createState() => _WorkerSignInScreenState();
}

class _WorkerSignInScreenState extends State<WorkerSignInScreen> {
  final phoneCtrl = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (phoneCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter your phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Format phone number with country code if not present
      String phoneNumber = phoneCtrl.text.trim();
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+94${phoneNumber.replaceFirst('0', '')}'; // Sri Lanka code
      }

      await _authService.sendOTP(phoneNumber);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully!')),
        );
        // Navigate to OTP verification screen
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
          /// Bottom Blue Shade (like prototype)
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

          /// Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),

                  // LOGO
                  Image.asset(
                    AppAssets.welcomeLogo,
                    height: 200,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 8),

                  /// Welcome
                  const Text(
                    "Welcome!",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Enter your mobile number to get started. We'll send you a code to verify your account.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),

                  const SizedBox(height: 30),

                  /// Input
                  InputField(
                    label: "Mobile Number",
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 20),

                  /// Button
                  PrimaryButton(
                    text: _isLoading ? "Sending..." : "Continue",
                    onPressed: _isLoading ? () {} : _sendOTP,
                  ),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const Spacer(),

                  /// Terms with clickable blue parts
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                        children: [
                          const TextSpan(
                            text: "By clicking continue, you agree to our ",
                          ),
                          TextSpan(
                            text: "Terms of Service",
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // Navigate to Terms
                              },
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy Policy",
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // Navigate to Privacy
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
