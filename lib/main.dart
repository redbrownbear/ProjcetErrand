import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/backend/backend.dart';
import 'core/config/naver_map_init.dart';
import 'core/storage/local_store.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'features/auth/screens/auth_gate.dart';
import 'features/auth/services/auth_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 화면 가장자리까지 그린다. targetSdk 36에서는 안드로이드 15+가 어차피 이걸
  // 강제하는데, 명시해 두면 구버전 안드로이드에서도 같은 모양이 나온다.
  // 시스템 바에 가리는 건 각 화면의 SafeArea가 막는다 ([ScreenFrame] 참고).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Firebase가 없어도 앱은 떠야 한다. 플러그인이 덜 붙은 플랫폼(데스크톱)이나
  // 네트워크가 끊긴 상태에서 여기서 예외가 나면 runApp까지 못 가서 화면이 통째로
  // 하얗게 뜬다. 실패하면 Backend.ready가 false로 남고, 저장소 계층이 전부
  // 이 기기의 LocalStore로 갈아탄다. (core/backend/backend.dart 참고)
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    Backend.markReady();
    // 로그인 유지 설정 (웹에서만 의미가 있다 — AuthService.configurePersistence 참고)
    await AuthService().configurePersistence();
  } catch (e) {
    Backend.markFailed(e);
  }
  // 지도 SDK 초기화가 실패해도(플러그인 미등록·인증 오류 등) 앱은 떠야 한다.
  // 여기서 예외가 나면 runApp까지 가지 못해 스플래시에서 멈춘다.
  try {
    await initNaverMap();
  } catch (e) {
    debugPrint('네이버 지도 초기화 실패: $e');
  }
  await LocalStore.init();
  runApp(const GyeomsaApp());
}

class GyeomsaApp extends StatelessWidget {
  const GyeomsaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '겸사겸사',
      debugShowCheckedModeBanner: false,
      // 색·서체·모서리는 전부 core/theme에 모여 있다 (기획 시안 v9 기준).
      theme: buildAppTheme(),
      scrollBehavior: const _AppScrollBehavior(),
      // 폴더블·태블릿·웹처럼 폭이 넓은 화면에서 레이아웃이 가로로 늘어나
      // 버튼 사이가 벌어지는 것을 막는다. 폰 폭(<=560)에서는 아무 영향이 없고,
      // 그보다 넓으면 가운데 정렬된 폰 폭 화면으로 보여준다.
      // builder에 두면 푸시되는 상세·목록 화면까지 모두 적용된다.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        // 앱 바탕이 밝아서 시스템 바 아이콘은 어두워야 보인다. 지정하지 않으면
        // 기기 테마에 따라 흰 아이콘이 흰 배경 위에 얹혀 아무것도 안 보인다.
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // 안드로이드
          statusBarBrightness: Brightness.light, // iOS
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: ColoredBox(
          // 시안은 앱 본문을 흰 바탕으로 두고, 프레임 바깥만 회색으로 깐다.
          color: AppColors.page,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: child,
            ),
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

  // 기본값은 터치·스타일러스만 드래그 스크롤을 허용한다. 웹·데스크톱에서
  // 마우스로 클릭한 채 끌거나 트랙패드로 스와이프하면 안 움직이던 이유다.
  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
