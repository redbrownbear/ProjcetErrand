import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:gyeomsa/core/net/api_client.dart';
import 'package:gyeomsa/core/net/coupang_partners_api.dart';
import 'package:gyeomsa/core/net/place_api.dart';

/// 정해진 응답만 돌려주는 가짜 서버. 실제 제휴사에 요청을 보내지 않고
/// '응답을 우리가 제대로 읽는가'만 확인한다.
class _FakeClient extends http.BaseClient {
  final String body;
  final int status;
  Uri? lastUrl;
  Map<String, String> lastHeaders = const {};

  _FakeClient(this.body, {this.status = 200});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUrl = request.url;
    lastHeaders = request.headers;
    return http.StreamedResponse(Stream.value(utf8.encode(body)), status);
  }
}

void main() {
  tearDown(() => ApiClient.client = http.Client());

  group('키 없이는 요청을 보내지 않는다', () {
    test('쿠팡은 키가 없으면 네트워크를 건드리지 않는다', () async {
      const api = CoupangPartnersApi();
      if (api.ready) return; // 키가 들어온 빌드에서는 이 테스트의 대상이 아니다

      final fake = _FakeClient('{}');
      ApiClient.client = fake;
      await expectLater(
        api.goldbox(),
        throwsA(isA<ApiFailure>().having((e) => e.kind, 'kind', ApiFailKind.noKey)),
      );
      expect(fake.lastUrl, isNull, reason: '키도 없이 요청을 보냈다');
    });

    test('카카오 로컬도 키가 없으면 나가지 않는다', () async {
      const api = KakaoLocalApi();
      if (api.ready) return;

      final fake = _FakeClient('{}');
      ApiClient.client = fake;
      await expectLater(
        api.nearby(lat: 37.4837, lon: 127.0324),
        throwsA(isA<ApiFailure>().having((e) => e.kind, 'kind', ApiFailKind.noKey)),
      );
      expect(fake.lastUrl, isNull, reason: '키도 없이 요청을 보냈다');
    });
  });

  group('실패 처리', () {
    test('HTTP 429는 할당량 초과로 구분한다', () async {
      ApiClient.client = _FakeClient('{}', status: 429);
      await expectLater(
        const ApiClient().getJson(Uri.https('example.com', '/')),
        throwsA(isA<ApiFailure>().having((e) => e.kind, 'kind', ApiFailKind.quota)),
      );
    });

    test('JSON이 아니면 badResponse로 바꾼다', () async {
      ApiClient.client = _FakeClient('<xml>에러</xml>');
      await expectLater(
        const ApiClient().getJson(Uri.https('example.com', '/')),
        throwsA(isA<ApiFailure>().having((e) => e.kind, 'kind', ApiFailKind.badResponse)),
      );
    });
  });

  group('네이버 지역검색', () {
    test('제목에 붙어 오는 <b> 태그를 지운다', () {
      expect(NaverLocalApi.plain('성수 <b>카페</b>'), '성수 카페');
      expect(NaverLocalApi.plain(' <b>GS25</b> 서초점 '), 'GS25 서초점');
    });
  });

  group('쿠팡 파트너스 서명', () {
    test('signed-date는 GMT yyMMddTHHmmssZ 형식이다', () {
      final header = CoupangPartnersApi.authHeader(
        'GET', '/v2/providers/affiliate_open_api/apis/openapi/v1/products/goldbox',
        now: DateTime.utc(2026, 9, 18, 5, 7, 9),
      );
      expect(header, startsWith('CEA algorithm=HmacSHA256,'));
      expect(header, contains('signed-date=260918T050709Z'));
      expect(header, contains('signature='));
    });

    test('경로나 시각이 다르면 서명도 달라진다', () {
      final at = DateTime.utc(2026, 9, 18, 5, 7, 9);
      final a = CoupangPartnersApi.authHeader('GET', '/a', now: at);
      final b = CoupangPartnersApi.authHeader('GET', '/b', now: at);
      final c = CoupangPartnersApi.authHeader('GET', '/a', now: at.add(const Duration(seconds: 1)));
      expect(a, isNot(b));
      expect(a, isNot(c));
    });
  });
}
