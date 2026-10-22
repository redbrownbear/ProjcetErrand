import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/app/neighbor_store.dart';
import 'package:gyeomsa/features/proposal/models/proposal.dart';
import 'package:gyeomsa/features/proposal/repositories/proposal_repository.dart';
import 'package:gyeomsa/features/proposal/widgets/proposal_sheet.dart';

/// 서버 대신 메모리에서 답하는 제안 저장소
class _FakeRepo implements ProposalRepository {
  @override
  final String uid;
  final List<Proposal> list;
  final calls = <String>[];
  _FakeRepo(this.uid, this.list);

  @override
  Stream<List<Proposal>> watch({int limit = 100}) => Stream.value(list);
  @override
  Stream<Set<int>> watchMyJoins() => Stream.value({});
  @override
  Stream<List<ProposalJoiner>> watchJoiners(int proposalId) => Stream.value(const [ProposalJoiner('a', '에이'), ProposalJoiner('b', '비')]);
  @override
  Future<void> create(Proposal p) async => calls.add('create:${p.item}:${p.delivery}');
  @override
  Future<void> join(int id) async => calls.add('join:$id');
  @override
  Future<void> leave(int id) async => calls.add('leave:$id');
  @override
  Future<void> decide(int id, String action) async => calls.add('decide:$id:$action');
  @override
  Stream<List<ProposalAsk>> watchAsks(int proposalId) => Stream.value(const [
    ProposalAsk(uid: 'c', name: '씨', item: '고들빼기', est: 12000),
    ProposalAsk(uid: 'd', name: '디', item: '돌산 갓', status: 'accepted', tradeId: 't1'),
  ]);
  ProposalAsk? myAsk;
  @override
  Stream<ProposalAsk?> watchMyAsk(int proposalId) => Stream.value(myAsk);
  @override
  Future<void> ask(int id, {required String item, int? est, String note = ''}) async => calls.add('ask:$id:$item:$est');
  @override
  Future<void> answerAsk(int id, String askerUid, bool accept) async => calls.add('answer:$id:$askerUid:$accept');
}

Map<String, dynamic> _doc({String owner = 'owner', String status = 'open', int count = 2}) => {
  'ownerUid': owner,
  'who': '여수댁',
  'abroad': false,
  'from': '여수',
  'to': '서울',
  'item': '갓김치',
  'price': 15000,
  'fee': 3000,
  'day': '2026-10-25',
  'max': 5,
  'joinedCount': count,
  'delivery': 'meet',
  'meetPlace': '강남역 11번 출구',
  'meetTime': '저녁 7시',
  'status': status,
  'createdAt': Timestamp.now(),
};

