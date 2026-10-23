import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/app/neighbor_store.dart';
import 'package:gyeomsa/features/errand/repositories/activity_repository.dart';
import 'package:gyeomsa/features/proposal/models/proposal.dart';
import 'package:gyeomsa/features/proposal/repositories/proposal_repository.dart';
import 'package:gyeomsa/features/proposal/widgets/live_board.dart';

class _NoProposals implements ProposalRepository {
  @override
  final String uid;
  _NoProposals(this.uid);
  @override
  Stream<List<Proposal>> watch({int limit = 100}) => Stream.value(const []);
  @override
  Stream<MyJoins> watchMyJoins() => Stream.value((joined: const {}, waiting: const {}));
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Done extends ActivityRepository {
  final List<DoneActivity> list;
  const _Done(this.list);
  @override
  Stream<List<DoneActivity>> watchRecent({int limit = 20}) => Stream.value(list);
}

/// A23 LIVE 보드 실데이터: 서버에 붙으면 예시 · 가짜 제휴 줄 없이 실제 제안만, 최근 완료 한 줄
void main() {
  final now = DateTime(2026, 10, 23, 12);

  test('완료 기록: 동네 · 종류 · 시각만 읽는다', () {
    final a = DoneActivity.fromDoc('t1', {'kind': 'done', 'mode': 'ask', 'cat': 'pickup', 'area': '방배동', 'cc': '', 'at': Timestamp.fromDate(now)})!;
    expect(a.line, '방배동 · 받아오기 부탁이 끝났어요');
    expect(a.abroad, isFalse);
    final g = DoneActivity.fromDoc('t2', {'kind': 'done', 'mode': 'going', 'area': '서초동', 'at': Timestamp.fromDate(now)})!;
    expect(g.line, '서초동 · 가는 김에 부탁이 끝났어요');
    final sea = DoneActivity.fromDoc('t3', {'kind': 'done', 'mode': 'sea', 'cc': 'jp', 'at': Timestamp.fromDate(now)})!;
    expect(sea.abroad, isTrue);
    expect(sea.line, startsWith('일본'));
    expect(DoneActivity.fromDoc('x', {'kind': 'done'}), isNull);
  });

  testWidgets('서버에 붙고 제안이 없으면 빈 상태 · 예시 · 제휴 줄 없음 · 최근 완료 한 줄', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = NeighborStore()..clock = () => now;
    store.attachServer(
      'me',
      repo: _NoProposals.new,
      activity: _Done([
        DoneActivity(id: 't1', mode: 'ask', cat: 'pickup', area: '방배동', at: now.subtract(const Duration(minutes: 12))),
        DoneActivity(id: 'old', mode: 'ask', area: '옛동', at: now.subtract(const Duration(days: 9))),
      ]),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ListenableBuilder(
              listenable: store,
              builder: (_, _) => LiveBoard(store: store, abroad: false, onOpen: (_) {}, onAll: () {}, onPropose: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(store.live, isTrue);
    expect(find.textContaining('아직 올라온 제안이 없어요'), findsOneWidget);
    expect(find.text('AD'), findsNothing);
    expect(find.textContaining('체험용 예시'), findsNothing);
    expect(find.text('방배동 · 받아오기 부탁이 끝났어요'), findsOneWidget);
    expect(find.text('12분 전'), findsOneWidget);
    expect(find.textContaining('옛동'), findsNothing, reason: '일주일이 지난 완료는 안 보인다');
    expect(tester.takeException(), isNull);
    store.dispose();
  });

  testWidgets('로그인 전에는 체험용 예시 · 제휴 줄', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = NeighborStore();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: LiveBoard(store: store, abroad: false, onOpen: (_) {}, onAll: () {}, onPropose: () {})),
        ),
      ),
    );
    await tester.pump();
    expect(store.live, isFalse);
    expect(find.text('AD'), findsOneWidget);
    expect(find.textContaining('체험용 예시'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
