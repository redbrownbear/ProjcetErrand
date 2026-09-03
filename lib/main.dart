import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'core/config/naver_map_config.dart';
import 'core/theme/colors.dart';
import 'features/auth/screens/auth_gate.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (naverMapSupported) {
    await FlutterNaverMap().init(
      clientId: naverMapClientId,
      onAuthFailed: (ex) => debugPrint('네이버 지도 인증 실패: $ex'),
    );
  }
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