void main() {
  test('서버 문서 읽기: 인원은 서버가 센 값, 내 제안, 진행 · 취소 상태, 전달 방식', () {
    final p = Proposal.fromDoc('1792000000000123', _doc(), myUid: 'owner')!;
    expect(p.mine, isTrue);
    expect(p.onServer, isTrue);
    expect(p.sample, isFalse);
    expect(p.countWith(false), 2);
    expect(p.countWith(true), 2, reason: '서버 인원에는 내가 이미 들어 있다');
    expect(p.deliveryLabel, '한꺼번에 받기 · 강남역 11번 출구 · 저녁 7시');
    expect(Proposal.fromDoc('1', _doc(status: 'proceeding'), myUid: 'x')!.status(false), '진행');
    expect(Proposal.fromDoc('1', _doc(status: 'proceeding'), myUid: 'x')!.openFor(false), isFalse);
    expect(Proposal.fromDoc('x', _doc()), isNull);
  });

  test('서버로 보낼 값: 한국 날짜 · 국내/해외 · 받는 곳', () {
    final p = Proposal(
      id: 1,
      abroad: false,
      from: '여수',
      item: '갓김치',
      price: 15000,
      day: DateTime(2026, 11, 3),
      max: 3,
      who: '나',
      delivery: 'meet',
      meetPlace: '강남역',
    );
    final m = p.toServer();
    expect(m['day'], '2026-11-03');
    expect(m['to'], '서울');
    expect(m.containsKey('cc'), isFalse);
    expect(m['meetPlace'], '강남역');
  });

  test('서버에 붙으면: 실제 제안만(예시 없음), 신청 · 올리기는 서버 함수로', () async {
    final store = NeighborStore();
    final toasts = <String>[];
    store.toast = toasts.add;
    final server = Proposal.fromDoc('1792000000000123', _doc(owner: 'other'), myUid: 'me')!;
    late _FakeRepo repo;
    store.attachServer('me', repo: (uid) => repo = _FakeRepo(uid, [server]));
    await Future<void>.delayed(Duration.zero);
    expect(store.proposals.map((p) => p.id), [server.id]);
    expect(store.proposals.any((p) => p.sample), isFalse);

    store.toggleJoin(server);
    await Future<void>.delayed(Duration.zero);
    expect(repo.calls, contains('join:${server.id}'));

    store.addProposal(Proposal(id: 0, abroad: true, from: '도쿄', cc: 'jp', item: '도쿄바나나', price: 9000, day: DateTime.now(), max: 3, who: '나'));
    await Future<void>.delayed(Duration.zero);
    expect(repo.calls, contains('create:도쿄바나나:each'));

    store.attachServer(null);
    expect(store.proposalRepo, isNull);
    store.dispose();
  });

  testWidgets('내 서버 제안: 신청한 이웃 이름 · N명으로 진행하기', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = NeighborStore();
    final mine = Proposal.fromDoc('1792000000000123', _doc(), myUid: 'owner')!;
    late _FakeRepo repo;
    store.attachServer('owner', repo: (uid) => repo = _FakeRepo(uid, [mine]));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProposalSheet(store: store, p: mine, onOpenPost: (_) {}, onMoreStories: () {}, onReview: (_) {}, onOtherAsk: () {}),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('에이'), findsOneWidget);
    expect(find.text('2명으로 진행하기'), findsOneWidget);
    await tester.tap(find.byKey(const Key('proposal-proceed')));
    await tester.pump();
    expect(repo.calls, contains('decide:${mine.id}:proceed'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('제안자에게 따로 부탁(A29): 시트로 보내고, 수락되면 채팅하기', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = NeighborStore();
    final other = Proposal.fromDoc('1792000000000123', _doc(owner: 'other'), myUid: 'me')!;
    late _FakeRepo repo;
    store.attachServer('me', repo: (uid) => repo = _FakeRepo(uid, [other]));
    final chats = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ProposalSheet.show(
                context,
                store: store,
                p: other,
                onOpenPost: (_) {},
                onMoreStories: () {},
                onReview: (_) {},
                onOtherAsk: () => fail('서버 제안은 일반 부탁 쓰기로 가지 않는다'),
                onOpenChat: chats.add,
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다른 부탁'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('ask-item')), '고들빼기');
    await tester.enterText(find.byKey(const Key('ask-est')), '12000');
    await tester.pump();
    await tester.tap(find.byKey(const Key('ask-send')));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('ask:${other.id}:고들빼기:12000'));

    // 수락된 부탁이 있으면 채팅하기
    Navigator.of(tester.element(find.byType(ProposalSheet))).pop();
    await tester.pumpAndSettle();
    repo.myAsk = const ProposalAsk(uid: 'me', name: '나', item: '고들빼기', status: 'accepted', tradeId: 't9');
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('맡아 줬어요'), findsOneWidget);
    await tester.tap(find.text('채팅하기'));
    await tester.pumpAndSettle();
    expect(chats, ['t9']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('내 제안에 따로 온 부탁: 맡을게요 · 어려워요', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = NeighborStore();
    final mine = Proposal.fromDoc('1792000000000123', _doc(), myUid: 'owner')!;
    late _FakeRepo repo;
    store.attachServer('owner', repo: (uid) => repo = _FakeRepo(uid, [mine]));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProposalSheet(store: store, p: mine, onOpenPost: (_) {}, onMoreStories: () {}, onReview: (_) {}, onOtherAsk: () {}),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('따로 온 부탁'), findsOneWidget);
    expect(find.text('씨 · 고들빼기 · 예상 12,000원'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('ask-accept-c')));
    await tester.tap(find.byKey(const Key('ask-accept-c')));
    await tester.pump();
    expect(repo.calls, contains('answer:${mine.id}:c:true'));
    expect(tester.takeException(), isNull);
  });
}
