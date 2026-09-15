import 'package:flutter_test/flutter_test.dart';
import 'package:project_errand/core/storage/local_store.dart';
import 'package:project_errand/core/utils/formatters.dart';
import 'package:project_errand/features/errand/models/task_item.dart';
import 'package:project_errand/features/errand/models/trade.dart';

void main() {
  group('Trade', () {
    test('단계를 건너뛰거나 두 번 완료할 수 없다', () {
      var t = Trade.pending();
      expect(identical(t.advance('confirm'), t), isTrue);
      for (final a in ['accept', 'start', 'finish', 'confirm']) {
        t = t.advance(a);
      }
      expect(t.status, 'completed');
      expect(identical(t.advance('confirm'), t), isTrue);
      expect(identical(t.advance('cancel'), t), isTrue);
    });

    test('작업 시작 전에만 취소, 완료 확인에서 보완 요청 가능', () {
      expect(Trade.pending().advance('cancel').status, 'cancelled');
      expect(Trade.pending().advance('accept').advance('cancel').status, 'cancelled');
      final working = Trade('working', DateTime(2026));
      expect(working.canCancel, isFalse);
      expect(identical(working.advance('cancel'), working), isTrue);
      expect(Trade('confirmation', DateTime(2026)).advance('revise').status, 'working');
    });

    test('JSON 왕복, 알 수 없는 상태는 버린다', () {
      final t = Trade('matched', DateTime.utc(2026, 9, 10, 9));
      final back = Trade.fromJson(t.toJson())!;
      expect(back.status, 'matched');
      expect(back.updatedAt, t.updatedAt);
      expect(Trade.fromJson({'status': 'hacked', 'updatedAt': '2026-09-10'}), isNull);
      expect(Trade.fromJson('nope'), isNull);
    });
  });

  group('마감', () {
    final deadline = DateTime(2026, 9, 10, 18);
    final item = TaskItem(id: 1, mode: 'ask', title: 't', who: '나', desc: 'd', distM: null, deadline: deadline);

    test('마감 시각 정각부터 마감으로 본다', () {
      expect(item.isExpiredAt(deadline), isTrue);
      expect(item.isExpiredAt(deadline.subtract(const Duration(milliseconds: 1))), isFalse);
    });

    test('마감 정보가 없으면 지어내지 않는다', () {
      const seed = TaskItem(id: 2, mode: 'ask', title: 't', who: 'x', desc: 'd', distM: 300);
      expect(seed.isExpiredAt(DateTime(2100)), isFalse);
      expect(deadlineLabel(seed), '마감 시각 협의');
      expect(deadlineLabel(item), '9월 10일 18:00까지');
    });

    test('거리 미확인은 임의 거리 대신 미확인으로 표시하고 정렬 맨 뒤', () {
      expect(distLabel(item), '거리 미확인');
      expect(item.distSort, double.infinity);
    });
  });

  test('내가 올린 부탁은 거래 조건까지 JSON으로 보관된다', () {
    final it = TaskItem(
      id: 1757480000000, mode: 'ask', cat: 'buy', title: '커피 픽업', who: '나', desc: '아메리카노 2잔 부탁해요',
      distM: null, place: '서초역 1번 출구', deliveryPlace: '서초역 2번 출구', deadline: DateTime(2026, 9, 11, 9),
      budget: 9000, payment: 'reimburse', completion: '수령 후 확인', price: 3000, verified: false, rating: 0,
    );
    LocalStore.write('requests', [it.toJson()]);
    final back = TaskItem.fromJson(LocalStore.read<List<dynamic>>('requests', const []).single)!;
    expect(back.deliveryPlace, '서초역 2번 출구');
    expect(back.deadline, DateTime(2026, 9, 11, 9));
    expect(back.budget, 9000);
    expect(back.payment, 'reimburse');
    expect(back.distM, isNull);
    expect(back.verified, isFalse);
  });
}
