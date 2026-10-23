import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/live_query.dart';

/// 내 동선에 맞는 부탁 한 건 (`users/{uid}/matches/{requestId}`, 서버가 만든다 — A13)
class RouteMatch {
  final int requestId;
  final String title;
  final int price;
  final String area;
  final String routeName;

  /// 동선에서 들렀다 가는 데 더 걸리는 시간(분, 직선거리 어림)
  final int extraMin;
  final DateTime? deadline;
  final DateTime createdAt;
  const RouteMatch({
    required this.requestId,
    required this.title,
    required this.price,
    required this.area,
    required this.routeName,
    required this.extraMin,
    this.deadline,
    required this.createdAt,
  });

  bool expiredAt(DateTime now) => deadline != null && deadline!.isBefore(now);

  static RouteMatch? fromDoc(String id, Map<String, dynamic> m) {
    final rid = int.tryParse(id);
    if (rid == null || m['title'] is! String) return null;
    final dl = m['deadline'], at = m['createdAt'];
    return RouteMatch(
      requestId: rid,
      title: m['title'] as String,
      price: m['price'] is int ? m['price'] as int : 0,
      area: m['area'] is String ? m['area'] as String : '',
      routeName: m['routeName'] is String ? m['routeName'] as String : '내 동선',
      extraMin: m['extraMin'] is int ? m['extraMin'] as int : 0,
      deadline: dl is Timestamp ? dl.toDate() : null,
      createdAt: at is Timestamp ? at.toDate() : DateTime.now(),
    );
  }
}

class MatchRepository {
  final String uid;
  const MatchRepository(this.uid);

  CollectionReference<Map<String, dynamic>> get _col => Backend.users.doc(uid).collection('matches');

  /// 최근 30건 중 마감이 안 지난 것
  Stream<List<RouteMatch>> watch() {
    if (!Backend.ready) return Stream<List<RouteMatch>>.value(const []);
    return _col
        .orderBy('createdAt', descending: true)
        .limit(30)
        .live((d) => RouteMatch.fromDoc(d.id, d.data()!), label: '동선 추천')
        .map((list) {
          // 마감은 시간이 지나며 바뀌니 문서를 읽을 때가 아니라 내보낼 때 거른다
          final now = DateTime.now();
          return [
            for (final m in list)
              if (!m.expiredAt(now)) m,
          ];
        });
  }

  /// 관심 없음 — 목록에서 지운다
  Future<void> dismiss(int requestId) => Backend.push(() => _col.doc('$requestId').delete());
}
