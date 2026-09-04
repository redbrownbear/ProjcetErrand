import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/config/naver_map_init.dart';
import 'core/theme/colors.dart';
import 'features/auth/screens/auth_gate.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initNaverMap();
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
      scrollBehavior: const _AppScrollBehavior(),
      // 폴더블·태블릿·웹처럼 폭이 넓은 화면에서 레이아웃이 가로로 늘어나
      // 버튼 사이가 벌어지는 것을 막는다. 폰 폭(<=560)에서는 아무 영향이 없고,
      // 그보다 넓으면 가운데 정렬된 폰 폭 화면으로 보여준다.
      // builder에 두면 푸시되는 상세·목록 화면까지 모두 적용된다.
      builder: (context, child) => ColoredBox(
        color: AppColors.page,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: child,
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// 웹·데스크톱에서 Flutter가 자동으로 붙이는 오른쪽 스크롤바를 숨긴다.
/// 모바일 앱에는 원래 없는 요소라, 있으면 웹에서만 앱처럼 안 보인다.
/// 휠·터치·드래그 스크롤은 그대로 동작한다.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;
}
