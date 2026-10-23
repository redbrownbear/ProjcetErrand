import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

typedef Doc = DocumentSnapshot<Map<String, dynamic>>;

/// Firestore 쿼리 구독을 화면용 목록으로 바꾸는 공용 길.
///
/// - 스냅샷마다 문서 전체를 다시 만들지 않고 **바뀐 문서(`docChanges`)만** 다시 만든다.
///   채팅 한 줄에 거래 문서 하나가 바뀌어도 나머지 문서의 객체는 그대로 재사용된다.
/// - 바뀐 문서가 없는 스냅샷은 내보내지 않는다 — 받는 쪽이 같은 목록으로 화면 전체를 다시 그리지 않게.
/// - 실패(색인 없음 · 권한)는 [label]과 함께 로그만 남기고 삼킨다. 화면은 마지막 값(또는 빈 값)으로 계속 돈다.
extension LiveQuery on Query<Map<String, dynamic>> {
  /// [parse]가 null을 돌려주면 그 문서는 목록에서 뺀다. 순서는 쿼리 순서 그대로.
  Stream<List<T>> live<T extends Object>(T? Function(Doc d) parse, {required String label}) =>
      liveFrom(snapshots(), parse, label: label);
}

/// [LiveQuery.live]의 본체. 테스트가 가짜 스냅샷을 넣을 수 있게 따로 둔다.
Stream<List<T>> liveFrom<T extends Object>(
  Stream<QuerySnapshot<Map<String, dynamic>>> source,
  T? Function(Doc d) parse, {
  required String label,
}) {
  // 구독마다 따로 기억한다(같은 스트림을 두 번 들어도 섞이지 않게)
  return Stream<List<T>>.multi((out) {
    final cache = <String, T?>{};
    var sent = false;
    T? read(Doc d) => d.data() == null ? null : parse(d);
    final sub = source.listen(
      (snap) {
        final changes = snap.docChanges;
        if (sent && changes.isEmpty) return;
        for (final c in changes) {
          final key = c.doc.reference.path;
          if (c.type == DocumentChangeType.removed) {
            cache.remove(key);
          } else {
            cache[key] = read(c.doc);
          }
        }
        final list = <T>[];
        for (final d in snap.docs) {
          final key = d.reference.path;
          final v = cache.containsKey(key) ? cache[key] : (cache[key] = read(d));
          if (v != null) list.add(v);
        }
        sent = true;
        out.add(list);
      },
      onError: (Object e) => debugPrint('$label 구독 실패: $e'),
      onDone: out.close,
    );
    out
      ..onCancel = sub.cancel
      ..onPause = sub.pause
      ..onResume = sub.resume;
  });
}
