import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../config/api_keys.dart';
import 'api_client.dart';

/// 쿠팡 파트너스 상품 한 개. 링크를 타고 들어가 사면 수수료가 들어온다.
class DealItem {
  final String id, name, image, url, category;
  final int price, discountRate;
  final bool rocket;

  const DealItem({
    required this.id,
    required this.name,
    required this.image,
    required this.url,
    required this.category,
    required this.price,
    this.discountRate = 0,
    this.rocket = false,
  });
}

/// 쿠팡 파트너스 Open API.
///
/// 제휴 계약(MOU)이 아니라 파트너스 가입 심사만 통과하면 열리는 공개 API다.
/// '오늘의 골드박스 특가 확인' 미션의 내용이 여기서 나오고, 사용자가 산 만큼
/// 수수료가 생겨 포인트 지급 재원이 된다.
///
/// ## secret은 앱에 넣지 않는다
/// HMAC 서명에 쓰는 secret key는 서버용이다. APK에서 문자열을 뽑으면 그대로
/// 보이고, 새면 남이 우리 파트너스 계정으로 API를 쓴다. 그래서 운영 빌드는
/// [ApiKeys.proxyBase]를 채워 서명을 서버에서 하게 하고, 아래 직접 서명 경로는
/// 연동을 확인하는 개발 빌드에서만 쓴다.
class CoupangPartnersApi {
  static const _host = 'api-gateway.coupang.com';
  static const _goldbox = '/v2/providers/affiliate_open_api/apis/openapi/v1/products/goldbox';

  final ApiClient _api;
  const CoupangPartnersApi([this._api = const ApiClient()]);

  bool get ready => ApiKeys.hasProxy || ApiKeys.filled([ApiKeys.coupangAccess, ApiKeys.coupangSecret]);

  /// 서버 프록시를 거치는 중인지. 화면에 '개발 모드' 경고를 띄울 때 쓴다.
  bool get viaProxy => ApiKeys.hasProxy;

  /// 오늘의 골드박스. 하루 한 번 갱신되는 특가 목록이다.
  Future<List<DealItem>> goldbox({int limit = 5}) async {
    if (!ready) throw const ApiFailure(ApiFailKind.noKey, 'COUPANG_ACCESS_KEY/SECRET 없음');

    final body = viaProxy
        ? await _api.getJson(Uri.parse('${ApiKeys.proxyBase}/coupang/goldbox').replace(queryParameters: {'limit': '$limit'}))
        : await _api.getJson(Uri.https(_host, _goldbox), headers: {'Authorization': authHeader('GET', _goldbox)});

    if (body is Map && body['rCode'] != null && '${body['rCode']}' != '0') {
      throw ApiFailure(ApiFailKind.badResponse, '${body['rMessage']}');
    }
    final data = body is Map ? body['data'] : null;
    if (data is! List) throw const ApiFailure(ApiFailKind.badResponse, 'data 없음');

    return [
      for (final d in data.whereType<Map>().take(limit))
        DealItem(
          id: '${d['productId']}',
          name: '${d['productName']}',
          image: '${d['productImage'] ?? ''}',
          url: '${d['productUrl'] ?? ''}',
          category: '${d['categoryName'] ?? ''}',
          price: int.tryParse('${d['productPrice']}') ?? 0,
          discountRate: int.tryParse('${d['discountRate'] ?? 0}') ?? 0,
          rocket: d['isRocket'] == true,
        ),
    ];
  }

  /// 파트너스 인증 헤더.
  ///
  /// 서명 대상은 `signed-date + METHOD + path + query`를 이어 붙인 문자열이고,
  /// query에는 `?`를 넣지 않는다. 시각은 반드시 GMT `yyMMdd'T'HHmmss'Z'` 형식이라
  /// 기기 시간대가 한국이어도 UTC로 바꿔서 만든다.
  static String authHeader(String method, String path, {String query = '', DateTime? now}) {
    final signedDate = _signedDate(now ?? DateTime.now());
    final message = '$signedDate$method$path$query';
    final signature = Hmac(sha256, utf8.encode(ApiKeys.coupangSecret)).convert(utf8.encode(message));
    return 'CEA algorithm=HmacSHA256, access-key=${ApiKeys.coupangAccess}, '
        'signed-date=$signedDate, signature=$signature';
  }

  static String _signedDate(DateTime now) {
    final t = now.toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.year % 100)}${two(t.month)}${two(t.day)}T${two(t.hour)}${two(t.minute)}${two(t.second)}Z';
  }
}
