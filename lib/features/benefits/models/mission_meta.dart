import 'partner_mission.dart';

/// 미션 한 건을 지원자 눈높이로 풀어 주는 값들. 시안(`gyumsa-refined`)의 `gyMeta`.
///
/// 목록과 상세가 같은 문구를 써야 해서 한 곳에 뒀다. 특히 **구매가 필요한지**는
/// 목록에서 바로 보여야 한다 — 포인트만 보고 들어갔다가 결제가 필요한 미션을
/// 만나면 안 되기 때문이다.
extension MissionMeta on PartnerMission {
  /// 후기·체험단(선정형)
  bool get isBlog => cat == 'blog';

  /// 현장 방문이 필요한 미션
  bool get isVisit => cat == 'visit' || const ['m15', 'm17', 'm19'].contains(id);

  /// 구매가 필요한 미션
  bool get isPaid => cat == 'shopping';

  /// 무료체험처럼 구독 조건을 확인해야 하는 미션
  bool get isTrial => id == 'm2';

  /// 돈이 들지 않는 미션. 목록 필터 '구매 없음'이 이걸 본다.
  bool get isFree => !isPaid && !isTrial && !isBlog;

  /// 목록 카드에 붙는 조건 꼬리표
  String get costTag {
    if (isPaid) return '구매 필요';
    if (isTrial) return '구독 조건 확인';
    if (isBlog) return '선정형 체험';
    return '구매 없음';
  }

  /// 참여 방식
  String get mode {
    if (id == 'm16') return '배송형 체험';
    return isVisit ? '방문 참여' : '온라인';
  }

  /// 상세의 '구매·비용'
  String get costDetail {
    if (isPaid) return '첫 구매 결제 필요 · 구매금액 별도';
    if (isTrial) return '무료체험 종료 후 과금·해지 조건 확인';
    if (isBlog) return '제공 범위·추가 비용은 모집 시 확인';
    return '상품 구매 없음 (시안 기준)';
  }

  /// 상세의 '완료 조건'
  String get completionRule {
    if (isBlog) return '선정 후 체험 및 후기 작성·검수';
    if (isVisit) return '방문 및 지정 인증 완료';
    if (isPaid) return '구매 확정 및 취소·반품 여부 확인';
    return '참여 요건 충족 및 완료 인증·검수';
  }

  /// 정렬·필터용 소요 시간(분). '방문'·'1~2시간'처럼 분으로 못 읽는 값은 뒤로 보낸다.
  int get minutes {
    final m = RegExp(r'^(\d+)분$').firstMatch(time);
    return m == null ? 999 : int.parse(m.group(1)!);
  }
}
