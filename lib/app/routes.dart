import 'package:flutter/material.dart';

import '../services/screens/welcome_screen.dart';
import '../services/screens/worker_signin_screen.dart';
import '../services/screens/otp_verification_screen.dart';
import '../services/screens/verified_screen.dart';
import '../services/screens/create_profile_screen.dart';
import '../services/screens/select_category_screen.dart';
import '../services/screens/worker_home_screen.dart';
import '../services/screens/terms_screen.dart';
import '../services/screens/privacy_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const WelcomeScreen(),
  '/signin': (context) => const WorkerSignInScreen(),
  '/otp': (context) => const OtpVerificationScreen(),
  '/verified': (context) => const VerifiedScreen(),
  '/profile': (context) => const CreateProfileScreen(),
  '/category': (context) => const SelectCategoryScreen(),
  '/terms': (context) => const TermsScreen(),
  '/privacy': (context) => const PrivacyScreen(),
  '/home': (context) => const WorkerHomeScreen(),
};
