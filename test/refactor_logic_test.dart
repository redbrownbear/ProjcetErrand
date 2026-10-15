import 'package:flutter_test/flutter_test.dart';

import 'package:gyeomsa/features/benefits/data/partner_missions.dart';
import 'package:gyeomsa/features/benefits/models/mission_meta.dart';
import 'package:gyeomsa/features/benefits/services/mission_filter.dart';
import 'package:gyeomsa/features/errand/models/task_item.dart';
import 'package:gyeomsa/features/errand/repositories/errand_repository.dart';
import 'package:gyeomsa/features/errand/screens/post/request_form.dart';
import 'package:gyeomsa/features/errand/services/nearby_query.dart';

/// 화면에서 떼어 낸 계산들. 화면 없이 조건과 결과만 본다.
void main() {
  const scope = '서울 서초구';

  group('NearbyQuery — 지금 내 주변 부탁', () {
    final items = LocalErrandRepository().fetchSeedItems();

    test('동네 부탁만, 지역 안에서, 반경 안의 것만 나온다', () {
      final list = const NearbyQuery(radius: 1).apply(items, scope);
      expect(list, isNotEmpty);
      for (final it in list) {
        expect(it.mode, 'ask');
        expect(it.region, scope);
        expect(it.distM, lessThanOrEqualTo(1000));
      }
    });

    test('정렬 — 가까운순과 금액 높은순', () {
      final near = const NearbyQuery(radius: 30).apply(items, scope);
      final pay = const NearbyQuery(radius: 30, sort: 'price').apply(items, scope);
      for (var i = 1; i < near.length; i++) {
        expect(near[i].distSort, greaterThanOrEqualTo(near[i - 1].distSort));
      }
      for (var i = 1; i < pay.length; i++) {
        expect(pay[i].price, lessThanOrEqualTo(pay[i - 1].price));
      }
    });

    test('방금 올린 내 부탁은 좌표가 없어도 맨 앞에 나온다', () {
      const mine = TaskItem(
        id: 999999,
        mode: 'ask',
        cat: 'buy',
        title: '방금 올린 부탁',
        region: scope,
        distM: null,
        mins: 10,
        desc: '',
        price: 5000,
        who: '나',
        sample: false,
        mine: true,
      );
      final list = const NearbyQuery(radius: 0.5).apply([...items, mine], scope);
      expect(list.first.id, mine.id);
    });

    test('종류·30분 조건과 반경 문구', () {
      final list = const NearbyQuery(radius: 30, cat: 'buy', shortOnly: true).apply(items, scope);
      for (final it in list) {
        expect(it.cat, 'buy');
        expect(it.mins, inInclusiveRange(1, 30));
      }
      expect(const NearbyQuery(radius: 0.5).radiusLabel, '500m');
      expect(const NearbyQuery(radius: 3).radiusLabel, '3km');
    });
  });

  group('MissionFilter — 참여할 미션', () {
    bool none(_) => false;

    test('구매 없음 · 3분 이내 · 종류 조건', () {
      final free = const MissionFilter(freeOnly: true).apply(partnerMissions, isDone: none, isActive: none);
      expect(free.every((m) => m.isFree), isTrue);

      final short = const MissionFilter(shortOnly: true).apply(partnerMissions, isDone: none, isActive: none);
      expect(short.every((m) => m.minutes <= 3), isTrue);

      final research = const MissionFilter(cat: 'research').apply(partnerMissions, isDone: none, isActive: none);
      expect(research, isNotEmpty);
      expect(research.every((m) => m.cat == 'research' || m.cat == 'consult'), isTrue);
    });

    test('적립을 끝낸 미션은 정렬과 무관하게 맨 아래로 간다', () {
      final top = partnerMissions.reduce((a, b) => a.points >= b.points ? a : b);
      final list = const MissionFilter(sort: 'point').apply(partnerMissions, isDone: (m) => m.id == top.id, isActive: none);
      expect(list.last.id, top.id);
      expect(list.first.points, greaterThanOrEqualTo(list[1].points));
    });

    test('상태 탭 — 참여 중만', () {
      final first = partnerMissions.first;
      final list = const MissionFilter(status: MissionStatus.active)
          .apply(partnerMissions, isDone: none, isActive: (m) => m.id == first.id);
      expect(list.map((m) => m.id), [first.id]);
    });
  });

  group('RequestForm — 부탁 쓰기', () {
    RequestForm filled() {
      final f = RequestForm.restore(kind: 'ask', cat: 'pickup');
      f.title.text = '택배 받아 주세요';
      f.desc.text = '경비실에 맡겨진 택배를 문 앞까지 부탁드려요';
      f.place.text = '서초역 1번 출구';
      f.delivery.text = '같은 장소';
      f.deadline = DateTime.now().add(const Duration(hours: 3));
      f.completion.text = '수령 확인 메시지';
      f.price = 5000;
      f.payment = 'none';
      f.hot = false;
      return f;
    }

    test('단계마다 필요한 값이 채워져야 넘어간다', () {
      final f = RequestForm.restore(kind: 'ask');
      f.title.text = '';
      f.desc.text = '';
      expect(f.readyAt(0), isFalse);
      expect(f.hintAt(0), contains('제목'));

      final ok = filled();
      expect(ok.ready, isTrue);
      expect(ok.hintAt(2), isNull);

      ok.deadline = DateTime.now().subtract(const Duration(hours: 1));
      expect(ok.readyAt(1), isFalse, reason: '지난 마감 시각은 통과하지 못한다');
    });

    test('등록 값 — 고른 종류와 다듬은 글자가 그대로 들어간다', () {
      final data = filled().toData();
      expect(data.mode, 'ask');
      expect(data.cat, 'pickup');
      expect(data.price, 5000);
      expect(data.country, isNull);
      expect(data.budget, 0);
    });

    test('해외 부탁은 최소 사례비 아래로 내려가지 않고 나라·도시가 붙는다', () {
      final f = filled()
        ..setKind('sea')
        ..cc = 'jp'
        ..city = '도쿄';
      expect(f.price, greaterThanOrEqualTo(f.floor));
      final data = f.toData();
      expect(data.country, '일본 도쿄');
      expect(data.mins, 0);
    });

    test('물품 구매비를 받기로 하면 예산이 있어야 한다', () {
      final f = filled()..payment = 'reimburse';
      expect(f.readyAt(2), isFalse);
      f.budgetText.text = '15000';
      expect(f.readyAt(2), isTrue);
      expect(f.toData().budget, 15000);
    });
  });
}
