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

  /// 새 부탁을 올린다. 공개 문서에는 대략적인 지역(`region`·`area`)만 두고,
  /// 정확한 장소·좌표는 글쓴이와 수락된 수행자만 읽는 `private/detail`에 따로 쓴다(보안 규칙 v2).
  Future<void> add(TaskItem it) => Backend.push(() async {
    final ref = Backend.requests.doc('${it.id}');
    await ref.set({
      ...toMap(it),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final detail = privateDetail(it);
    if (detail.isNotEmpty) await ref.collection('private').doc('detail').set(detail);
  });

  /// 부탁 하나. 모집이 끝나 공개 목록에서 빠진 내 지원·거래의 부탁을 채울 때 쓴다.
  Future<TaskItem?> get(int id) => Backend.guard<TaskItem?>(() async {
    final d = await Backend.requests.doc('$id').get();
    final m = d.data();
    return m == null ? null : fromDoc(d.id, m);
  }, null);

  /// 가는 김에 접수 마감 켜기·끄기 (글쓴이만, 모집 중일 때 — 보안 규칙)
  Future<void> setClosed(int id, bool closed) =>
      Backend.requests.doc('$id').update({'closed': closed, 'updatedAt': FieldValue.serverTimestamp()}).timeout(Backend.timeout);

  /// 정확한 장소(`private/detail`). 글쓴이와 수락된 수행자만 읽을 수 있다(보안 규칙 v2). 없거나 못 읽으면 null.
  Future<Map<String, dynamic>?> getPrivate(int id) => Backend.guard<Map<String, dynamic>?>(() async {
    final d = await Backend.requests.doc('$id').collection('private').doc('detail').get();
    return d.data();
  }, null);

  // 모집 취소·마감은 앱이 직접 쓰지 않는다 → 서버 함수 cancelRequest · expireRequests

  // ── 변환 ────────────────────────────────────────────────────────────────

  /// 공개 문서. 보안 규칙 v2의 필드 목록(`requestEditable`)과 맞춰야 한다 — 목록 밖 필드가 있으면 저장이 거부된다.
  static Map<String, Object?> toMap(TaskItem it) => {
    'ownerUid': it.ownerUid,
    'who': it.who,
    'mode': it.mode,
    'cat': it.cat,
    'title': it.title,
    'desc': it.desc,
    'region': it.region,
    'area': it.region,
    'country': it.country,
    'cc': it.cc,
    'city': it.city,
    'mins': it.mins,
    'price': it.price,
    'budget': it.budget,
    'payment': it.payment,
    'completion': it.completion,
    'hot': it.hot,
    'extra': it.extra,
    // 가는 김에(제가 가요) 일정. 핀은 '가는 곳'이라 공개한다(동네 부탁 좌표는 private/detail)
    if (it.isGoing) ...{
      'goAt': it.goAt == null ? null : Timestamp.fromDate(it.goAt!),
      'capacity': it.capacity > 0 ? it.capacity : 3,
      'kinds': it.kinds,
      'closed': it.closed,
      'pinLat': it.lat,
      'pinLng': it.lng,
    },
    'deadline': it.deadline == null ? null : Timestamp.fromDate(it.deadline!),
  };

  /// 정확한 위치. 값이 있는 것만.
  static Map<String, Object?> privateDetail(TaskItem it) => {
    if (it.place != null) 'place': it.place,
    if (it.deliveryPlace != null) 'deliveryPlace': it.deliveryPlace,
    if (it.lat != null) 'lat': it.lat,
    if (it.lng != null) 'lng': it.lng,
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
      lat: dbl('lat') ?? dbl('pinLat'),
      lng: dbl('lng') ?? dbl('pinLng'),
      distM: dbl('distM'),
      mins: whole('mins'),
      price: whole('price'),
      budget: whole('budget'),
      payment: str('payment'),
      completion: str('completion'),
      who: str('who') ?? '이웃',
      // 서버에서 내려온 글은 아직 후기·인증 기록이 없다. 없는 신뢰 지표를 지어내지 않는다.
      rating: 0,
      reviews: 0,
      deals: 0,
      resp: 0,
      verified: false,
      hot: m['hot'] == true,
      extra: str('extra'),
      commentCount: whole('commentCount'),
      goAt: m['goAt'] is Timestamp ? (m['goAt'] as Timestamp).toDate() : null,
      capacity: whole('capacity'),
      acceptedCount: whole('acceptedCount'),
      kinds: [if (m['kinds'] is List) ...(m['kinds'] as List).whereType<String>()],
      closed: m['closed'] == true,
      deadline: deadline is Timestamp ? deadline.toDate() : DateTime.tryParse('$deadline'),
      sample: false,
      ownerUid: str('ownerUid'),
    );
  }
}
