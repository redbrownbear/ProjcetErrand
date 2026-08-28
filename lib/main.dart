import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'theme/colors.dart';

void main() => runApp(const BureumApp());

class BureumApp extends StatelessWidget {
  const BureumApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '부릉부름',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: AppColors.page),
      home: const HomeShell(),
    );
  }
}
