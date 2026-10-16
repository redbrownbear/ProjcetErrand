import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gyeomsa/app/app_nav.dart';
import 'package:gyeomsa/app/neighbor_store.dart';
import 'package:gyeomsa/features/benefits/screens/side_job_view.dart';
import 'package:gyeomsa/features/chat/screens/chat_view.dart';
import 'package:gyeomsa/features/community/screens/community_view.dart';
import 'package:gyeomsa/features/errand/repositories/errand_repository.dart';
import 'package:gyeomsa/features/errand/screens/home/home_content.dart';
import 'package:gyeomsa/features/errand/screens/overseas_tab.dart';
import 'package:gyeomsa/features/lucky/models/tickets.dart';
import 'package:gyeomsa/features/lucky/screens/lucky_draw_screen.dart';
import 'package:gyeomsa/features/lucky/widgets/lucky_card.dart';
import 'package:gyeomsa/features/proposal/models/proposal.dart';
import 'package:gyeomsa/features/proposal/widgets/live_board.dart';
import 'package:gyeomsa/features/benefits/models/point_wallet.dart';

import 'support/social.dart';

/// 시안 v77 — 응모권 · 제안 규칙과, v77에서 붙은 부분이 기준 폰 폭에서 넘치지 않는지 본다.
final _items = LocalErrandRepository().fetchSeedItems();

