import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'app/routes.dart';
import 'app/theme.dart';

// Screens imports
import 'screens/welcome_screen.dart';
import 'screens/worker_home_screen.dart';
import 'screens/pending_verification_screen.dart';
import 'screens/create_profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
      // home is the AuthWrapper which decides where the user lands
      home: const AuthWrapper(), 
      routes: appRoutes,
    );
  }
}

// ================= AUTH WRAPPER LOGIC =================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen to Auth State changes (Login/Logout)
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Show loading while checking auth status
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 1. If NO user is logged in (or they just signed out), go to Welcome
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          debugPrint("⚡ Auth: Signed Out. Redirecting to Welcome Screen.");
          return const WelcomeScreen();
        }

        final String uid = authSnapshot.data!.uid;
        debugPrint("⚡ Auth: User Logged In ($uid)");

        // 2. If logged in, listen to their Firestore Profile document
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('workers')
              .doc(uid)
              .snapshots(),
          builder: (context, docSnapshot) {
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // Check if profile exists
            if (docSnapshot.hasData && docSnapshot.data != null && docSnapshot.data!.exists) {
              final data = docSnapshot.data!.data() as Map<String, dynamic>?;

              if (data != null) {
                // Get and clean the status string
                String status = (data['verificationStatus'] ?? 'pending')
                    .toString()
                    .trim()
                    .toLowerCase();
                
                debugPrint("🔍 Status for $uid: '$status'");

                if (status == 'verified') {
                  return const WorkerHomeScreen();
                } else {
                  // This is where they go if pending
                  return const PendingVerificationScreen();
                }
              }
            }

            // 3. If Logged in but document hasn't been created yet
            debugPrint("📝 Status: No Profile. Redirecting to Create Profile.");
            return const CreateProfileScreen();
          },
        );
      },
    );
  }
}