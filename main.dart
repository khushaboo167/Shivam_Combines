import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/firebase_service.dart';
import 'screens/entry_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!FirebaseService.demoMode) {
    await Firebase.initializeApp();
  }
  runApp(const ShivamApp());
}

class ShivamApp extends StatelessWidget {
  const ShivamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shivam Combines',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const EntryScreen(),
    );
  }
}
