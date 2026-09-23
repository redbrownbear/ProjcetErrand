import '../config/api_keys.dart';
import 'api_client.dart';

/// 지도 API가 돌려준 근처 장소 한 곳.
class NearbyPlace {
  final String id, name, category, address;
  final double lat, lon;

  /// 요청 좌표로부터의 거리(m). 네이버 검색은 거리를 주지 않아 -1이 들어온다.
  final int distance;

  const NearbyPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.lat,
    required this.lon,
    this.distance = -1,
  });

  String get distanceLabel => distance < 0 ? '' : (distance < 1000 ? '${distance}m' : '${(distance / 100).round() / 10}km');
}

/// 카카오 디벨로퍼스 — 로컬(장소) API.
///
/// REST 키가 가입 즉시 무료로 나오고 제휴 계약이 필요 없다. 지금 서 있는 자리에서
/// 반경 안 매장을 실제로 찾아주므로, '아무 데서나 눌러 받는' 체크인 미션이 아니라
/// **정말 그 앞에 있어야 되는** 체크인 미션을 만들 수 있다.
class KakaoLocalApi {
  static const _host = 'dapi.kakao.com';
  static const _path = '/v2/local/search/category.json';

  /// 카카오 장소 카테고리 그룹 코드 중 심부름과 맞닿는 것들
  static const cafe = 'CE7';
  static const convenience = 'CS2';
  static const mart = 'MT1';
  static const pharmacy = 'PM9';
  static const bank = 'BK9';

  final ApiClient _api;
  const KakaoLocalApi([this._api = const ApiClient()]);

  bool get ready => ApiKeys.kakaoRest.isNotEmpty || ApiKeys.hasProxy;

  /// [radius]는 m 단위, 최대 20000. 가까운 순으로 돌려준다.
  Future<List<NearbyPlace>> nearby({
    required double lat,
    required double lon,
    String category = convenience,
    int radius = 500,
    int size = 10,
  }) async {
    if (!ready) throw const ApiFailure(ApiFailKind.noKey, 'KAKAO_REST_KEY 없음');
    final query = {
      'category_group_code': category,
      'x': '$lon',
      'y': '$lat',
      'radius': '$radius',
      'size': '$size',
      'sort': 'distance',
    };

    final body = ApiKeys.hasProxy
        ? await _api.getJson(Uri.parse('${ApiKeys.proxyBase}/kakao/local').replace(queryParameters: query))
        : await _api.getJson(Uri.https(_host, _path, query), headers: {'Authorization': 'KakaoAK ${ApiKeys.kakaoRest}'});

    final docs = body is Map ? body['documents'] : null;
    if (docs is! List) throw const ApiFailure(ApiFailKind.badResponse, 'documents 없음');
    return [
      for (final d in docs.whereType<Map>())
        NearbyPlace(
          id: '${d['id']}',
          name: '${d['place_name']}',
          category: '${d['category_group_name'] ?? ''}',
          address: '${d['road_address_name'] ?? d['address_name'] ?? ''}',
          lat: double.tryParse('${d['y']}') ?? 0,
          lon: double.tryParse('${d['x']}') ?? 0,
          distance: int.tryParse('${d['distance']}') ?? -1,
        ),
    ];
  }
}

/// 네이버 개발자센터 — 검색 API(지역).
///
/// 후기 미션에 쓴다. 카카오가 '내 반경 안에 뭐가 있나'를 답한다면, 네이버는
/// '이 이름의 가게가 실재하나'를 답한다. 체험단 미션의 대상 가게를 만들 때 쓴다.
///
/// 주의: client secret은 서버용 값이다. 운영 빌드에서는 [ApiKeys.proxyBase]를
/// 채워 우리 서버를 거치게 하고, dart-define 직접 호출은 개발용으로만 쓴다.
class NaverLocalApi {
  static const _host = 'openapi.naver.com';
  static const _path = '/v1/search/local.json';

  final ApiClient _api;
  const NaverLocalApi([this._api = const ApiClient()]);

  bool get ready => ApiKeys.hasProxy || ApiKeys.filled([ApiKeys.naverSearchId, ApiKeys.naverSearchSecret]);

  Future<List<NearbyPlace>> search(String keyword, {int display = 5}) async {
    if (!ready) throw const ApiFailure(ApiFailKind.noKey, 'NAVER_SEARCH_ID/SECRET 없음');
    final query = {'query': keyword, 'display': '$display', 'sort': 'random'};

    final body = ApiKeys.hasProxy
        ? await _api.getJson(Uri.parse('${ApiKeys.proxyBase}/naver/local').replace(queryParameters: query))
        : await _api.getJson(Uri.https(_host, _path, query), headers: {
            'X-Naver-Client-Id': ApiKeys.naverSearchId,
            'X-Naver-Client-Secret': ApiKeys.naverSearchSecret,
          });

    final items = body is Map ? body['items'] : null;
    if (items is! List) throw const ApiFailure(ApiFailKind.badResponse, 'items 없음');
    return [
      for (final it in items.whereType<Map>())
        NearbyPlace(
          id: '${it['link'] ?? it['title']}',
          name: plain('${it['title']}'),
          category: '${it['category'] ?? ''}',
          address: '${it['roadAddress'] ?? it['address'] ?? ''}',
          // mapx·mapy는 WGS84 경위도에 10^7을 곱한 정수다.
          lat: (double.tryParse('${it['mapy']}') ?? 0) / 1e7,
          lon: (double.tryParse('${it['mapx']}') ?? 0) / 1e7,
        ),
    ];
  }

  /// 검색어와 겹치는 글자를 `<b>`로 감싸서 내려준다. 그대로 쓰면 태그가 보인다.
  static String plain(String v) => v.replaceAll(RegExp(r'</?b>'), '').trim();
}
