import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_header.dart';
import '../widgets/primary_button.dart';
import '../services/auth_service.dart';

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
    
    for (int i = 0; i < otpCtrls.length; i++) {
      otpCtrls[i].addListener(() {
        if (otpCtrls[i].text.length == 1 && i < otpCtrls.length - 1) {
          FocusScope.of(context).requestFocus(otpFocusNodes[i + 1]);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in otpCtrls) c.dispose();
    for (final f in otpFocusNodes) f.dispose();
    super.dispose();
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
      // 1. Verify via Auth Service
      await _authService.verifyOTP(otp).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Verification timeout. Please try again.');
        },
      );

      final user = FirebaseAuth.instance.currentUser;

      if (user != null && mounted) {
        // 2. Firestore Check
        DocumentSnapshot workerDoc = await FirebaseFirestore.instance
            .collection('workers')
            .doc(user.uid)
            .get();

        if (workerDoc.exists) {
          String status = workerDoc.get('verificationStatus') ?? 'pending';
          if (status == 'verified') {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          } else {
            Navigator.pushNamedAndRemoveUntil(context, '/pending', (route) => false);
          }
        } else {
          // New User
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
      await _authService.resendOTP(_phoneNumber!);
      if (mounted) {
        setState(() => _isResending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Widget otpBox(int index) {
    return SizedBox(
      width: 45,
      height: 60,
      child: TextField(
        controller: otpCtrls[index],
        focusNode: otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(title: "Worker Verification"),
              const SizedBox(height: 20),
              const Text("Enter the 6-digit code sent to your phone."),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => otpBox(index)),
              ),
              const SizedBox(height: 30),
              if (_error != null)
                Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 10),
              PrimaryButton(
                text: _isLoading ? "Verifying..." : "Verify",
                onPressed: _isLoading ? () {} : _verifyOTP,
              ),
              Center(
                child: TextButton(
                  onPressed: _isResending ? null : _resendOTP,
                  child: Text(_isResending ? "Sending..." : "Resend Code"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}