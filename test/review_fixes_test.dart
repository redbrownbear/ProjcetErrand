import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gyeomsa/app/session_store.dart';
import 'package:gyeomsa/core/theme/app_theme.dart';
import 'package:gyeomsa/core/storage/local_store.dart';
import 'package:gyeomsa/core/utils/stable_sort.dart';
import 'package:gyeomsa/features/dayjob/screens/job_post_form.dart';
import 'package:gyeomsa/features/benefits/models/coupon.dart';
import 'package:gyeomsa/features/benefits/models/point_wallet.dart';
import 'package:gyeomsa/features/benefits/models/reward_product.dart';
import 'package:gyeomsa/features/benefits/screens/point_shop_screen.dart';
import 'package:gyeomsa/features/errand/models/task_item.dart';
import 'package:gyeomsa/features/errand/navigation/errand_actions.dart';
import 'package:gyeomsa/features/errand/screens/detail_page.dart';
import 'package:gyeomsa/features/lucky/models/tickets.dart';
import 'package:gyeomsa/features/proposal/models/proposal.dart';

/// 2026-10-16 전체 코드 리뷰에서 고친 버그들이 다시 생기지 않는지 본다.
void main() {
  group('안정 정렬', () {
    test('같은 값끼리는 원래 순서를 지킨다 (32개를 넘어도)', () {
      final list = [for (var i = 0; i < 100; i++) (key: i % 3, order: i)];
      list.sortStable((a, b) => a.key - b.key);
      for (var i = 1; i < list.length; i++) {
        final a = list[i - 1], b = list[i];
        expect(a.key < b.key || (a.key == b.key && a.order < b.order), isTrue);
      }
    });
  });

  group('내 글 판단', () {
    tearDown(() => TaskItem.currentUid = null);

    test('남의 서버 글은 작성자 이름이 "나"여도 내 글이 아니다', () {
      TaskItem.currentUid = 'me';
      const other = TaskItem(id: 1, mode: 'ask', title: 't', who: '나', desc: 'd', distM: null, ownerUid: 'other', sample: false);
      expect(other.isMine, isFalse);
    });

    test('올릴 때 남긴 표시나 같은 uid면 내 글이다', () {
      TaskItem.currentUid = 'me';
      const marked = TaskItem(id: 1, mode: 'ask', title: 't', who: '닉', desc: 'd', distM: null, mine: true);
      const owned = TaskItem(id: 2, mode: 'ask', title: 't', who: '닉', desc: 'd', distM: null, ownerUid: 'me');
      expect(marked.isMine, isTrue);
      expect(owned.isMine, isTrue);
    });

    test('이 기기에 보관된 옛 글은 표시가 없어도 내 글로 되살린다', () {
      final it = TaskItem.fromJson({'id': 1, 'mode': 'ask', 'title': 't', 'desc': 'd', 'who': '나'});
      expect(it!.isMine, isTrue);
    });
  });

  group('쿠폰', () {
    test('유효기간은 교환한 날부터 1년', () {
      expect(Coupon.expiryFrom(DateTime(2026, 10, 16)), '2027.10.16');
    });

    test('이 기기 사본으로 저장했다가 되살린다', () {
      const c = Coupon(id: 7, brandK: 'cu', name: '아메리카노', points: 1500, exp: '2027.10.16', code: 'GC1', used: true);
      final back = Coupon.fromJson(c.toJson())!;
      expect(
        [back.id, back.brandK, back.name, back.points, back.exp, back.code, back.used],
        [7, 'cu', '아메리카노', 1500, '2027.10.16', 'GC1', true],
      );
      expect(Coupon.fromJson('broken'), isNull);
    });
  });

  group('이 기기 사본', () {
    const store = SessionStore();

    test('포인트·쿠폰도 남는다 (예전엔 앱을 다시 켜면 0P로 시작했다)', () {
      store.savePoints(120);
      store.saveCoupons(const [Coupon(id: 1, brandK: 'cu', name: 'n', points: 10, exp: 'e', code: 'c')]);
      expect(store.loadPoints(), 120);
      expect(store.loadCoupons().single.id, 1);
    });

    test('주인을 기록하고, 계정 자료를 지우면 다른 기기 설정은 남는다', () {
      store.saveOwner('uid-a');
      store.saveBookmarks([1, 2]);
      store.savePoints(50);
      LocalStore.write('tickets', {'have': 3});
      expect(store.loadOwner(), 'uid-a');

      store.clearAccount();
      store.saveOwner(null);
      expect(store.loadOwner(), isNull);
      expect(store.loadBookmarks(), isEmpty);
      expect(store.loadPoints(), 0);
      expect(LocalStore.read<Map<String, dynamic>>('tickets', const {})['have'], 3, reason: '응모권은 계정 자료가 아니다');
    });
  });

  group('응모권', () {
    test('하루 기준은 한국 시간이다', () {
      // UTC 10/16 16:00 = 한국 10/17 01:00
      final late = DateTime.utc(2026, 10, 16, 16);
      final w = const TicketWallet().gain(TicketRules.attend, late)!;
      expect(w.claimed, contains('attend:2026-10-17'));
    });

    test('달이 바뀌면 지난 달의 하루 한 번 기록은 버리고 한 번뿐인 기록은 남긴다', () {
      final oct = DateTime(2026, 10, 16, 12);
      var w = const TicketWallet().gain(TicketRules.attend, oct)!.gain(TicketRules.firstPost, oct)!;
      w = w.gain(TicketRules.attend, DateTime(2026, 11, 2, 12))!;
      expect(w.claimed, containsAll(['firstPost', 'attend:2026-11-02']));
      expect(w.claimed, isNot(contains('attend:2026-10-16')));
    });
  });

  test('저장된 제안의 나라 코드가 문자열이 아니어도 앱이 멈추지 않는다', () {
    final p = Proposal.fromJson({'id': 1, 'item': '바나나', 'price': 3000, 'day': '2026-10-20', 'cc': 81, 'spec': 3});
    expect(p, isNotNull);
    expect(p!.cc, isNull);
  });

  testWidgets('열린 상세 화면이 관심 저장을 바로 반영한다', (tester) async {
    // 세션처럼 바뀔 때마다 새 목록으로 갈아 끼운다 — 옛 목록에 묶인 화면은 갱신되지 않는다
    var saved = <int>[];
    final changes = ValueNotifier(0);
    late ErrandActions Function() build;
    build = () => ErrandActions(
      grabbed: const [],
      onGrab: (_) {},
      onOffer: (_, _, _) {},
      offers: const {},
      isSaved: saved.contains,
      toggleSave: (id) {
        saved = saved.contains(id) ? [...saved.where((x) => x != id)] : [...saved, id];
        changes.value++;
      },
      changes: changes,
      latest: () => build(),
    );
    const it = TaskItem(id: 42, mode: 'ask', title: '커피 픽업', who: '이웃', desc: '아메리카노 두 잔', distM: 300);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(onPressed: () => build().open(context, it), child: const Text('열기')),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    await tester.tap(find.byTooltip('관심 저장'));
    await tester.pump();
    expect(saved, [42]);
    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
  });

  group('포인트샵', () {
    Future<void> open(WidgetTester tester, PointWallet wallet) async {
      tester.view.physicalSize = const Size(375, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: PointShopScreen(wallet: wallet, goPointsHub: () {}),
        ),
      );
    }

    Future<void> redeemFirst(WidgetTester tester) async {
      await tester.tap(find.text('교환하기').first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('P 사용하기'));
      await tester.pumpAndSettle();
    }

    testWidgets('교환하면 열린 화면의 보유 포인트가 바로 줄어든다', (tester) async {
      final changes = ValueNotifier(0);
      var points = 100000;
      final wallet = PointWallet(
        changes: changes,
        readPoints: () => points,
        readCoupons: () => const [],
        redeem: (RewardProduct p) async {
          points -= p.points;
          changes.value++;
          return true;
        },
        useCoupon: (_) {},
      );
      await open(tester, wallet);
      expect(find.text('100,000P'), findsOneWidget);
      await redeemFirst(tester);
      expect(points, lessThan(100000));
      expect(find.text('100,000P'), findsNothing);
      expect(find.text('교환 완료!'), findsOneWidget);
    });

    testWidgets('교환이 안 됐으면 교환 완료를 띄우지 않는다', (tester) async {
      final wallet = PointWallet(
        changes: ValueNotifier(0),
        readPoints: () => 100000,
        readCoupons: () => const [],
        redeem: (_) async => false,
        useCoupon: (_) {},
      );
      await open(tester, wallet);
      await redeemFirst(tester);
      expect(find.text('교환 완료!'), findsNothing);
    });
  });

  test('단기알바 폼 — 마감이 근무 시작보다 늦으면 등록할 수 없다', () {
    final now = DateTime(2026, 10, 16, 9);
    final f = JobPostForm()
      ..pay.text = '12000'
      ..start = DateTime(2026, 10, 20, 9)
      ..end = DateTime(2026, 10, 20, 18)
      ..payDate = DateTime(2026, 10, 25)
      ..deadline = DateTime(2026, 10, 19, 18)
      ..contact.text = '인사팀'
      ..confirmed = true;
    expect(f.validAt(2, now), isTrue);
    f.deadline = DateTime(2026, 10, 21);
    expect(f.validAt(2, now), isFalse);
    expect(f.netMinutes, 9 * 60);
    f.dispose();
  });

  testWidgets('앱 테마에서 부탁 상세가 깨지지 않는다 (가격 제안 버튼이 무한 폭이던 문제)', (tester) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const it = TaskItem(id: 7, mode: 'ask', title: '커피 픽업', who: '이웃', desc: '아메리카노 두 잔', distM: 300, price: 3000);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: DetailPage(
          it: it,
          grabbed: const [],
          myOffers: const [],
          onGrab: (_) {},
          onOffer: (_, _, _) {},
          isSaved: (_) => false,
          toggleSave: (_) {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('가격 제안'), findsOneWidget);
    expect(find.text('지원하기'), findsOneWidget);
  });
}
