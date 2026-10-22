import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/core/compliance/safety_policy.dart';
import 'package:gyeomsa/features/profile/models/consents.dart';
import 'package:gyeomsa/features/profile/widgets/consent_widgets.dart';

/// A21 동의 관리 · A20 금지 품목 (앱 쪽 미리 확인)
void main() {
  final day1 = DateTime(2026, 10, 22, 9);
  final day2 = DateTime(2026, 10, 23, 9);

  group('동의', () {
    test('선택 항목은 기본 꺼짐, 필수 셋을 지금 버전으로 받아야 끝난다', () {
      const empty = Consents();
      expect(empty.isOn(Consents.location), isFalse);
      expect(empty.requiredDone, isFalse);
      final c = empty.apply({Consents.terms: true, Consents.privacy: true}, day1);
      expect(c.requiredDone, isFalse);
      final done = c.apply({Consents.age14: true}, day1);
      expect(done.requiredDone, isTrue);
      expect(done[Consents.terms]!.version, Consents.version);
      // 고르지 않은 선택 항목은 기록하지 않는다
      expect(done[Consents.marketing], isNull);
    });

    test('바뀐 항목만 새 시각으로 기록하고, 그대로인 항목은 그대로 둔다', () {
      final a = const Consents().apply({Consents.terms: true, Consents.location: true}, day1);
      final b = a.apply({Consents.terms: true, Consents.location: false}, day2);
      expect(b[Consents.terms]!.at, day1);
      expect(b[Consents.location]!.at, day2);
      expect(b.isOn(Consents.location), isFalse);
      expect(b.changedFrom(a), [Consents.location]);
      expect(a.apply({Consents.location: true}, day2).changedFrom(a), isEmpty);
    });

    test('혜택 알림을 끄면 야간 수신도 꺼지고, 혜택 알림 없이 야간만 켤 수 없다', () {
      final on = const Consents().apply({Consents.marketing: true, Consents.night: true}, day1);
      expect(on.isOn(Consents.night), isTrue);
      final off = on.apply({Consents.marketing: false}, day2);
      expect(off.isOn(Consents.night), isFalse);
      expect(off.changedFrom(on), containsAll([Consents.marketing, Consents.night]));
      expect(const Consents().apply({Consents.night: true}, day1).isOn(Consents.night), isFalse);
    });

    test('예전 버전 필수 동의는 다시 받아야 하고, 계정을 바꾸면 위치 설정만 남는다', () {
      final old = Consents.fromJson({
        'terms': {'on': true, 'v': '2020-01-01', 'at': '2020-01-01T00:00:00.000'},
        'privacy': {'on': true, 'v': '2020-01-01'},
        'age14': {'on': true, 'v': '2020-01-01'},
        'location': {'on': true, 'v': '2020-01-01'},
        'marketing': {'on': true, 'v': '2020-01-01'},
        'weird': {'on': 'yes'},
      });
      expect(old.requiredDone, isFalse);
      expect(old.hadOldRequired, isTrue);
      final again = old.apply({Consents.terms: true, Consents.privacy: true, Consents.age14: true}, day1);
      expect(again.requiredDone, isTrue);
      final device = again.forDevice();
      expect(device.isOn(Consents.location), isTrue);
      expect(device.isOn(Consents.terms), isFalse);
      expect(device.isOn(Consents.marketing), isFalse);
      // 저장 → 읽기 왕복
      expect(Consents.fromJson(again.toJson()).requiredDone, isTrue);
    });

    testWidgets('동의 목록: 전체 동의는 모두 켜고 끄며, 야간을 켜면 혜택 알림도 켠다', (tester) async {
      var values = <String, bool>{};
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: ConsentChecklist(values: values, onChanged: (v) => setState(() => values = v)),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('전체 동의'));
      await tester.pump();
      expect(Consents.items.every((i) => values[i.key] == true), isTrue);
      await tester.tap(find.text('전체 동의'));
      await tester.pump();
      expect(values.values.every((v) => !v), isTrue);
      await tester.ensureVisible(find.text(Consents.item(Consents.night).title));
      await tester.tap(find.text(Consents.item(Consents.night).title));
      await tester.pump();
      expect(values[Consents.night], isTrue);
      expect(values[Consents.marketing], isTrue);
      expect(find.text('보기'), findsNWidgets(3)); // 필수 셋만 내용 보기
    });
  });

  group('금지 품목', () {
    test('띄어쓰기와 상관없이 찾고, 다른 낱말 속 짧은 말은 걸지 않는다', () {
      expect(SafetyPolicy.findBlocked('편의점 소주 2병'), '소주');
      expect(SafetyPolicy.findBlocked('감 기 약'), '감기약');
      for (final ok in ['기술 서적 반납', '식당 예약', '술집 앞 택배함', '약국 앞에서 만나요']) {
        expect(SafetyPolicy.findBlocked(ok), isNull, reason: ok);
      }
    });
  });
}
