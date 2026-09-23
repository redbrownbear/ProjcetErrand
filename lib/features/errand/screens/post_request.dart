import 'package:flutter/material.dart';

import '../../../core/storage/local_store.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../benefits/data/point_rules.dart';
import '../data/categories.dart';
import '../data/countries.dart';
import '../models/task_item.dart';
import '../widgets/task_card.dart';

class NewRequestData {
  final String mode, cat, title, desc, place;
  final String? cc, city, country;
  final int mins, price;
  final bool hot;
  final DateTime deadline;
  final String deliveryPlace;
  final int budget;
  final String payment; // none | prepaid | reimburse
  final String completion;
  const NewRequestData({
    required this.mode, required this.cat, required this.title, required this.desc,
    required this.place, this.cc, this.city, this.country, required this.mins, required this.price, required this.hot,
    required this.deadline, required this.deliveryPlace, required this.budget, required this.payment, required this.completion,
  });
}

class PostRequest extends StatefulWidget {
  final String scope;
  final void Function(NewRequestData) onSubmit;

  /// 앞선 갈래 화면([CreateChoiceScreen])에서 정해 온 종류 — ask | sea.
  /// 지정하면 저장된 임시글의 종류보다 이 값을 따른다.
  final String? initialKind;
  const PostRequest({super.key, required this.scope, required this.onSubmit, this.initialKind});
  @override
  State<PostRequest> createState() => _PostRequestState();
}

class _PostRequestState extends State<PostRequest> {
  static const _draftKey = 'draft';

  int step = 0;
  String kind = 'ask'; // ask | sea
  String cat = 'buy';
  String cc = 'jp';
  String city = '';
  int mins = 30;
  int price = 10000;
  bool hot = false;
  DateTime? deadline;
  String payment = 'none';
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final placeCtrl = TextEditingController();
  final deliveryCtrl = TextEditingController();
  final budgetCtrl = TextEditingController();
  final completionCtrl = TextEditingController();

  bool get sea => kind == 'sea';
  // 사례비 하한. 0원짜리 부탁이 올라가지 않도록 동네 부탁도 최소 1,000원을 받는다.
  int get floor => sea ? seaMin : 1000;
  int get budget => int.tryParse(budgetCtrl.text.trim()) ?? 0;
  bool get deadlineOk => deadline != null && deadline!.isAfter(DateTime.now());

  @override
  void initState() {
    super.initState();
    // 작성 도중 닫았다가 다시 열면 내용을 복원한다. 등록에 성공하면 지운다.
    final d = LocalStore.read<Map<String, dynamic>>(_draftKey, const {});
    String s(String k, String f) => d[k] is String ? d[k] as String : f;
    int n(String k, int f) => d[k] is int ? d[k] as int : f;
    kind = (widget.initialKind ?? s('kind', kind)) == 'sea' ? 'sea' : 'ask';
    cat = s('cat', cat);
    cc = s('cc', cc);
    city = s('city', city);
    mins = n('mins', mins);
    price = n('price', price);
    hot = d['hot'] == true;
    deadline = DateTime.tryParse(s('deadline', ''));
    payment = paymentLabels.containsKey(d['payment']) ? d['payment'] as String : payment;
    titleCtrl.text = s('title', '');
    descCtrl.text = s('desc', '');
    placeCtrl.text = s('place', '');
    deliveryCtrl.text = s('delivery', '');
    budgetCtrl.text = s('budget', '');
    completionCtrl.text = s('completion', '');
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _saveDraft();
  }

