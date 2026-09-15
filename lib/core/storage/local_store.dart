import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 이 기기 안에만 남는 체험용 보관소. (관심 저장·지원 내역·가격 제안·새 부탁·작성 중 임시 내용)
///
/// 다른 기기와 동기화되지 않고 앱 데이터를 지우면 사라진다. 실제 서비스에서는
/// 인증된 서버가 거래 단계·매칭 권한·정산을 관리해야 한다.
///
/// [init]을 부르기 전(위젯 테스트 등)에는 메모리에만 보관한다.
class LocalStore {
  static const _prefix = 'gyumsa:v3:';
  static SharedPreferences? _prefs;
  static final Map<String, String> _memory = {};

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null; // 저장소를 못 열면 이번 실행 동안 메모리로만 동작
    }
  }

  /// 저장된 JSON을 읽는다. 없거나 깨졌거나 [fallback]과 타입이 다르면 [fallback].
  static T read<T>(String name, T fallback) {
    final raw = _prefs?.getString(_prefix + name) ?? _memory[name];
    if (raw == null) return fallback;
    try {
      final value = jsonDecode(raw);
      return value is T ? value : fallback;
    } catch (_) {
      return fallback;
    }
  }

  static void write(String name, Object? value) {
    final raw = jsonEncode(value);
    _memory[name] = raw;
    _prefs?.setString(_prefix + name, raw);
  }

  static void remove(String name) {
    _memory.remove(name);
    _prefs?.remove(_prefix + name);
  }
}
