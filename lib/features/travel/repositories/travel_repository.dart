import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/live_query.dart';
import '../../../core/backend/server_api.dart';
import '../models/travel_plan.dart';

/// 내 여행 · 출국 일정 (`users/{uid}/travels`, 본인만 읽고 쓴다 — 보안 규칙).
class TravelRepository {
  final String uid;
  const TravelRepository(this.uid);

  CollectionReference<Map<String, dynamic>> get _col => Backend.users.doc(uid).collection('travels');

  Stream<List<TravelPlan>> watch() {
    if (!Backend.ready) return Stream<List<TravelPlan>>.value(const []);
    return _col.live((d) => TravelPlan.fromDoc(d.id, d.data()!), label: '여행 일정');
  }

  /// 새 일정(id 없음) 또는 고친 일정. 실패하면 [ServerException]
  Future<void> save(TravelPlan p, {required int existing, DateTime? today}) async {
    final problem = p.problemOn(today ?? DateTime.now(), isNew: p.id.isEmpty);
    if (problem != null) throw ServerException(problem);
    if (!Backend.ready) throw const ServerException('서버에 연결되지 않아 지금은 저장할 수 없어요.');
    final now = FieldValue.serverTimestamp();
    try {
      if (p.id.isEmpty) {
        if (existing >= TravelPlan.maxPlans) throw const ServerException('여행 일정은 ${TravelPlan.maxPlans}개까지 적을 수 있어요.');
        await _col.add({...p.toMap(), 'createdAt': now, 'updatedAt': now}).timeout(Backend.timeout);
      } else {
        await _col.doc(p.id).update({...p.toMap(), 'updatedAt': now}).timeout(Backend.timeout);
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      debugPrint('여행 일정 저장 실패: $e');
      throw const ServerException('일정을 저장하지 못했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  Future<void> delete(String id) => Backend.push(() => _col.doc(id).delete());
}