  void _saveDraft() => LocalStore.write(_draftKey, {
        'kind': kind, 'cat': cat, 'cc': cc, 'city': city, 'mins': mins, 'price': price, 'hot': hot,
        'deadline': deadline?.toIso8601String(), 'payment': payment,
        'title': titleCtrl.text, 'desc': descCtrl.text, 'place': placeCtrl.text, 'delivery': deliveryCtrl.text,
        'budget': budgetCtrl.text, 'completion': completionCtrl.text,
      });

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    placeCtrl.dispose();
    deliveryCtrl.dispose();
    budgetCtrl.dispose();
    completionCtrl.dispose();
    super.dispose();
  }

  void _setKind(String k) {
    setState(() {
      kind = k;
      if (k == 'sea' && price < seaMin) price = seaMin;
    });
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final init = (deadline != null && deadline!.isAfter(now)) ? deadline! : now.add(const Duration(hours: 2));
    final date = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(init));
    if (time == null || !mounted) return;
    setState(() => deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  /// 각 단계를 넘어갈 수 있는지.
  bool _readyAt(int s) {
    switch (s) {
      case 0:
        return titleCtrl.text.trim().length >= 2 && descCtrl.text.trim().length >= 10;
      case 1:
        final places = placeCtrl.text.trim().length >= 2 && deliveryCtrl.text.trim().length >= 2 && deadlineOk;
        return places && (sea ? (cc.isNotEmpty && city.isNotEmpty) : mins > 0);
      default:
        return price >= floor && completionCtrl.text.trim().length >= 5 && (payment == 'none' || budget > 0);
    }
  }

  /// 넘어갈 수 없을 때 버튼 위에 띄울 안내. 통과 상태면 null.
  String? _hintAt(int s) {
    if (_readyAt(s)) return null;
    switch (s) {
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

  void _submit() {
    if (!_readyAt(0) || !_readyAt(1) || !_readyAt(2)) return;
    final finalPrice = sea ? (price < seaMin ? seaMin : price) : price;
    final country = countryOf(cc);
    widget.onSubmit(NewRequestData(
      mode: kind, cat: cat, title: titleCtrl.text.trim(), desc: descCtrl.text.trim(),
      place: placeCtrl.text.trim(),
      cc: sea ? cc : null,
      city: sea ? city : null,
      country: sea ? '${country.flag} ${country.name}${city.isNotEmpty ? ' $city' : ''}' : null,
      mins: sea ? 0 : mins, price: finalPrice, hot: hot,
      deadline: deadline!, deliveryPlace: deliveryCtrl.text.trim(),
      budget: payment == 'none' ? 0 : budget, payment: payment, completion: completionCtrl.text.trim(),
    ));
    LocalStore.remove(_draftKey);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final canNext = _readyAt(step);
    final hint = _hintAt(step);
    return Material(
      color: AppColors.page,
      // edge-to-edge(targetSdk 36)에서 헤더가 상태바에, 본문 끝이 제스처바에 깔린다.
      child: SafeArea(child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
          decoration: const BoxDecoration(color: AppColors.card, border: Border(bottom: BorderSide(color: AppColors.line))),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: step == 0 ? () => Navigator.of(context).pop() : () => setState(() => step -= 1),
                    borderRadius: BorderRadius.circular(99),
                    child: Padding(padding: const EdgeInsets.all(2), child: Text(step == 0 ? '✕' : '‹', style: const TextStyle(fontSize: 20, color: AppColors.ink))),
                  ),
                  Text('${step + 1} / 3', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sub)),
                  const SizedBox(width: 20),
                ],
              ),
              const SizedBox(height: 14),
              Row(children: [
                for (int i = 0; i < 3; i++)
                  Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      decoration: BoxDecoration(color: i <= step ? AppColors.yellow : AppColors.line, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
              ]),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
              child: _stepBody(),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.line))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hint != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.sub, fontWeight: FontWeight.w600)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: !canNext ? null : (step < 2 ? () => setState(() => step += 1) : _submit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canNext ? AppColors.black : AppColors.line,
                      foregroundColor: canNext ? Colors.white : AppColors.faint,
                      disabledBackgroundColor: AppColors.line,
                      disabledForegroundColor: AppColors.faint,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(step < 2 ? '다음' : (hot ? '1,000원 결제하고 올리기' : '부탁 올리기'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ])),
    );
  }

  Widget _stepBody() {
    if (step == 0) return _step1();
    if (step == 1) return _step2();
    return _step3();
  }

  Widget _stepTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 18), child: Text(t, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.3)));
  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Text(t, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink)));
  Widget _hint(String t) => Padding(padding: const EdgeInsets.only(top: 6), child: Text(t, style: const TextStyle(fontSize: 12, color: AppColors.sub)));

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true, fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
      );

  Widget _step1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('무엇을 부탁할까요?'),
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text('작성 중인 내용은 이 기기에 자동 보관돼요.', style: TextStyle(fontSize: 12, color: AppColors.sub)),
        ),
        Row(children: [
          Expanded(child: _segBtn(!sea, () => _setKind('ask'), '🇰🇷 우리 동네', AppColors.yellow, AppColors.yellowSoft)),
          const SizedBox(width: 8),
          Expanded(child: _segBtn(sea, () => _setKind('sea'), '✈️ 해외 대행', AppColors.purple, AppColors.purpleSoft)),
        ]),
        const SizedBox(height: 20),
        if (sea)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(12)),
            child: Text('그 나라에 있는 이웃이 대신 사서 가져다줘요. 물건값은 영수증으로 정산, 사례비는 최소 ${nf(seaMin)}원부터예요.', style: const TextStyle(fontSize: 12, color: AppColors.purple, height: 1.55, fontWeight: FontWeight.w500)),
          ),
        if (!sea) ...[
          _label('카테고리'),
          GridView(
            // 비율이 아니라 픽셀로 높이를 고정한다. 비율을 쓰면 넓은 화면에서 셀이 같이 커진다.
            // 내용물 = 아이콘 22 + 간격 3 + 라벨 14 + 상하 여백
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 68,
              mainAxisSpacing: 8, crossAxisSpacing: 8,
              mainAxisExtent: 58,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cats.map((c) {
              final on = cat == c.k;
              return InkWell(
                onTap: () => setState(() => cat = c.k),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: on ? AppColors.yellowSoft : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: on ? AppColors.yellow : AppColors.line, width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c.icon, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 3),
                      Text(c.label, style: TextStyle(fontSize: 10.5, color: AppColors.ink, fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
        _label('제목'),
        TextField(
          controller: titleCtrl,
          maxLength: 40,
          onChanged: (_) => setState(() {}),
          decoration: _dec(sea ? '예: 돈키호테에서 곤약젤리 사다주세요' : '예: 성심당에서 빵 좀 사다 주세요'),
        ),
        _label('간단 설명'),
        TextField(
          controller: descCtrl,
          maxLines: 4,
          maxLength: 2000,
          onChanged: (_) => setState(() {}),
          decoration: _dec(sea ? '품목·수량, 예산, 귀국 예정일 등을 적어주세요' : '필요한 물건, 수량, 전달 방법을 알려주세요'),
        ),
      ],
    );
  }

  Widget _step2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('언제 어디서요?'),
        if (sea) ...[
          _label('어느 나라'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: countries.map((c) {
              final on = cc == c.cc;
              return InkWell(
                onTap: () => setState(() {
                  cc = c.cc;
                  city = '';
                }),
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: on ? AppColors.purpleSoft : AppColors.card,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: on ? AppColors.purple : AppColors.line, width: 1.5),
                  ),
                  child: Text('${c.flag} ${c.name}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _label('도시'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: countryOf(cc).cities.map((ci) {
              final on = city == ci;
              return InkWell(
                onTap: () => setState(() => city = city == ci ? '' : ci),
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: on ? AppColors.ink : AppColors.card,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: on ? AppColors.ink : AppColors.line, width: 1.5),
                  ),
                  child: Text(ci, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: on ? Colors.white : AppColors.ink)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _label('구매할 매장'),
          TextField(controller: placeCtrl, onChanged: (_) => setState(() {}), decoration: _dec('예: 시부야 돈키호테')),
        ] else ...[
          _label('만날 장소'),
          TextField(
            controller: placeCtrl,
            onChanged: (_) => setState(() {}),
            decoration: _dec('예: 역삼동 / 강남역 3번출구'),
          ),
          const SizedBox(height: 18),
          _label('예상 소요시간'),
          _qtyStepper('약 $mins분', () => setState(() => mins = (mins - 5).clamp(5, 999)), () => setState(() => mins += 5)),
          const SizedBox(height: 10),
          Row(children: [
            for (final m in [10, 20, 30, 60])
              Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: _quickBtn('$m분', mins == m, () => setState(() => mins = m)))),
          ]),
        ],
        const SizedBox(height: 18),
        _label('전달·완료 장소'),
        TextField(controller: deliveryCtrl, onChanged: (_) => setState(() {}), decoration: _dec('예: 서초역 2번 출구 / 같은 장소')),
        const SizedBox(height: 18),
        _label('완료해야 하는 날짜와 시각'),
        InkWell(
          onTap: _pickDeadline,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: deadline != null && !deadlineOk ? AppColors.red : AppColors.line)),
            child: Row(children: [
              const Text('🗓', style: TextStyle(fontSize: 17)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  deadline == null ? '날짜와 시각 선택' : '${dateTimeLabel(deadline!)}까지',
                  style: TextStyle(fontSize: 14.5, color: deadline == null ? AppColors.faint : AppColors.ink, fontWeight: deadline == null ? FontWeight.w500 : FontWeight.w700),
                ),
              ),
              const Text('›', style: TextStyle(fontSize: 18, color: AppColors.faint)),
            ]),
          ),
        ),
        _hint(deadline != null && !deadlineOk ? '이미 지난 시각이에요. 현재보다 이후 시각을 선택해 주세요.' : '현재보다 이후 시각을 선택해 주세요.'),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(12)),
          child: Text(sea ? '📍 매장 이름을 자세히 적어주세요.' : '📍 여러 사람이 오가는 공개된 장소가 좋아요.', style: const TextStyle(fontSize: 12, color: AppColors.yellowDeep, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _step3() {
    final quickPrices = sea ? [20000, 30000, 50000, 100000] : [5000, 10000, 15000, 20000];
    final country = countryOf(cc);
    final preview = TaskItem(
      id: -1, mode: kind, cat: cat,
      title: titleCtrl.text.trim().isEmpty ? '제목을 입력하세요' : titleCtrl.text.trim(),
      price: sea ? (price < seaMin ? seaMin : price) : price, hot: hot,
      distM: sea ? 9e9 : null, mins: sea ? 0 : mins,
      region: sea ? null : (placeCtrl.text.trim().isEmpty ? '우리 동네' : placeCtrl.text.trim()),
      cc: sea ? cc : null,
      country: sea ? '${country.flag} ${country.name}${city.isNotEmpty ? ' $city' : ''}' : null,
      place: placeCtrl.text.trim(),
      who: '나', desc: descCtrl.text.trim(),
      deadline: deadline, deliveryPlace: deliveryCtrl.text.trim().isEmpty ? null : deliveryCtrl.text.trim(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('비용과 완료 조건을 알려주세요'),
        _label(sea ? '사례비 (최소 ${nf(seaMin)}원, 물건값 별도)' : '사례비 (물건값 별도)'),
        _qtyStepper(won(price), () => setState(() => price = (price - 1000).clamp(floor, 9999999)), () => setState(() => price += 1000), big: true),
        const SizedBox(height: 10),
        Row(children: [
          for (final p in quickPrices)
            Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: _quickBtn('${p ~/ 1000}천', price == p, () => setState(() => price = p)))),
        ]),
        const SizedBox(height: 10),
        Text.rich(const TextSpan(style: TextStyle(fontSize: 12, color: AppColors.sub, height: 1.5), children: [
          TextSpan(text: '애매하면 이대로 올려도 돼요. 이웃이 '),
          TextSpan(text: '비공개로 가격을 제안', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
          TextSpan(text: '할 수 있어요.'),
        ])),
        const SizedBox(height: 22),
        _label('물품 구매비 부담 방식'),
        for (final e in paymentLabels.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => setState(() => payment = e.key),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                decoration: BoxDecoration(
                  color: payment == e.key ? AppColors.yellowSoft : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: payment == e.key ? AppColors.yellow : AppColors.line, width: 1.5),
                ),
                child: Text(e.value, style: TextStyle(fontSize: 14, color: AppColors.ink, fontWeight: payment == e.key ? FontWeight.w800 : FontWeight.w500)),
              ),
            ),
          ),
        if (payment != 'none') ...[
          const SizedBox(height: 8),
          _label('물품 예산 (원)'),
          TextField(controller: budgetCtrl, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), decoration: _dec('예: 15000')),
          _hint('사례비와 별도로 물건값에 쓰는 금액이에요.'),
        ],
        const SizedBox(height: 18),
        _label('완료 확인 방법'),
        TextField(controller: completionCtrl, maxLines: 2, onChanged: (_) => setState(() {}), decoration: _dec('예: 물품 전달 후 요청자가 수령 확인 (5자 이상)')),
        const SizedBox(height: 22),
        _label('급하게 올릴까요? (선택)'),
        InkWell(
          onTap: () => setState(() => hot = !hot),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            margin: const EdgeInsets.only(bottom: 22),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: hot ? AppColors.red : AppColors.line, width: 1.5)),
            child: Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('급해요 표시 + 목록 맨 위 노출', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    SizedBox(height: 2),
                    Text('더 빨리 매칭돼요 · 1,000원', style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
                  ],
                ),
              ),
              Container(
                width: 24, height: 24, alignment: Alignment.center,
                decoration: BoxDecoration(color: hot ? AppColors.red : Colors.white, shape: BoxShape.circle, border: Border.all(color: hot ? AppColors.red : AppColors.line, width: 2)),
                child: hot ? const Text('✓', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)) : null,
              ),
            ]),
          ),
        ),
        _label('이렇게 올라가요'),
        TaskCard(it: preview, onOpen: () {}, rich: true),
      ],
    );
  }

  Widget _segBtn(bool on, VoidCallback onTap, String label, Color c, Color bg) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: on ? bg : AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: on ? c : AppColors.line, width: 1.5)),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: on ? (c == AppColors.yellow ? AppColors.ink : c) : AppColors.ink)),
      ),
    );
  }

  Widget _quickBtn(String label, bool on, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: on ? AppColors.ink : AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: on ? AppColors.ink : AppColors.line)),
        child: Text(label, style: TextStyle(color: on ? Colors.white : AppColors.ink, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _qtyStepper(String value, VoidCallback onMinus, VoidCallback onPlus, {bool big = false}) {
    return Row(children: [
      _round('−', onMinus),
      Expanded(child: Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: big ? 26 : 18, fontWeight: FontWeight.w800, color: AppColors.ink))),
      _round('＋', onPlus),
    ]);
  }

  Widget _round(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 46, height: 46, alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line, width: 1.5), color: Colors.white),
        child: Text(label, style: const TextStyle(fontSize: 22, color: AppColors.ink)),
      ),
    );
  }
}
