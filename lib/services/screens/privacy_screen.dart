import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(
          'Privacy Policy\n\n'
          '1. TECHNI collects phone numbers for authentication.\n'
          '2. Personal data is securely stored.\n'
          '3. Location data is used to match customers with nearby workers.\n'
          '4. Your data will never be sold to third parties.\n'
          '5. Users can request deletion of their account anytime.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
