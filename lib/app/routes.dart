import 'package:flutter/material.dart';

import '../screens/welcome_screen.dart';
import '../screens/worker_signin_screen.dart';
import '../screens/otp_verification_screen.dart';
import '../screens/verified_screen.dart';
import '../screens/create_profile_screen.dart';
import '../screens/select_category_screen.dart';
import '../screens/worker_home_screen.dart';


final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const WelcomeScreen(),
  '/signin': (context) => const WorkerSignInScreen(),
  '/otp': (context) => const OtpVerificationScreen(),
  '/verified': (context) => const VerifiedScreen(),
  '/profile': (context) => const CreateProfileScreen(),
  '/category': (context) => const SelectCategoryScreen(),
  '/home': (context) => const WorkerHomeScreen(),

};
