import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/live_query.dart';
import '../data/categories.dart';
import '../data/countries.dart';

/// 최근 완료된 거래 한 건(`activity/{tradeId}`, A23). 서버가 거래 완료 때 동네 · 종류 · 시각만 쓴다.
/// 누가 · 무엇을 · 얼마에는 들어 있지 않다.
class DoneActivity {
  final String id;

  /// ask · going · sea
  final String mode;
  final String cat;
  final String area;
  final String cc;
  final DateTime at;
  const DoneActivity({required this.id, required this.mode, this.cat = '', this.area = '', this.cc = '', required this.at});

  bool get abroad => mode == 'sea' || cc.isNotEmpty;

  /// '방배동 · 받아오기 부탁이 끝났어요'
  String get line {
    final where = abroad ? countryOf(cc).name : area;
    final what = mode == 'going' ? '가는 김에 부탁' : '${cat.isEmpty ? '' : '${catOf(cat).label} '}부탁';
    return [if (where.isNotEmpty) where, '$what이 끝났어요'].join(' · ');
  }

  static DoneActivity? fromDoc(String id, Map<String, dynamic> m) {
    final at = m['at'];
    if (m['kind'] != 'done' || at is! Timestamp) return null;
    String s(String k) => m[k] is String ? m[k] as String : '';
    return DoneActivity(
      id: id,
      mode: s('mode').isEmpty ? 'ask' : s('mode'),
      cat: s('cat'),
      area: s('area'),
      cc: s('cc'),
      at: at.toDate(),
    );
  }
}

/// 공개 완료 기록 구독(누구나 읽기 — 보안 규칙)
class ActivityRepository {
  const ActivityRepository();

  Stream<List<DoneActivity>> watchRecent({int limit = 20}) {
    if (!Backend.ready) return Stream<List<DoneActivity>>.value(const []);
    return Backend.db
        .collection('activity')
        .orderBy('at', descending: true)
        .limit(limit)
        .live((d) => DoneActivity.fromDoc(d.id, d.data()!), label: '완료 기록');
  }
}
