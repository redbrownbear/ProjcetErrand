import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'server_api.dart';

/// 로컬 에뮬레이터에 붙기 — 개발 프로젝트를 건드리지 않고 PC에서 서버까지 통째로 돌려 본다.
///
/// `flutter run --dart-define=EMULATOR_HOST=10.0.2.2` (안드로이드 에뮬레이터 → PC). 실제 폰이면 PC의 내부 IP.
/// 서버 쪽은 functions 폴더에서 `npm run dev`(에뮬레이터) → `npm run seed`(예시 데이터 · 테스트 계정). 자세한 건 functions/README.md.
/// 출시 빌드에서는 값을 줘도 무시한다.
const emulatorHost = String.fromEnvironment('EMULATOR_HOST');

bool get useEmulator => emulatorHost.isNotEmpty && !kReleaseMode;

/// Firebase 초기화 직후, 다른 Firebase 호출보다 먼저 부른다
Future<void> connectEmulators() async {
  if (!useEmulator) return;
  final host = emulatorHost;
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instanceFor(region: ServerApi.region).useFunctionsEmulator(host, 5001);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  debugPrint('Firebase 에뮬레이터에 붙음: $host');
}