Future<void> _phone(WidgetTester tester, Widget child, {double height = 812}) async {
  tester.view.physicalSize = Size(375, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pump();
}

/// 히어로·배너가 Timer로 돈다. 테스트가 끝나기 전에 트리를 내려 타이머를 끊는다.
Future<void> _unmount(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  group('응모권', () {
    final day1 = DateTime(2026, 10, 16, 9);
    final day2 = DateTime(2026, 10, 17, 9);

    test('출석은 하루 한 번, 첫 부탁은 계정당 한 번', () {
      var w = const TicketWallet();
      w = w.gain(TicketRules.attend, day1)!;
      expect(w.have, 1);
      expect(w.gain(TicketRules.attend, day1), isNull, reason: '같은 날 두 번');
      w = w.gain(TicketRules.attend, day2)!;
      expect(w.have, 2);

      w = w.gain(TicketRules.firstPost, day1)!;
      expect(w.have, 7);
      expect(w.gain(TicketRules.firstPost, day2), isNull);

      // 부탁 완료처럼 반복되는 건 할 때마다
      w = w.gain(TicketRules.helpDone, day2)!.gain(TicketRules.helpDone, day2)!;
      expect(w.have, 13);
    });

    test('응모하면 가진 장수에서 빠지고, 가진 것보다 많이 낼 수 없다', () {
      var w = const TicketWallet().gain(TicketRules.push, day1)!;
      expect(w.enter(11, day1), isNull);
      w = w.enter(6, day1)!;
      expect((w.have, w.entered), (4, 6));
    });

    test('달이 바뀌면 이번 달 응모는 0부터, 가진 장수는 남는다', () {
      var w = const TicketWallet().gain(TicketRules.push, day1)!.enter(4, day1)!;
      w = w.gain(TicketRules.helpDone, DateTime(2026, 11, 1))!;
      expect(w.entered, 0);
      expect(w.have, 9);
    });

    test('럭키드로우 D-day는 그달 말일까지 남은 날', () {
      expect(LuckyDraw(DateTime(2026, 10, 16)).dday, 15);
      expect(LuckyDraw(DateTime(2026, 10, 31)).dday, 0);
      expect(LuckyDraw(DateTime(2026, 10, 16)).label, '10월 LUCKY DRAW · D-15');
    });
  });

  group('제안', () {
    final today = DateTime.now();
    Proposal p({int max = 5, int joined = 0, int plus = 0}) => Proposal(
      id: 1,
      abroad: false,
      from: '여수',
      item: '갓김치',
      price: 12000,
      day: DateTime(today.year, today.month, today.day + plus),
      max: max,
      joined: joined,
      who: '다온 스토어',
    );

    test('보드 상태 — 남은 자리 · 1자리 · 마감 · 제한 없음', () {
      expect(p(joined: 3).status(false), '3/5');
      expect(p(joined: 4).status(false), '1자리');
      expect(p(joined: 4).status(true), '마감');
      expect(p(max: 0, joined: 2).status(false), '2명');
      expect(p(plus: -1).status(false), '마감', reason: '지난 날짜');
    });

    test('국내 제안 문구는 출발지 → 도착지와 날짜를 담는다', () {
      final d = DateTime(today.year, today.month, today.day);
      expect(p().headline, '여수에서 ${d.month}/${d.day}에 서울로 올라가는데 갓김치 원하시는 분?');
      expect(dayTag(d), '오늘');
      expect(dayTag(d.add(const Duration(days: 1))), '내일');
    });

    test('정원이 찬 제안에는 구매 요청을 보낼 수 없다', () {
      final store = NeighborStore();
      final toasts = <String>[];
      store.toast = toasts.add;
      final full = store.proposals.firstWhere((x) => x.max > 0 && x.joined >= x.max);
      store.toggleJoin(full);
      expect(store.joined.contains(full.id), isFalse);
      expect(toasts.last, contains('정원'));

      final open = store.proposals.firstWhere((x) => x.id == 9003); // 강릉 닭강정 — 자리 남음
      store.toggleJoin(open);
      expect(store.joined.contains(open.id), isTrue);
    });

    test('답글을 달면 응모권 +1', () {
      final store = NeighborStore();
      final before = store.wallet.have;
      store.addComment(7001, '좋아요');
      expect(store.wallet.have, before + 1);
      expect(store.postById(7001)!.comments.last.text, '좋아요');
    });
  });

  group('화면', () {
    HomeContent home(AppNav social) => HomeContent(
      social: social,
      items: _items,
      scope: '서울 서초구',
      actions: social.actions(),
      wallet: PointWallet.fixed(points: 3200),
      steps: 0,
      monthEarn: 0,
      doneMissions: const [],
      isClaimed: (k, {daily = true}) => false,
      earn: (a, l, {required key, daily = true}) async {},
      completeMission: (_) {},
      flash: (_) {},
      goPay: () {},
      goProfile: () {},
      goPost: () {},
      goPostCat: (_) {},
      goPostSea: () {},
      goOverseasTab: () {},
      goSideTab: (_) {},
      goPointsHub: () {},
      activeCount: 0,
      goActivity: () {},
      openJobPost: () {},
    );

    testWidgets('홈 · 국내 — 럭키드로우 말풍선 · LIVE 보드 · 가는 김에가 붙는다', (tester) async {
      await _phone(tester, home(testSocial()), height: 5200);
      expect(find.text('이동하는 길에, 필요한 분?'), findsOneWidget);
      expect(find.textContaining('LUCKY DRAW'), findsOneWidget);
      expect(find.text('여행 어디 갈까?'), findsOneWidget);
      expect(find.text('내일 오사카 가요'), findsOneWidget, reason: '가는 김에 글');
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('돈벌기'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('이동하는 길에, 필요한 분?'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    });

    testWidgets('홈 · 해외 — 부탁하기 · 돈벌기 · 현지 이웃', (tester) async {
      final social = testSocial();
      await _phone(tester, OverseasTab(items: _items, actions: social.actions(), onPostSea: () {}, social: social), height: 4000);
      expect(find.text('가는 김에 사다 드려요'), findsOneWidget);
      for (final seg in ['돈벌기', '현지 이웃']) {
        await tester.tap(find.text(seg).first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: seg);
      }
      expect(find.text('현지 거주 확인'), findsWidgets);
      await _unmount(tester);
    });

    testWidgets('마켓 — 미션 · 공동구매 · 중고장터 · 나눔', (tester) async {
      final social = testSocial();
      await _phone(
        tester,
        SideJobView(
          social: social,
          wallet: PointWallet.fixed(points: 3200),
          items: _items,
          scope: '서울 서초구',
          actions: social.actions(),
          monthEarn: 0,
          freeLeft: 3,
          doneMissions: const [],
          earn: (a, l, {required key, daily = true}) async {},
          isClaimed: (k, {daily = true}) => false,
          completeMission: (_) {},
          goPointsHub: () {},
          flash: (_) {},
        ),
        height: 2400,
      );
      expect(find.textContaining('LUCKY DRAW'), findsOneWidget);
      for (final t in ['공동구매', '중고장터', '나눔']) {
        await tester.tap(find.text(t).first);
        await tester.pump();
        expect(tester.takeException(), isNull, reason: t);
      }
      expect(find.text('아이 옷 한 상자 나눔해요'), findsOneWidget);
      await _unmount(tester);
    });

    testWidgets('커뮤니티 — 여행 피드에 제안이 글처럼 섞이고, 지어낸 이웃 수가 없다', (tester) async {
      await _phone(tester, CommunityView(nav: testSocial(), goOverseasAsk: () {}), height: 3000);
      expect(find.text('우리 동네에서 제일 좋아하는 가게는?'), findsOneWidget);
      expect(find.textContaining('312명'), findsNothing);
      await tester.tap(find.text('여행'));
      await tester.pump();
      expect(find.text('저 구매할래요!'), findsWidgets);
      await tester.tap(find.text('해외'));
      await tester.pump();
      expect(find.text('출국 전, 여행자보험 챙기셨나요?'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    });

    testWidgets('LIVE 보드 줄을 누르면 제안 상세가 열리고 구매 요청이 된다', (tester) async {
      final store = NeighborStore();
      final nav = testSocial(store: store);
      await _phone(
        tester,
        ListenableBuilder(
          listenable: store,
          builder: (context, _) =>
              LiveBoard(store: store, abroad: false, onOpen: (p) => nav.openProposal(context, p), onAll: () {}, onPropose: () {}),
        ),
      );
      expect(find.textContaining('체험용 예시'), findsOneWidget);
      await tester.tap(find.text('갓김치'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('저 구매할래요!'), findsOneWidget);
      await tester.tap(find.text('저 구매할래요!'));
      await tester.pump();
      expect(store.joined.contains(9001), isTrue);
      expect(find.text('구매 요청 취소'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    });

    testWidgets('마이 — 응모권 카드', (tester) async {
      await _phone(tester, LuckyCard(nav: testSocial()));
      expect(find.textContaining('내 응모권'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('채팅 빈 화면', (tester) async {
      await _phone(tester, ChatView(onGoActivity: () {}, onBrowse: () {}));
      expect(find.text('아직 대화가 없어요'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('럭키드로우 — 응모하면 보유 응모권이 줄어든다', (tester) async {
      final store = NeighborStore();
      store.gainTicket(TicketRules.push);
      final have = store.wallet.have;
      await _phone(
        tester,
        ListenableBuilder(
          listenable: store,
          builder: (_, _) => LuckyDrawScreen(wallet: () => store.wallet, onEnter: store.enterDraw),
        ),
        height: 1600,
      );
      expect(find.text('$have개 보유'), findsOneWidget);
      await tester.tap(find.text('응모하기'));
      await tester.pump();
      expect(store.wallet.have, 0);
      expect(store.wallet.entered, have);
      expect(tester.takeException(), isNull);
    });
  });
}
