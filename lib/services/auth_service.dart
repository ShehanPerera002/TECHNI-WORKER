import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  int? _resendToken;

  AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  Future<void> _logFirebaseIdToken(User? user) async {
    if (user == null) {
      debugPrint('No authenticated user found for token logging');
      return;
    }

    final idToken = await user.getIdToken(true);
    debugPrint('FIREBASE_TOKEN: $idToken');
  }

  /// Send OTP to phone number
  Future<void> sendOTP(String phoneNumber) async {
    try {
      debugPrint('Sending OTP to: $phoneNumber');

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('Verification completed automatically');
          final userCredential = await _auth.signInWithCredential(credential);
          await _logFirebaseIdToken(userCredential.user);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Verification failed: ${e.message}');
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('OTP sent successfully');
          _verificationId = verificationId;
          _resendToken = resendToken;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Code auto retrieval timeout');
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      rethrow;
    }
  }

  /// Verify OTP code
  Future<UserCredential?> verifyOTP(String otp) async {
    try {
      if (_verificationId == null) {
        throw Exception('Verification ID is null. Please request OTP first.');
      }

      debugPrint('Verifying OTP: $otp');

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      debugPrint(
        'OTP verified successfully. User: ${userCredential.user?.phoneNumber}',
      );
      await _logFirebaseIdToken(userCredential.user);
      return userCredential;
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      rethrow;
    }
  }

  /// Resend OTP
  Future<void> resendOTP(String phoneNumber) async {
    try {
      debugPrint('Resending OTP to: $phoneNumber');

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('Verification completed automatically on resend');
          final userCredential = await _auth.signInWithCredential(credential);
          await _logFirebaseIdToken(userCredential.user);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Resend verification failed: ${e.message}');
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('OTP resent successfully');
          _verificationId = verificationId;
          _resendToken = resendToken;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      debugPrint('Error resending OTP: $e');
      rethrow;
    }
  }

  /// Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Get verification ID (for testing)
  String? getVerificationId() => _verificationId;
}
