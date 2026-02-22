import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // මේක අලුතින් ඕනේ
import 'app/techni_worker_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCl4f-KS1P_N1a34qO06IXsR933PfMwi3I",
      appId: "1:183569548741:android:5db1ac142be71819d677ac",
      messagingSenderId: "183569548741",
      projectId: "project-techni",
      storageBucket: "project-techni.firebasestorage.app",
    ),
  );

  runApp(const TechniWorkerApp());
}