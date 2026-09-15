/// 일급·일당형 일감 (공연·행사 스태프, 단기알바, 프로젝트).
///
/// MOU·제휴 영업 전략 가이드 §6·§11을 그대로 옮겼다.
/// §11이 "화면에 전면 표시"하라고 못박은 7가지는 전부 필수 필드로 둔다.
/// (일급/일당 · 예상 시간 · 위치 · 지급일 · 업무 난이도 · 준비물 · 신원확인 수준)
class DayJob {
  final String id;
  final String icon;

  /// 구인 주체. 겸사겸사가 고용주가 아니라는 점을 화면에서 항상 같이 보여준다.
  final String org;
  final String title;
  final String desc;

  /// 하위 분류: 행사 | 공연 | 전시 | 단기 | 프로젝트
  final String cat;

  /// 지급액(원)과 그 단위 — 일급 | 일당 | 건당
  final int pay;
  final String payKind;

  /// 예상 근무 시간 (예: 6시간 · 09:00~15:00)
  final String hours;

  /// 근무 위치
  final String place;
  final String region;

  /// 지급일 (예: 당일 현장 지급, 익일, 익월 10일)
  final String payDate;

  /// 업무 난이도 — 쉬움 | 보통 | 힘듦
  final String level;

  /// 준비물 (예: 검정 상하의, 운동화)
  final String gear;

  /// 신원확인 수준 — 없음 | 본인인증 | 신분증 확인
  final String idCheck;

  /// 공고 출처 — 직접 제휴 | 공고 연동.
  /// §11의 "법적 역할을 명확히 설계" 요구에 따라 화면에 출처를 그대로 노출한다.
  final String source;

  /// 마감 안내
  final String closing;

  const DayJob({
    required this.id,
    required this.icon,
    required this.org,
    required this.title,
    required this.desc,
    required this.cat,
    required this.pay,
    required this.payKind,
    required this.hours,
    required this.place,
    required this.region,
    required this.payDate,
    required this.level,
    required this.gear,
    required this.idCheck,
    required this.source,
    required this.closing,
  });

  /// 카드 한 줄 요약 — 돈·시간·위치 순으로 사용자가 가장 먼저 보는 정보
  String get headline => '$payKind ${_comma(pay)}원';
  String get meta => '$hours · $region';

  static String _comma(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

const dayJobCats = [
  ['all', '전체'],
  ['행사', '행사'],
  ['공연', '공연'],
  ['전시', '전시·컨벤션'],
  ['단기', '단기알바'],
  ['프로젝트', '프로젝트'],
];
