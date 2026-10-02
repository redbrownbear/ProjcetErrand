import 'package:flutter/material.dart';

import '../../../../core/storage/local_store.dart';
import '../../../../core/utils/formatters.dart';
import '../../../benefits/data/point_rules.dart';
import '../../data/countries.dart';
import '../../models/new_request_data.dart';
import '../../models/task_item.dart';

/// 부탁 쓰기 폼의 값과 검증.
///
/// 작성 도중 닫았다가 다시 열어도 이어 쓸 수 있게 [save]로 이 기기에 임시 보관하고,
/// 등록에 성공하면 [clear]로 지운다.
class RequestForm {
  static const _draftKey = 'draft';
  static const stepCount = 3;

  /// ask(동네 부탁) | sea(해외 사다주기)
  String kind = 'ask';
  String cat = 'buy';
  String cc = 'jp';
  String city = '';
  int mins = 30;
  int price = 10000;
  bool hot = false;
  DateTime? deadline;

  /// none | prepaid | reimburse
  String payment = 'none';

  final title = TextEditingController();
  final desc = TextEditingController();
  final place = TextEditingController();
  final delivery = TextEditingController();
  final budgetText = TextEditingController();
  final completion = TextEditingController();

  /// 저장된 임시글에서 되살린다. [kind]·[cat]을 주면 임시글보다 그 값을 따른다.
  RequestForm.restore({String? kind, String? cat}) {
    final d = LocalStore.read<Map<String, dynamic>>(_draftKey, const {});
    String s(String k, String fallback) => d[k] is String ? d[k] as String : fallback;
    int n(String k, int fallback) => d[k] is int ? d[k] as int : fallback;

    this.kind = (kind ?? s('kind', this.kind)) == 'sea' ? 'sea' : 'ask';
    this.cat = cat ?? s('cat', this.cat);
    cc = s('cc', cc);
    city = s('city', city);
    mins = n('mins', mins);
    price = n('price', price);
    hot = d['hot'] == true;
    deadline = DateTime.tryParse(s('deadline', ''));
    if (paymentLabels.containsKey(d['payment'])) payment = d['payment'] as String;
    title.text = s('title', '');
    desc.text = s('desc', '');
    place.text = s('place', '');
    delivery.text = s('delivery', '');
    budgetText.text = s('budget', '');
    completion.text = s('completion', '');
  }

  void save() => LocalStore.write(_draftKey, {
    'kind': kind,
    'cat': cat,
    'cc': cc,
    'city': city,
    'mins': mins,
    'price': price,
    'hot': hot,
    'deadline': deadline?.toIso8601String(),
    'payment': payment,
    'title': title.text,
    'desc': desc.text,
    'place': place.text,
    'delivery': delivery.text,
    'budget': budgetText.text,
    'completion': completion.text,
  });

  void clear() => LocalStore.remove(_draftKey);

  void dispose() {
    for (final c in [title, desc, place, delivery, budgetText, completion]) {
      c.dispose();
    }
  }

  // ── 값 ──────────────────────────────────────────────────────────────────

  bool get sea => kind == 'sea';

  /// 사례비 하한. 0원짜리 부탁이 올라가지 않도록 동네 부탁도 최소 1,000원을 받는다.
  int get floor => sea ? seaMin : 1000;

  int get budget => int.tryParse(budgetText.text.trim()) ?? 0;

  bool get deadlineOk => deadline != null && deadline!.isAfter(DateTime.now());

  void setKind(String next) {
    kind = next;
    if (sea && price < seaMin) price = seaMin;
  }

  /// 해외 부탁의 장소 표기 (예: '일본 도쿄'). 동네 부탁이면 null.
  String? get _countryLabel => sea ? '${countryOf(cc).name}${city.isNotEmpty ? ' $city' : ''}' : null;

  int get _finalPrice => price < floor ? floor : price;

  // ── 검증 ────────────────────────────────────────────────────────────────

  /// [step]단계를 넘어갈 수 있는지
  bool readyAt(int step) => switch (step) {
    0 => title.text.trim().length >= 2 && desc.text.trim().length >= 10,
    1 =>
      place.text.trim().length >= 2 &&
          delivery.text.trim().length >= 2 &&
          deadlineOk &&
          (sea ? (cc.isNotEmpty && city.isNotEmpty) : mins > 0),
    _ => price >= floor && completion.text.trim().length >= 5 && (payment == 'none' || budget > 0),
  };

  bool get ready => [for (var i = 0; i < stepCount; i++) readyAt(i)].every((ok) => ok);

  /// 넘어갈 수 없을 때 버튼 위에 띄울 안내. 넘어갈 수 있으면 null.
  String? hintAt(int step) {
    if (readyAt(step)) return null;
    switch (step) {
      case 0:
        return '제목은 2자, 설명은 10자 이상 적어주세요';
      case 1:
        return sea ? '도시, 구매 장소, 전달 장소와 앞으로의 마감 시각을 입력해 주세요' : '만날 장소, 전달 장소와 앞으로의 마감 시각을 입력해 주세요';
      default:
        if (price < floor) return '사례비를 ${nf(floor)}원 이상으로 정해주세요';
        if (payment != 'none' && budget <= 0) return '물품 예산을 입력해 주세요';
        return '완료 확인 방법을 5자 이상 적어주세요';
    }
  }

  // ── 결과 ────────────────────────────────────────────────────────────────

  /// 등록할 값. [ready]일 때만 부른다.
  NewRequestData toData() => NewRequestData(
    mode: kind,
    cat: cat,
    title: title.text.trim(),
    desc: desc.text.trim(),
    place: place.text.trim(),
    cc: sea ? cc : null,
    city: sea ? city : null,
    country: _countryLabel,
    mins: sea ? 0 : mins,
    price: _finalPrice,
    hot: hot,
    deadline: deadline!,
    deliveryPlace: delivery.text.trim(),
    budget: payment == 'none' ? 0 : budget,
    payment: payment,
    completion: completion.text.trim(),
  );

  /// 마지막 단계의 '이렇게 올라가요' 미리보기
  TaskItem preview() {
    final where = place.text.trim();
    final to = delivery.text.trim();
    return TaskItem(
      id: -1,
      mode: kind,
      cat: cat,
      title: title.text.trim().isEmpty ? '제목을 입력하세요' : title.text.trim(),
      price: _finalPrice,
      hot: hot,
      distM: sea ? 9e9 : null,
      mins: sea ? 0 : mins,
      region: sea ? null : (where.isEmpty ? '우리 동네' : where),
      cc: sea ? cc : null,
      country: _countryLabel,
      place: where,
      who: '나',
      desc: desc.text.trim(),
      deadline: deadline,
      deliveryPlace: to.isEmpty ? null : to,
    );
  }
}
