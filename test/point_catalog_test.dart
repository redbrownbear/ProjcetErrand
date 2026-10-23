import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/features/benefits/data/reward_products.dart';
import 'package:gyeomsa/features/benefits/models/attendance.dart';
import 'package:gyeomsa/features/benefits/repositories/point_repository.dart';

/// 포인트 서버 표(functions/src/points/catalog.json)가 앱 표와 같은지 본다(B09).
/// 한쪽만 고치면 화면에 보이는 금액과 서버가 주는 금액이 달라진다.
void main() {
  final catalog = jsonDecode(File('functions/src/points/catalog.json').readAsStringSync()) as Map<String, dynamic>;

  test('출석 규칙이 서버와 같다', () {
    final a = catalog['attend'] as Map<String, dynamic>;
    expect(a['daily'], AttendRules.daily);
    expect(a['streakEvery'], AttendRules.streakEvery);
    expect(a['streakBonus'], AttendRules.streakBonus);
    expect(a['monthTarget'], AttendRules.monthTarget);
    expect(a['monthBonus'], AttendRules.monthBonus);
  });

  test('교환 상품 · 포인트가 서버와 같다', () {
    final server = {
      for (final p in (catalog['products'] as List).cast<Map<String, dynamic>>()) p['id']: [p['brand'], p['name'], p['points']],
    };
    final app = {for (final p in rewardProducts) p.id: [p.brand, p.name, p.points]};
    expect(server, app);
  });

  test('적립 결과 — 빠진 값은 0', () {
    final r = EarnResult.fromMap({'key': 'benefit:attend:2026-10-23', 'amount': 11, 'balance': 120});
    expect((r.key, r.amount, r.balance), ('benefit:attend:2026-10-23', 11, 120));
    final empty = EarnResult.fromMap({});
    expect((empty.amount, empty.balance), (0, 0));
  });
}
