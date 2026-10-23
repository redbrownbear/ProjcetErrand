// 가짜 스냅샷을 만들려고 Firestore의 @sealed 클래스를 구현한다(테스트에서만)
// ignore_for_file: subtype_of_sealed_class
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/core/backend/live_query.dart';

typedef _M = Map<String, dynamic>;

class _Ref implements DocumentReference<_M> {
  @override
  final String id;
  _Ref(this.id);
  @override
  String get path => 'c/$id';
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Doc implements QueryDocumentSnapshot<_M> {
  @override
  final String id;
  final _M m;
  _Doc(this.id, this.m);
  @override
  DocumentReference<_M> get reference => _Ref(id);
  @override
  _M data() => m;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Change implements DocumentChange<_M> {
  @override
  final DocumentChangeType type;
  @override
  final DocumentSnapshot<_M> doc;
  _Change(this.type, this.doc);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Snap implements QuerySnapshot<_M> {
  @override
  final List<QueryDocumentSnapshot<_M>> docs;
  @override
  final List<DocumentChange<_M>> docChanges;
  _Snap(this.docs, this.docChanges);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Item {
  final String id;
  final int n;
  _Item(this.id, this.n);
}

/// 실시간 구독 공용 길(live_query): 바뀐 문서만 다시 만들고, 바뀐 게 없으면 내보내지 않는다
void main() {
  test('바뀐 문서만 다시 만들고 나머지는 같은 객체를 쓴다 · 빈 변경은 내보내지 않는다', () async {
    final source = StreamController<QuerySnapshot<_M>>();
    var parsed = 0;
    final out = <List<_Item>>[];
    final sub = liveFrom<_Item>(source.stream, (d) {
      parsed++;
      final n = d.data()!['n'] as int;
      return n < 0 ? null : _Item(d.id, n); // 음수는 목록에서 뺀다
    }, label: '테스트').listen(out.add);

    final a = _Doc('a', {'n': 1}), b = _Doc('b', {'n': 2}), c = _Doc('c', {'n': -1});
    source.add(_Snap([a, b, c], [
      _Change(DocumentChangeType.added, a),
      _Change(DocumentChangeType.added, b),
      _Change(DocumentChangeType.added, c),
    ]));
    await pumpEventQueue();
    expect(out.single.map((i) => i.n), [1, 2]);
    expect(parsed, 3);

    // b만 바뀜 → b만 다시 만든다. a는 같은 객체
    final b2 = _Doc('b', {'n': 20});
    source.add(_Snap([a, b2, c], [_Change(DocumentChangeType.modified, b2)]));
    await pumpEventQueue();
    expect(out.last.map((i) => i.n), [1, 20]);
    expect(parsed, 4);
    expect(identical(out[0][0], out[1][0]), isTrue);

    // 바뀐 문서가 없으면 내보내지 않는다
    source.add(_Snap([a, b2, c], []));
    await pumpEventQueue();
    expect(out.length, 2);

    // a가 빠짐 · 순서는 쿼리 순서
    source.add(_Snap([b2, c], [_Change(DocumentChangeType.removed, a)]));
    await pumpEventQueue();
    expect(out.last.map((i) => i.id), ['b']);
    expect(parsed, 4);

    await sub.cancel();
    await source.close();
  });

  test('첫 스냅샷이 비어 있어도 한 번은 내보낸다 · 오류는 삼킨다', () async {
    final source = StreamController<QuerySnapshot<_M>>();
    final out = <List<_Item>>[];
    final sub = liveFrom<_Item>(source.stream, (d) => _Item(d.id, 0), label: '테스트').listen(out.add);
    source.add(_Snap(const [], const []));
    source.addError(StateError('권한 없음'));
    await pumpEventQueue();
    expect(out, [isEmpty]);
    await sub.cancel();
    await source.close();
  });
}
