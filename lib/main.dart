import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BureumApp());
}

class BureumApp extends StatelessWidget {
  const BureumApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '겸사겸사',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: AppColors.page),
      home: const AuthGate(),
    );
  }
}
