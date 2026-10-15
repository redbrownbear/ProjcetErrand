import 'package:flutter_test/flutter_test.dart';

import 'package:gyeomsa/features/benefits/data/partner_missions.dart';
import 'package:gyeomsa/features/benefits/models/mission_meta.dart';

/// 미션 조건 문구가 목록(마켓 › 미션)에 그대로 나오는지 본다.
void main() {
  test('미션 조건 문구 — 구매가 필요한 미션을 목록에서 구분한다', () {
    final shopping = partnerMissions.firstWhere((m) => m.id == 'm5');
    final trial = partnerMissions.firstWhere((m) => m.id == 'm2');
    final blog = partnerMissions.firstWhere((m) => m.cat == 'blog');
    final plain = partnerMissions.firstWhere((m) => m.id == 'm1');

    expect(shopping.costTag, '구매 필요');
    expect(shopping.isFree, isFalse);
    expect(trial.costTag, '구독 조건 확인');
    expect(blog.costTag, '선정형 체험');
    expect(plain.costTag, '구매 없음');
    expect(plain.isFree, isTrue);
    expect(plain.minutes, 3);
    // '방문'·'1~2시간'처럼 분으로 못 읽는 값은 3분 이내 필터에서 빠진다.
    expect(partnerMissions.firstWhere((m) => m.time == '방문').minutes, 999);
  });
}
