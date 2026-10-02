import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gyeomsa/core/ads/kakao_reward_ad.dart';
import 'package:gyeomsa/features/benefits/data/daily_missions.dart';
import 'package:gyeomsa/features/benefits/data/mission_providers.dart';
import 'package:gyeomsa/features/benefits/services/mission_engine.dart';
import 'package:gyeomsa/features/benefits/services/reward_ad_flow.dart';

/// 광고 보고 포인트 받기 — 카카오 애드핏 리워드 동영상.
/// 애드핏 정책 5.3.3: 직접 고른 경우에만, 보상 조건을 먼저 알린 뒤에 띄운다.
class _FakeAd extends KakaoRewardAd {
  final RewardAdResult result;
  final bool ready;
  int shown = 0;
  _FakeAd(this.result, {this.ready = true});

  @override
  bool get isReady => ready;

  @override
  Future<RewardAdResult> show() async {
    shown++;
    return result;
  }
}

final _adMission = dailyMissions.firstWhere((m) => m.id == 'ad');

MissionState _state() => MissionEngine((k, {daily = true}) => false).stateOf(_adMission);

Future<(List<String>, List<String>)> _run(WidgetTester tester, _FakeAd ad, {bool agree = true}) async {
  final earned = <String>[];
  final flashes = <String>[];
  final flow = RewardAdFlow(
    earn: (amt, label, {required key, daily = true}) async => earned.add('$amt:$key'),
    flash: flashes.add,
    ad: ad,
  );
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (c) {
          ctx = c;
          return const Scaffold();
        },
      ),
    ),
  );
  final done = flow.run(ctx, _state());
  await tester.pumpAndSettle();
  if (find.text('광고 보고 받기').evaluate().isNotEmpty) {
    await tester.tap(find.text(agree ? '광고 보고 받기' : '다음에 할게요'));
    await tester.pumpAndSettle();
  }
  await done;
  return (earned, flashes);
}

void main() {
  test('광고 시청 미션은 카카오 애드핏만 쓴다', () {
    expect(_adMission.providerId, 'adfit');
    expect(providerOf('adfit').name, contains('카카오'));
    expect(missionProviders.any((p) => p.id == 'admob'), isFalse);
  });

  test('시청 전 안내에 보상 조건·지급·제외 사유가 들어 있다', () {
    final rows = RewardAdFlow.notice(_state());
    final keys = rows.map((r) => r.$1).toList();
    expect(keys, containsAll(['보상 조건', '지급', '지급 제외']));
  });

  testWidgets('끝까지 보면 그 회차 키로 한 번 적립한다', (tester) async {
    final ad = _FakeAd(RewardAdResult.earned);
    final (earned, _) = await _run(tester, ad);
    expect(ad.shown, 1);
    expect(earned, ['${_adMission.points}:${_adMission.ledgerKey(0)}']);
  });

  testWidgets('중간에 닫거나 광고가 없으면 적립하지 않는다', (tester) async {
    for (final r in [RewardAdResult.skipped, RewardAdResult.noFill, RewardAdResult.unavailable]) {
      final (earned, flashes) = await _run(tester, _FakeAd(r));
      expect(earned, isEmpty, reason: '$r');
      expect(flashes, isNotEmpty);
    }
  });

  testWidgets('안내에서 다음에 하기를 누르면 광고를 띄우지 않는다 (Opt-in)', (tester) async {
    final ad = _FakeAd(RewardAdResult.earned);
    final (earned, _) = await _run(tester, ad, agree: false);
    expect(ad.shown, 0);
    expect(earned, isEmpty);
  });

  testWidgets('광고단위가 없으면 안내도 띄우지 않고 준비 중이라고 알린다', (tester) async {
    final ad = _FakeAd(RewardAdResult.earned, ready: false);
    final (earned, flashes) = await _run(tester, ad);
    expect(ad.shown, 0);
    expect(earned, isEmpty);
    expect(flashes.single, contains('준비 중'));
  });
}
