import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/backend/backend.dart';
import '../models/task_item.dart';

/// 공개 부탁글(`requests/{id}`)을 읽고 쓴다.
///
/// 문서 id는 [TaskItem.id]를 문자열로 쓴다(밀리초 타임스탬프). 같은 사람이 같은
/// 밀리초에 두 번 올릴 일이 없고, 로컬에 있던 글을 서버로 올릴 때도 id가 그대로라
/// 중복이 생기지 않는다.
///
/// 시드 예시 데이터는 **서버에 올리지 않는다.** 화면을 채우는 용도일 뿐이고,
/// 올려 두면 다른 사용자 눈에 진짜 모집 글처럼 보이기 때문이다.
class RequestRepository {
  const RequestRepository();

  /// 모집 중인 부탁을 최신순으로 구독한다. 서버가 없으면 빈 목록만 흘린다.
  Stream<List<TaskItem>> watchOpen({int limit = 200}) {
    if (!Backend.ready) return Stream<List<TaskItem>>.value(const []);
    return Backend.requests
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
          final out = <TaskItem>[];
          for (final d in snap.docs) {
            final item = fromDoc(d.id, d.data());
            if (item != null) out.add(item);
          }
          return out;
        })
        // 색인이 아직 없거나 권한이 막혔을 때. 화면은 예시 데이터로 계속 돈다.
        .handleError((Object e) => debugPrint('부탁 목록 구독 실패: $e'));
  }

  Future<void> add(TaskItem it) => Backend.push(
        () => Backend.requests.doc('${it.id}').set({
          ...toMap(it),
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );

  /// 모집을 닫는다(삭제하지 않는다 — 지원자 쪽 기록이 남아야 하므로).
  Future<void> close(int id) => Backend.push(
        () => Backend.requests.doc('$id').set(
          {'status': 'closed', 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        ),
      );

  // ── 변환 ────────────────────────────────────────────────────────────────

  static Map<String, Object?> toMap(TaskItem it) => {
        'ownerUid': it.ownerUid,
        'who': it.who,
        'mode': it.mode,
        'cat': it.cat,
        'title': it.title,
        'desc': it.desc,
        'region': it.region,
        'place': it.place,
        'deliveryPlace': it.deliveryPlace,
        'country': it.country,
        'cc': it.cc,
        'city': it.city,
        'lat': it.lat,
        'lng': it.lng,
        'distM': it.distM,
        'mins': it.mins,
        'price': it.price,
        'budget': it.budget,
        'payment': it.payment,
        'completion': it.completion,
        'hot': it.hot,
        'deadline': it.deadline == null ? null : Timestamp.fromDate(it.deadline!),
      };

  static TaskItem? fromDoc(String docId, Map<String, dynamic> m) {
    final id = int.tryParse(docId);
    final mode = m['mode'], title = m['title'], desc = m['desc'];
    if (id == null || mode is! String || title is! String || desc is! String) return null;

    String? str(String k) => m[k] is String && (m[k] as String).isNotEmpty ? m[k] as String : null;
    int whole(String k) => m[k] is int ? m[k] as int : 0;
    double? dbl(String k) => m[k] is num ? (m[k] as num).toDouble() : null;
    final deadline = m['deadline'];

    return TaskItem(
      id: id,
      mode: mode,
      cat: str('cat') ?? 'etc',
      title: title,
      desc: desc,
      region: str('region'),
      place: str('place'),
      deliveryPlace: str('deliveryPlace'),
      country: str('country'),
      cc: str('cc'),
      city: str('city'),
      lat: dbl('lat'),
      lng: dbl('lng'),
      distM: dbl('distM'),
      mins: whole('mins'),
      price: whole('price'),
      budget: whole('budget'),
      payment: str('payment'),
      completion: str('completion'),
      who: str('who') ?? '이웃',
      // 서버에서 내려온 글은 아직 후기·인증 기록이 없다. 없는 신뢰 지표를 지어내지 않는다.
      rating: 0, reviews: 0, deals: 0, resp: 0, verified: false,
      hot: m['hot'] == true,
      deadline: deadline is Timestamp ? deadline.toDate() : DateTime.tryParse('$deadline'),
      sample: false,
      ownerUid: str('ownerUid'),
    );
  }
}
