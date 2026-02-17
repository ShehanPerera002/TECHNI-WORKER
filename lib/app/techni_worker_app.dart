import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

class TechniWorkerApp extends StatelessWidget {
  const TechniWorkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TECHNI Worker',
      theme: appTheme,
      initialRoute: '/',
      routes: appRoutes,
    );
  }
}
