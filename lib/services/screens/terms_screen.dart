import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(
          'Terms and Conditions\n\n'
          '1. Users must provide accurate information.\n'
          '2. TECHNI connects customers with service providers.\n'
          '3. Payments and services are handled between customer and worker.\n'
          '4. TECHNI is not responsible for damages caused by workers.\n'
          '5. Users must follow platform guidelines.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
