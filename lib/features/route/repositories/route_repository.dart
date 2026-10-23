import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/live_query.dart';
import '../../../core/backend/server_api.dart';
import '../models/commute_route.dart';

/// 내 정기 동선 (`users/{uid}/routes`, 본인만 읽고 쓴다). 매칭 격자는 서버가 붙인다.
class RouteRepository {
  final String uid;
  const RouteRepository(this.uid);

  CollectionReference<Map<String, dynamic>> get _col => Backend.users.doc(uid).collection('routes');

  Stream<List<CommuteRoute>> watch() {
    if (!Backend.ready) return Stream<List<CommuteRoute>>.value(const []);
    return _col.orderBy('createdAt').live((d) => CommuteRoute.fromDoc(d.id, d.data()!), label: '동선');
  }

  /// 새 동선(id 없음) 또는 고친 동선. 실패하면 [ServerException]
  Future<void> save(CommuteRoute r, {required int existing}) async {
    final problem = r.problem;
    if (problem != null) throw ServerException(problem);
    if (!Backend.ready) throw const ServerException('서버에 연결되지 않아 지금은 저장할 수 없어요.');
    final now = FieldValue.serverTimestamp();
    try {
      if (r.id.isEmpty) {
        if (existing >= CommuteRoute.maxRoutes) throw const ServerException('동선은 ${CommuteRoute.maxRoutes}개까지 등록할 수 있어요.');
        await _col.add({...r.toMap(), 'createdAt': now, 'updatedAt': now}).timeout(Backend.timeout);
      } else {
        await _col.doc(r.id).update({...r.toMap(), 'updatedAt': now}).timeout(Backend.timeout);
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      debugPrint('동선 저장 실패: $e');
      throw const ServerException('동선을 저장하지 못했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  Future<void> setActive(String id, bool on) =>
      Backend.push(() => _col.doc(id).update({'active': on, 'updatedAt': FieldValue.serverTimestamp()}));

  /// 지우면 서버가 붙인 격자도 문서와 함께 사라진다
  Future<void> delete(String id) => Backend.push(() => _col.doc(id).delete());
}
