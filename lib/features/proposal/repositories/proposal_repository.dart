import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/server_api.dart';
import '../models/proposal.dart';

/// 신청한 이웃 한 명 (`proposals/{id}/joins/{uid}` — 제안자와 본인만 읽는다)
class ProposalJoiner {
  final String uid;
  final String name;
  const ProposalJoiner(this.uid, this.name);
}

/// 제안자에게 따로 한 부탁 (`proposals/{id}/asks/{uid}` — 부탁한 사람과 제안자만 읽는다, A29)
class ProposalAsk {
  final String uid;
  final String name;
  final String item;
  final int? est;
  final String note;

  /// pending · accepted · rejected
  final String status;

  /// 수락되면 생긴 거래 — 채팅은 이 거래로 연다
  final String? tradeId;
  const ProposalAsk({
    required this.uid,
    required this.name,
    required this.item,
    this.est,
    this.note = '',
    this.status = 'pending',
    this.tradeId,
  });

  bool get pending => status == 'pending';
  bool get accepted => status == 'accepted';

  static ProposalAsk? fromDoc(String uid, Map<String, dynamic>? m) {
    if (m == null || m['item'] is! String) return null;
    return ProposalAsk(
      uid: uid,
      name: '${m['name'] ?? '이웃'}',
      item: m['item'] as String,
      est: m['est'] is num ? (m['est'] as num).toInt() : null,
      note: m['note'] is String ? m['note'] as String : '',
      status: m['status'] is String ? m['status'] as String : 'pending',
      tradeId: m['tradeId'] is String ? m['tradeId'] as String : null,
    );
  }
}

/// 제안하기 서버 저장(A15). 읽기는 Firestore 구독, 쓰기는 모두 서버 함수(functions/src/proposal).
/// 서버 함수는 실패하면 [ServerException]을 던진다 — 화면이 그 문구를 보여 준다.
class ProposalRepository {
  final String uid;
  const ProposalRepository(this.uid);

  /// 최근 제안. 취소된 것은 뺀다(진행 중인 건 '진행'으로 남는다)
  Stream<List<Proposal>> watch({int limit = 100}) => Backend.db
      .collection('proposals')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snap) => [
            for (final d in snap.docs)
              if (Proposal.fromDoc(d.id, d.data(), myUid: uid) case final p? when !p.cancelled) p,
          ])
      .handleError((Object e) => debugPrint('제안 구독 실패: $e'));

  /// 내가 신청 중인 제안 id
  Stream<Set<int>> watchMyJoins() => Backend.db
      .collectionGroup('joins')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((snap) => {
            for (final d in snap.docs)
              if (d.data()['status'] == 'joined')
                if (int.tryParse('${d.data()['proposalId']}') case final id?) id,
          })
      .handleError((Object e) => debugPrint('내 신청 구독 실패: $e'));

  /// 내가 대기 예약한 제안 id (A30). [watchMyJoins]와 같은 색인을 쓰려고 상태는 앱에서 거른다
  Stream<Set<int>> watchMyWaits() => Backend.db
      .collectionGroup('joins')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((snap) => {
            for (final d in snap.docs)
              if (d.data()['status'] == 'waiting')
                if (int.tryParse('${d.data()['proposalId']}') case final id?) id,
          })
      .handleError((Object e) => debugPrint('내 대기 구독 실패: $e'));

  /// 내 제안에 신청한 이웃 (제안자만 읽을 수 있다)
  Stream<List<ProposalJoiner>> watchJoiners(int proposalId) => Backend.db
      .collection('proposals')
      .doc('$proposalId')
      .collection('joins')
      .where('status', isEqualTo: 'joined')
      .snapshots()
      .map((snap) => [for (final d in snap.docs) ProposalJoiner(d.id, '${d.data()['name'] ?? '이웃'}')])
      .handleError((Object e) => debugPrint('신청자 구독 실패: $e'));

  Future<void> create(Proposal p) => ServerApi.call('createProposal', p.toServer());
  Future<void> join(int id) => ServerApi.call('joinProposal', {'proposalId': '$id'});
  Future<void> leave(int id) => ServerApi.call('leaveProposal', {'proposalId': '$id'});

  /// 정원이 찬 제안에 대기 예약 — 자리가 나면 먼저 온 순서로 자동 참여(A30). 취소는 [leave]
  Future<void> wait(int id) => ServerApi.call('joinProposal', {'proposalId': '$id', 'wait': true});

  /// 제안자가 정원을 늘린다. 0이면 제한 없음 — 대기자가 늘어난 자리만큼 들어온다
  Future<void> raiseMax(int id, int max) => ServerApi.call('raiseProposalMax', {'proposalId': '$id', 'max': max});

  /// proceed — 지금 인원으로 진행 · cancel — 제안 취소
  Future<void> decide(int id, String action) => ServerApi.call('decideProposal', {'proposalId': '$id', 'action': action});

  /// 내 제안에 따로 온 부탁 — 답을 기다리는 것 · 수락한 것 (제안자만)
  Stream<List<ProposalAsk>> watchAsks(int proposalId) => _asks(proposalId)
      .where('status', whereIn: const ['pending', 'accepted'])
      .snapshots()
      .map((snap) => [
            for (final d in snap.docs)
              if (ProposalAsk.fromDoc(d.id, d.data()) case final a?) a,
          ])
      .handleError((Object e) => debugPrint('따로 온 부탁 구독 실패: $e'));

  /// 이 제안에 내가 따로 한 부탁
  Stream<ProposalAsk?> watchMyAsk(int proposalId) => _asks(proposalId)
      .doc(uid)
      .snapshots()
      .map((d) => ProposalAsk.fromDoc(d.id, d.data()))
      .handleError((Object e) => debugPrint('내 부탁 구독 실패: $e'));

  CollectionReference<Map<String, dynamic>> _asks(int id) => Backend.db.collection('proposals').doc('$id').collection('asks');

  /// 제안자에게 따로 부탁(A29). 다시 보내면 내용만 바뀐다
  Future<void> ask(int id, {required String item, int? est, String note = ''}) =>
      ServerApi.call('askProposer', {'proposalId': '$id', 'item': item, 'est': ?est, 'note': note});

  /// 제안자의 답 — 수락하면 거래가 생기고 채팅이 열린다
  Future<void> answerAsk(int id, String askerUid, bool accept) =>
      ServerApi.call('answerProposerAsk', {'proposalId': '$id', 'askerUid': askerUid, 'accept': accept});
}
