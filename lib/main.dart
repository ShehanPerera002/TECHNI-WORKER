import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'app/routes.dart';
import 'app/theme.dart';

// Screens
import 'services/screens/welcome_screen.dart';
import 'services/screens/worker_home_screen.dart';
import 'services/screens/pending_verification_screen.dart';
import 'services/screens/create_profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with platform options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TECHNI Worker',
      theme: appTheme,
      
      // Starting point of the app
      home: const AuthWrapper(), 
      routes: appRoutes,
    );
  }
}

// ================= Authentication & Profile Status Wrapper =================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen to Firebase Auth state (Logged in or Logged out)
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Show loading while checking authentication status
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 1. If User is NOT logged in, redirect to Welcome Screen
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const WelcomeScreen();
        }

        final String uid = authSnapshot.data!.uid;

        // 2. If Logged in, listen to the Worker's Profile document in real-time
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('workers')
              .doc(uid)
              .snapshots(),
          builder: (context, docSnapshot) {
            // Show loading while fetching Firestore data
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // Check if the Profile document exists in Firestore
            if (docSnapshot.hasData && docSnapshot.data != null && docSnapshot.data!.exists) {
              final data = docSnapshot.data!.data() as Map<String, dynamic>?;

              if (data != null) {
                // Get verification status (default to 'pending' if not found)
                String status = (data['verificationStatus'] ?? 'pending')
                    .toString()
                    .trim()
                    .toLowerCase();
                
                // Logic: If status is 'verified', show Home Screen. 
                // For any other status (pending/rejected), show Pending Screen.
                if (status == 'verified') {
                  return const WorkerHomeScreen();
                } else {
                  return const PendingVerificationScreen();
                }
              }
            }

            // 3. If User is logged in but the Firestore document is missing (Deleted),
            // show the Profile Creation Screen.
            return const CreateProfileScreen();
          },
        );
      },
    );
  }
}