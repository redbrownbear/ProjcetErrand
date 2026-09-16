/// 지역별 지도 초기 중심 좌표와 줌.
///
/// 전체 지도 화면(`map_view.dart`)과 홈의 인라인 지도가 같은 위치에서 시작해야
/// "목록에서 지도로 바꿨는데 다른 동네가 보이는" 일이 생기지 않는다.
const regionCenters = <String, (double, double)>{
  '서울 서초구': (37.4837, 127.0324),
  '서울 강남구': (37.5172, 127.0473),
  '서울 성동구': (37.5634, 127.0367),
  '부산 수영구': (35.1455, 129.1132),
  '대전 유성구': (36.3623, 127.3560),
};

/// 등록되지 않은 지역·'전국'은 한반도 전체를 보여준다.
const koreaCenter = (36.5, 127.8);

(double, double) centerOf(String scope) => regionCenters[scope] ?? koreaCenter;

/// 동네 단위면 가깝게, 전국이면 멀리.
double zoomOf(String scope) => regionCenters.containsKey(scope) ? 13.5 : 7.0;
