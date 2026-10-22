import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/core/widgets/bubble_quota.dart';
import 'package:gyeomsa/core/widgets/hero_card.dart';

/// A24 겸이 말풍선 노출 상한: 세션당 3번 · 3분 간격 · 닫으면 하루, '이벤트' 표시
void main() {
  var now = DateTime(2026, 10, 23, 12);
  setUp(() {
    now = DateTime(2026, 10, 23, 12);
    BubbleQuota.clock = () => now;
    BubbleQuota.reset();
  });

  test('세션당 3번, 3분 간격', () {
    expect(BubbleQuota.take(), isTrue);
    expect(BubbleQuota.take(), isFalse, reason: '바로 다시는 안 된다');
    now = now.add(const Duration(minutes: 3));
    expect(BubbleQuota.take(), isTrue);
    now = now.add(const Duration(minutes: 5));
    expect(BubbleQuota.take(), isTrue);
    now = now.add(const Duration(minutes: 5));
    expect(BubbleQuota.take(), isFalse, reason: '세 번 넘음');
  });

  test('닫으면 하루 동안 안 보인다', () {
    BubbleQuota.dismiss();
    now = now.add(const Duration(hours: 23));
    expect(BubbleQuota.take(), isFalse);
    now = now.add(const Duration(hours: 2));
    expect(BubbleQuota.take(), isTrue);
  });

  testWidgets('카드: 이벤트 표시 · 닫기, 다시 그려도 상한을 더 쓰지 않는다', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    Widget card() => MaterialApp(
      home: Scaffold(
        body: HeroCard(
          sub: '부탁하기',
          title: '무엇이든\n**부탁**해요',
          floats: const [],
          cta: '부탁하기',
          ctaIcon: 'plus',
          onCta: () {},
          note: '',
          bubble: const SizedBox(width: 120, height: 50, child: Text('럭키드로우')),
        ),
      ),
    );
    await tester.pumpWidget(card());
    expect(find.text('럭키드로우'), findsOneWidget);
    expect(find.text('이벤트'), findsOneWidget);
    await tester.pumpWidget(card());
    expect(find.text('럭키드로우'), findsOneWidget);
    await tester.tap(find.byKey(const Key('hero-bubble-close')));
    await tester.pump();
    expect(find.text('럭키드로우'), findsNothing);
    expect(BubbleQuota.take(), isFalse, reason: '닫은 뒤 하루');
    expect(tester.takeException(), isNull);
  });
}
