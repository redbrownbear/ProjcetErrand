import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/live_query.dart';
import '../../../core/backend/server_api.dart';
import '../models/application.dart';

/// 지원·거래 읽기(구독)와 서버 함수 호출.
///
/// 읽기는 Firestore를 직접 구독하고, 상태를 바꾸는 일은 전부 서버 함수로 한다.
/// 보안 규칙 v2가 앱의 직접 쓰기를 막는다(firebase/firestore.rules).
class TradeRepository {
  final String uid;
  const TradeRepository(this.uid);

  // ── 구독 ────────────────────────────────────────────────────────────────

  /// 내가 낸 지원 전체
  Stream<List<Application>> watchMyApplications() =>
      _apps(Backend.db.collectionGroup('applications').where('helperUid', isEqualTo: uid));

  /// 내 부탁에 들어온 지원 전체(상태 무관). 화면에서 대기 중인 것만 거른다.
  Stream<List<Application>> watchReceived() =>
      _apps(Backend.db.collectionGroup('applications').where('requesterUid', isEqualTo: uid));

  /// 내가 요청자 또는 수행자인 거래
  Stream<List<ServerTrade>> watchTrades({required bool asRequester}) => Backend.db
      .collection('trades')
      .where(asRequester ? 'requesterUid' : 'helperUid', isEqualTo: uid)
      .live((d) => ServerTrade.fromDoc(d.id, d.data()!), label: '거래');

  Stream<List<Application>> _apps(Query<Map<String, dynamic>> q) =>
      q.live((d) => Application.fromDoc(d.reference.parent.parent?.id ?? '', d.id, d.data()!), label: '지원');

  // ── 서버 함수 ───────────────────────────────────────────────────────────

  /// [est]·[spot]은 가는 김에 '어! 나도'에만 쓴다(예상 물건값·받는 곳)
  static Future<void> apply(int requestId, {int? offerPrice, String? msg, int? est, String? spot}) => ServerApi.call(
    'applyToRequest',
    {'requestId': '$requestId', 'offerPrice': ?offerPrice, 'msg': ?msg, 'est': ?est, 'spot': ?spot},
  );

  static Future<void> withdraw(int requestId) => ServerApi.call('withdrawApplication', {'requestId': '$requestId'});

  static Future<void> accept(String requestId, String helperUid) =>
      ServerApi.call('acceptApplication', {'requestId': requestId, 'helperUid': helperUid});

  static Future<void> reject(String requestId, String helperUid) =>
      ServerApi.call('rejectApplication', {'requestId': requestId, 'helperUid': helperUid});

  static Future<void> advance(String tradeId, String action) =>
      ServerApi.call('advanceTrade', {'tradeId': tradeId, 'action': action});

  static Future<void> cancelRequest(int requestId) => ServerApi.call('cancelRequest', {'requestId': '$requestId'});
}
