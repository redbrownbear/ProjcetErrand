/// 금지 품목 · 건당 물건값 상한 (개발 To-do A20).
///
/// **최종 판단은 서버다**(functions/src/safety/policy.ts — Firestore `config/safety`로 바꿀 수 있다).
/// 여기 값은 서버 기본값과 같게 두고, 올리기 전에 미리 알려 주는 데만 쓴다.
/// 서버 설정을 바꿨는데 여기가 옛 값이면 앱은 통과시키고 서버가 거부 · 숨김 처리한다.
class SafetyPolicy {
  SafetyPolicy._();

  /// '술' · '약'처럼 짧은 말은 '기술' · '예약'까지 걸려서 물건 이름으로 적는다(법률 검토 L-050~056 · L-061)
  static const blockedWords = [
    '소주', '맥주', '와인', '막걸리', '양주', '위스키', '보드카', '사케', '하이볼', '주류',
    '담배', '전자담배', '궐련', '액상', '니코틴',
    '의약품', '처방약', '처방전', '감기약', '해열제', '진통제', '수면제', '타이레놀', '마약', '대마',
    '복권', '로또', '현금전달', '현금배달', '카드전달',
  ];

  /// 국내 · 가는 김에 건당 물건값(원)
  static const maxItemPrice = 50000;

  /// 해외 사다주기 건당 물건값(원)
  static const maxItemPriceSea = 100000;

  static String _squash(String s) => s.replaceAll(RegExp(r'\s+'), '').toLowerCase();

  /// 글에 들어 있는 첫 금지어. 없으면 null
  static String? findBlocked(String text) {
    final t = _squash(text);
    if (t.isEmpty) return null;
    for (final w in blockedWords) {
      if (t.contains(_squash(w))) return w;
    }
    return null;
  }

  static String blockedMessage(String word) => "'$word'처럼 부탁할 수 없는 물건(주류 · 담배 · 의약품 · 복권 · 현금)이 들어 있어요";
}
