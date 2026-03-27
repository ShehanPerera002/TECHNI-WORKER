import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import '../../widgets/primary_button.dart';

class PendingVerificationScreen extends StatefulWidget {
  const PendingVerificationScreen({super.key});

  @override
  State<PendingVerificationScreen> createState() => _PendingVerificationScreenState();
}

class _PendingVerificationScreenState extends State<PendingVerificationScreen> {
  bool _isRefreshing = false;
  bool _isSigningOut = false;

  Future<void> _handleSignOut() async {
    setState(() => _isSigningOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logout failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  Future<void> _refreshStatus() async {
    setState(() => _isRefreshing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('workers')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Checking latest status...")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          "TECHNI",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          _isSigningOut 
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent)
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  onPressed: _handleSignOut,
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text("Sign Out"),
                ),
              ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange.shade300, width: 1.5),
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.08),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.hourglass_empty_rounded, color: Colors.orange.shade800, size: 35),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Verification Pending",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.orange),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "We are reviewing your information.\nThis usually takes up to 24 hours.",
                      style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    
                    const Icon(
                      Icons.check_circle_outline_rounded, 
                      size: 100, 
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 30),
                    PrimaryButton(
                      text: _isRefreshing ? "Checking..." : "Refresh Status",
                      onPressed: _isRefreshing ? () {} : _refreshStatus,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Once verified, the home screen will load automatically.",
                      style: TextStyle(fontSize: 12, color: Colors.black38, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
