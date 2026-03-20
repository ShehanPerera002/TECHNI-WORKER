import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


import '../auth_service.dart';            // lib/services/auth_service.dart
import '../../widgets/app_header.dart';     // lib/widgets/app_header.dart
import '../../widgets/primary_button.dart'; // lib/widgets/primary_button.dart

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> otpCtrls = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> otpFocusNodes = List.generate(6, (_) => FocusNode());

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isResending = false;
  String? _error;
  String? _phoneNumber;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && mounted) {
        setState(() => _phoneNumber = args as String);
      }
    });
  }

  @override
  void dispose() {
    // curly_braces_in_flow_control_structures fix
    for (final c in otpCtrls) {
      c.dispose();
    }
    for (final f in otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _handleOtpChanged(int index, String value) {
    if (value.isNotEmpty) {
      final digit = value.substring(value.length - 1);
      if (otpCtrls[index].text != digit) {
        otpCtrls[index].text = digit;
      }
      otpCtrls[index].selection = TextSelection.fromPosition(
        const TextPosition(offset: 1),
      );

      if (index < otpCtrls.length - 1) {
        FocusScope.of(context).requestFocus(otpFocusNodes[index + 1]);
      } else {
        otpFocusNodes[index].unfocus();
      }
      return;
    }

    if (index > 0) {
      FocusScope.of(context).requestFocus(otpFocusNodes[index - 1]);
    }
  }

  Future<void> _verifyOTP() async {
    final otp = otpCtrls.map((c) => c.text).join();

    if (otp.length != 6) {
      setState(() => _error = 'Please enter 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authService.verifyOTP(otp).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Verification timeout. Please try again.');
        },
      );

      final user = FirebaseAuth.instance.currentUser;

      // use_build_context_synchronously fix - check mounted
      if (!mounted) return;

      if (user != null) {
        DocumentSnapshot workerDoc = await FirebaseFirestore.instance
            .collection('workers')
            .doc(user.uid)
            .get();

        if (!mounted) return;

        if (workerDoc.exists) {
          String status = workerDoc.get('verificationStatus') ?? 'pending';
          if (status == 'verified') {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          } else {
            Navigator.pushNamedAndRemoveUntil(context, '/pending', (route) => false);
          }
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/verified', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Invalid code. Please try again.';
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (_phoneNumber == null) return;
    setState(() {
      _isResending = true;
      _error = null;
    });

    try {
      await _authService.resendOTP(_phoneNumber!).timeout(const Duration(seconds: 30));
      if (mounted) {
        setState(() => _isResending = false);
        for (final c in otpCtrls) {
          c.clear();
        }
        FocusScope.of(context).requestFocus(otpFocusNodes.first);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
          _error = 'Failed to resend OTP';
        });
      }
    }
  }

  Widget otpBox(int index) {
    return SizedBox(
      width: 45,
      height: 65,
      child: TextField(
        controller: otpCtrls[index],
        focusNode: otpFocusNodes[index],
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        maxLength: 1,
        onChanged: (value) => _handleOtpChanged(index, value),
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(title: 'Worker Verification'),
              const SizedBox(height: 15),
              Center(
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded, size: 80, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'A six digit code has been sent to your phone. Enter it below to verify.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 35),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => otpBox(index)),
              ),
              const SizedBox(height: 30),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                ),
              PrimaryButton(
                text: _isLoading ? 'Verifying...' : 'Verify',
                onPressed: _isLoading ? () {} : _verifyOTP,
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive the code? ", style: TextStyle(color: Colors.black54)),
                  TextButton(
                    onPressed: _isResending ? null : _resendOTP,
                    child: Text(_isResending ? 'Resending...' : 'Resend Code',
                        style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}