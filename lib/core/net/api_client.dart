import 'dart:convert';

import 'package:http/http.dart' as http;

/// 외부 API 호출이 실패한 이유. 화면에서는 이유를 구분해서 안내한다.
/// (키가 없는 것과 네트워크가 끊긴 것은 사용자에게 다른 말을 해야 한다)
enum ApiFailKind { noKey, network, badResponse, quota }

class ApiFailure implements Exception {
  final ApiFailKind kind;
  final String message;
  const ApiFailure(this.kind, this.message);

  @override
  String toString() => 'ApiFailure($kind): $message';

  String get userMessage => switch (kind) {
        ApiFailKind.noKey => '아직 연동 준비 중인 미션이에요',
        ApiFailKind.network => '네트워크가 불안정해요. 잠시 후 다시 시도해 주세요',
        ApiFailKind.quota => '오늘 조회 한도를 넘었어요. 내일 다시 시도해 주세요',
        ApiFailKind.badResponse => '제휴사 응답을 읽지 못했어요',
      };
}

/// 제휴 API 공통 호출부.
///
/// 미션 하나가 API 하나를 부르는 구조라, 응답이 늦으면 사용자는 버튼을 누른 채로
/// 기다린다. 그래서 타임아웃을 짧게(8초) 두고 실패를 [ApiFailure]로 통일한다.
class ApiClient {
  static const timeout = Duration(seconds: 8);

  /// 미션마다 연결을 새로 열지 않도록 한 개만 둔다. 테스트에서 교체할 수 있게
  /// final이 아니라 쓰기 가능한 static으로 뒀다.
  static http.Client client = http.Client();

  const ApiClient();

  Future<dynamic> getJson(Uri url, {Map<String, String> headers = const {}}) async {
    final http.Response res;
    try {
      res = await client.get(url, headers: {'Accept': 'application/json', ...headers}).timeout(timeout);
    } catch (e) {
      throw ApiFailure(ApiFailKind.network, '$e');
    }
    if (res.statusCode == 429) {
      throw const ApiFailure(ApiFailKind.quota, 'rate limited');
    }
    if (res.statusCode >= 400) {
      throw ApiFailure(ApiFailKind.badResponse, 'HTTP ${res.statusCode}: ${_head(res.body)}');
    }
    try {
      // 공공데이터포털은 Content-Type이 xml이어도 본문은 json인 경우가 있어
      // 헤더를 믿지 않고 본문을 직접 파싱한다.
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      throw ApiFailure(ApiFailKind.badResponse, _head(res.body));
    }
  }

  static String _head(String body) => body.length > 160 ? '${body.substring(0, 160)}…' : body;
}
