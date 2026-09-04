import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'naver_map_config.dart';

/// 네이티브용 네이버 지도 초기화.
/// 데스크톱(Windows·macOS·Linux)도 dart.library.io에 포함되지만 SDK 지원 대상이
/// 아니므로 naverMapSupported로 한 번 더 거른다.
Future<void> initNaverMap() async {
  if (!naverMapSupported) return;
  await FlutterNaverMap().init(
    clientId: naverMapClientId,
    onAuthFailed: (ex) => debugPrint('네이버 지도 인증 실패: $ex'),
  );
}
