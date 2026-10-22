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

  /// proceed — 지금 인원으로 진행 · cancel — 제안 취소
  Future<void> decide(int id, String action) => ServerApi.call('decideProposal', {'proposalId': '$id', 'action': action});
}
