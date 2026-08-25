import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'theme/colors.dart';

void main() => runApp(const PumApp());

class PumApp extends StatelessWidget {
  const PumApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '품',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: AppColors.page),
      home: const HomeShell(),
    );
  }
}
