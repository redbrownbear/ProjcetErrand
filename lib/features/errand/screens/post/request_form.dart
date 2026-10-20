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

  /// ask(동네 부탁) | sea(해외 사다주기) | going(가는 김에 · 제가 가요)
  String kind = 'ask';

  /// trip이면 '가는 김에 · 가는 분 찾아요'(일반 부탁이 가는 김에에도 보인다)
  String? extra;

  /// 가는 김에(제가 가요)가 해외로 가는가
  bool abroad = false;

  /// 미리보기에 쓸 내 동네 이름
  String scope = '전국';
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
  RequestForm.restore({String? kind, String? cat, String? extra, String? scope}) {
    final d = LocalStore.read<Map<String, dynamic>>(_draftKey, const {});
    String s(String k, String fallback) => d[k] is String ? d[k] as String : fallback;
    int n(String k, int fallback) => d[k] is int ? d[k] as int : fallback;

    final k = kind ?? s('kind', this.kind);
    this.kind = const ['sea', 'going'].contains(k) ? k : 'ask';
    this.extra = kind != null ? extra : (d['extra'] is String ? d['extra'] as String : null);
    if (this.kind != 'ask') this.extra = null;
    abroad = d['abroad'] == true && this.kind == 'going';
    if (scope != null) this.scope = scope;
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
    'extra': extra,
    'abroad': abroad,
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

  /// 가는 김에 · 제가 가요 — 글쓴이가 도와주는 쪽
  bool get going => kind == 'going';

  /// '가는 김에'에서 연 글(제가 가요 · 가는 분 찾아요)
  bool get trip => going || extra == 'trip';

  /// 나라·도시를 고르는가 (해외 대행 · 해외로 가는 김에)
  bool get pickCountry => sea || (going && abroad);

  /// 사례비 하한. 0원짜리 부탁이 올라가지 않도록 동네 부탁도 최소 1,000원을 받는다.
  int get floor => sea ? seaMin : 1000;

  int get budget => int.tryParse(budgetText.text.trim()) ?? 0;

  bool get deadlineOk => deadline != null && deadline!.isAfter(DateTime.now());

  void setKind(String next) {
    kind = next;
    if (sea && price < seaMin) price = seaMin;
    if (!going) abroad = false;
  }

  /// 가는 김에: 제가 가요(going) ↔ 가는 분 찾아요(ask + trip)
  void setTripSide(bool goingSide) {
    kind = goingSide ? 'going' : 'ask';
    extra = goingSide ? null : 'trip';
    if (!goingSide) abroad = false;
  }

  /// 해외 부탁의 장소 표기 (예: '일본 도쿄'). 동네 부탁이면 null.
  String? get _countryLabel => pickCountry ? '${countryOf(cc).name}${city.isNotEmpty ? ' $city' : ''}' : null;

  int get _finalPrice => price < floor ? floor : price;

  // ── 검증 ────────────────────────────────────────────────────────────────

  /// [step]단계를 넘어갈 수 있는지
  bool readyAt(int step) => switch (step) {
    0 => title.text.trim().length >= 2 && desc.text.trim().length >= 10,
    1 =>
      place.text.trim().length >= 2 &&
          delivery.text.trim().length >= 2 &&
          deadlineOk &&
          (!pickCountry || (cc.isNotEmpty && city.isNotEmpty)),
    _ => price >= floor && completion.text.trim().length >= 5 && (going || payment == 'none' || budget > 0),
  };

  bool get ready => [for (var i = 0; i < stepCount; i++) readyAt(i)].every((ok) => ok);

  /// 넘어갈 수 없을 때 버튼 위에 띄울 안내. 넘어갈 수 있으면 null.
  String? hintAt(int step) {
    if (readyAt(step)) return null;
    switch (step) {
      case 0:
        return '제목은 2자, 설명은 10자 이상 적어주세요';
      case 1:
        if (going) return pickCountry ? '나라·도시, 들를 곳, 전달 장소와 언제까지 받을지 정해 주세요' : '가는 곳, 전달 장소와 언제까지 받을지 정해 주세요';
        return sea ? '도시, 구매 장소, 전달 장소와 앞으로의 마감 시각을 입력해 주세요' : '만날 장소, 전달 장소와 앞으로의 마감 시각을 입력해 주세요';
      default:
        if (price < floor) return '사례비를 ${nf(floor)}원 이상으로 정해주세요';
        if (!going && payment != 'none' && budget <= 0) return '물품 예산을 입력해 주세요';
        return '완료 확인 방법을 5자 이상 적어주세요';
    }
  }

  // ── 결과 ────────────────────────────────────────────────────────────────

  /// 등록할 값. 올릴 때는 [ready]일 때만 부른다(미리보기는 비어 있어도 된다).
  NewRequestData toData() => NewRequestData(
    mode: kind,
    cat: going ? 'buy' : cat,
    title: title.text.trim(),
    desc: desc.text.trim(),
    place: place.text.trim(),
    cc: pickCountry ? cc : null,
    city: pickCountry ? city : null,
    country: _countryLabel,
    // 소요시간은 받지 않는다 — '언제까지(마감 일시)'로 충분하다
    mins: 0,
    price: _finalPrice,
    hot: going ? false : hot,
    deadline: deadline,
    deliveryPlace: delivery.text.trim(),
    budget: (going || payment == 'none') ? 0 : budget,
    payment: going ? 'none' : payment,
    completion: completion.text.trim(),
    extra: kind == 'ask' ? extra : null,
  );

  /// 마지막 단계의 '이렇게 올라가요' 미리보기 — 실제로 올라가는 글과 같은 함수([NewRequestData.toItem])로 만든다
  TaskItem preview() {
    final d = toData();
    final empty = d.title.isEmpty;
    return NewRequestData(
      mode: d.mode,
      cat: d.cat,
      title: empty ? '제목을 입력하세요' : d.title,
      desc: d.desc,
      place: d.place,
      cc: d.cc,
      city: d.city,
      country: d.country,
      mins: d.mins,
      price: d.price,
      hot: d.hot,
      deadline: d.deadline,
      deliveryPlace: d.deliveryPlace,
      budget: d.budget,
      payment: d.payment,
      completion: d.completion,
      extra: d.extra,
    ).toItem(id: -1, scope: scope, who: '나');
  }
}
