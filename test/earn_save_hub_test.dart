import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gyeomsa/features/benefits/data/partner_missions.dart';
import 'package:gyeomsa/features/benefits/screens/earn_hub_screen.dart';
import 'package:gyeomsa/features/dayjob/data/day_jobs.dart';
import 'package:gyeomsa/features/dayjob/screens/day_job_screen.dart';
import 'package:gyeomsa/features/deals/data/member_deals.dart';
import 'package:gyeomsa/features/deals/screens/save_hub_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  group('오늘 벌기 허브 (§15 2차 메뉴)', () {
    testWidgets('네 개의 2차 메뉴가 모두 보인다', (tester) async {
      await tester.pumpWidget(_wrap(EarnHubScreen(
        doneMissions: const [], completeMission: (_) {}, onOpenErrand: () {}, onApplyDayJob: (_) {},
      )));
      for (final label in ['심부름', '참여·리워드', '단기알바', '간단 미션']) {
        expect(find.textContaining(label), findsWidgets, reason: '2차 메뉴 $label 이 없음');
      }
    });

    testWidgets('심부름 메뉴는 심부름 목록으로 연결된다', (tester) async {
      var opened = false;
      await tester.pumpWidget(_wrap(EarnHubScreen(
        doneMissions: const [], completeMission: (_) {}, onOpenErrand: () => opened = true, onApplyDayJob: (_) {},
      )));
      await tester.tap(find.textContaining('심부름').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('근처 심부름 보러 가기'));
      expect(opened, isTrue);
    });
  });

  group('미션 분류', () {
    test('모든 미션이 2차 메뉴 중 하나에 속한다', () {
      for (final m in partnerMissions) {
        expect(['reward', 'mission'], contains(m.group), reason: '${m.id} 의 group 이 잘못됨');
      }
    });

    test('규제 영역 미션은 전용 고지 키를 갖는다', () {
      String keyOf(String id) => partnerMissions.firstWhere((m) => m.id == id).disclosureKey;
      expect(keyOf('m21'), 'realEstate'); // 모델하우스
      expect(keyOf('m22'), 'clinical'); // 임상시험
      expect(keyOf('m23'), 'research'); // 대학 연구실
      expect(keyOf('m24'), 'insurance'); // 보험 상담
      expect(keyOf('m7'), 'finance'); // 금융 프로모션
    });
  });

  group('단기알바 (§11)', () {
    test('모든 공고가 필수 표시 항목을 채우고 있다', () {
      for (final j in dayJobs) {
        expect(j.pay, greaterThan(0), reason: '${j.id} 금액 없음');
        for (final v in [j.payKind, j.hours, j.place, j.payDate, j.level, j.gear, j.idCheck, j.source]) {
          expect(v, isNotEmpty, reason: '${j.id} 필수 표시 항목 누락');
        }
      }
    });

    testWidgets('목록에서 지급일·난이도·준비물·신원확인이 바로 보인다', (tester) async {
      await tester.pumpWidget(_wrap(DayJobScreen(onApply: (_) {})));
      final top = dayJobs.reduce((a, b) => a.pay >= b.pay ? a : b);
      expect(find.textContaining('💵 ${top.payDate}'), findsWidgets);
      expect(find.textContaining('🪪 ${top.idCheck}'), findsWidgets);
    });
  });

  group('생활비 아끼기 (§10)', () {
    test('가격이 있는 상품은 비교 기준가의 출처를 함께 갖는다', () {
      for (final d in memberDeals.where((d) => d.isPriced)) {
        expect(d.baseSource, isNotEmpty, reason: '${d.id} 기준가 출처 없음');
        expect(d.memberPrice, lessThan(d.basePrice), reason: '${d.id} 회원가가 기준가보다 비쌈');
        expect(d.howMade, isNotEmpty, reason: '${d.id} 특가 조성 근거 없음');
      }
    });

    testWidgets('최저가를 약속하지 않는다는 원칙이 화면에 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(SaveHubScreen(
        earn: (amt, label, {required key, daily = true}) async {},
        isClaimed: (key, {daily = true}) => false,
        onUse: (_) {},
      )));
      // 원칙 문구는 목록 맨 아래에 붙어 있어 스크롤해야 그려진다
      await tester.scrollUntilVisible(
        find.textContaining('최저가를 보장하는 가격이 아니라'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('최저가를 보장하는 가격이 아니라'), findsWidgets);
    });
  });
}
