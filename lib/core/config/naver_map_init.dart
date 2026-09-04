// 네이버 지도 SDK 초기화. 플랫폼에 따라 구현이 갈린다.
//
// flutter_naver_map은 Android/iOS 네이티브 SDK만 지원하므로,
// 웹 빌드에서는 해당 패키지를 import조차 하지 않도록 조건부 import로 분리한다.
export 'naver_map_init_stub.dart' if (dart.library.io) 'naver_map_init_native.dart';
