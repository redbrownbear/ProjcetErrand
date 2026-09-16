import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/backend/backend.dart';
import '../models/pay_entry.dart';

/// 겸사페이 원장 저장소. `users/{uid}/payEntries/{id}`
///
/// 잔액을 따로 저장하는 필드는 **일부러 두지 않았다.** 지금은 앱이 기록을 쓰기
/// 때문에, 잔액까지 앱이 쓰면 마음먹은 사람이 숫자를 고칠 수 있다. 기록만 남겨
/// 두고 합계로 보여주면 최소한 앞뒤가 맞는지는 눈으로 확인된다.
///
/// 실제 돈이 오가기 시작하면 이 클래스는 통째로 서버로 옮겨야 한다.
/// 충전은 결제사(PG) 콜백이, 출금은 계좌 인증과 이체가, 잔액 갱신은
/// Cloud Functions의 트랜잭션이 맡아야 앱을 못 믿어도 숫자를 믿을 수 있다.
class PayRepository {
  final String uid;
  const PayRepository(this.uid);

  CollectionReference<Map<String, dynamic>> get _col => Backend.users.doc(uid).collection('payEntries');

  Future<List<PayEntry>> load({int limit = 100}) => Backend.guard<List<PayEntry>>(() async {
        final snap = await _col.orderBy('at', descending: true).limit(limit).get();
        final out = <PayEntry>[];
        for (final d in snap.docs) {
          final e = PayEntry.fromMap(d.id, d.data());
          if (e != null) out.add(e);
        }
        return out;
      }, const []);

  Future<void> add(PayEntry e) => Backend.push(() => _col.doc('${e.id}').set(e.toMap()));
}
