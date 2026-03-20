import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

// Screens
import '../services/screens/welcome_screen.dart';
import '../services/screens/worker_signin_screen.dart';
import '../services/screens/otp_verification_screen.dart';
import '../services/screens/verified_screen.dart';
import '../services/screens/create_profile_screen.dart';
import '../services/screens/select_category_screen.dart';
import '../services/screens/worker_home_screen.dart';
import '../services/screens/terms_screen.dart';
import '../services/screens/privacy_screen.dart';
import '../services/screens/pending_verification_screen.dart'; 

final Map<String, WidgetBuilder> appRoutes = {
  // IMPORTANT: The '/' route is handled by AuthWrapper in main.dart
  
  '/signin': (context) => const WorkerSignInScreen(),
  '/otp': (context) => const OtpVerificationScreen(),
  '/verified': (context) => const VerifiedScreen(),
  '/profile': (context) => const CreateProfileScreen(),
  
  '/category': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (args != null && 
        args.containsKey('name') && 
        args.containsKey('nic')) {
      
      return SelectCategoryScreen(
        name: args['name'] as String,
        nic: args['nic'] as String,
        phone: args['phone'] as String,
        birthDate: args['birthDate'] as String,
        // UPDATED: Now casting specifically to List<String>
        languages: List<String>.from(args['languages'] as List), 
        profilePhoto: args['profilePhoto'] as PlatformFile,
        nicFront: args['nicFront'] as PlatformFile,
        nicBack: args['nicBack'] as PlatformFile,
        policeReport: args['policeReport'] as PlatformFile,
        latitude: args['latitude'] as double,
        longitude: args['longitude'] as double,
      );
    }
    
    return const CreateProfileScreen();
  },

  '/welcome': (context) => const WelcomeScreen(),
  '/terms': (context) => const TermsScreen(),
  '/privacy': (context) => const PrivacyScreen(),
  '/pending': (context) => const PendingVerificationScreen(),
  '/home': (context) => const WorkerHomeScreen(),
};