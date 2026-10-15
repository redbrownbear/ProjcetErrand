import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/kit.dart';
import '../../errand/data/countries.dart';
import '../data/proposals.dart';
import '../models/proposal.dart';

/// 제안하기 폼 (시안 v43 `openPropose`).
///
/// 국내는 다른 지역으로 이동할 때만 올릴 수 있다 — 출발지와 도착지가 같으면 막는다.
/// 가격은 영수증 기준으로 고지하고, 초과분은 환불하겠다는 확인을 받아야 올라간다.
class ProposeForm extends StatefulWidget {
  final bool abroad;
  final String who;
  final String area;
  final void Function(Proposal) onSubmit;
  const ProposeForm({super.key, this.abroad = false, required this.who, required this.area, required this.onSubmit});

  @override
  State<ProposeForm> createState() => _ProposeFormState();
}

class _ProposeFormState extends State<ProposeForm> {
  late bool abroad = widget.abroad;
  String? from;
  String to = '서울';
  String cc = 'jp';
  final city = TextEditingController();
  DateTime day = DateTime.now();
  final item = TextEditingController();
  final spec = TextEditingController();
  final price = TextEditingController();
  final note = TextEditingController();
  bool receiptOk = false;
  int max = 5;
  bool unlimited = false;

  @override
  void dispose() {
    for (final c in [city, item, spec, price, note]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _price => int.tryParse(price.text.replaceAll(',', '')) ?? 0;

  String? get _problem {
    if (abroad) {
      if (city.text.trim().isEmpty) return '어느 도시에 가는지 알려 주세요';
    } else {
      if (from == null) return '어디서 사 오는지 골라 주세요';
      if (from == to) return '국내는 다른 지역으로 이동할 때만 올릴 수 있어요';
    }
    if (item.text.trim().isEmpty) return '무엇을 사 올지 적어 주세요';
    if (_price <= 0) return '물건 가격을 적어 주세요';
    if (!receiptOk) return '영수증 안내를 확인해 주세요';
    return null;
  }

  String get _preview {
    final what = item.text.trim().isEmpty ? '○○' : item.text.trim();
    if (abroad) return '${city.text.trim().isEmpty ? '○○' : city.text.trim()} 가는데 $what 원하시는 분?';
    final f = from ?? '○○';
    final when = dayTag(day) == '오늘' ? '오늘' : '${day.month}/${day.day}에';
    return '$f에서 $when $to로 ${to == '서울' ? '올라가는데' : '가는데'} $what 원하시는 분?';
  }

  ({String range, String fee, int max})? get _fee {
    final p = _price;
    if (p <= 0) return null;
    for (final f in feeGuide) {
      if (p < f.max) return f;
    }
    return feeGuide.last;
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (d != null) setState(() => day = d);
  }

  void _submit() {
    if (_problem != null) return;
    widget.onSubmit(
      Proposal(
        id: DateTime.now().millisecondsSinceEpoch,
        abroad: abroad,
        from: abroad ? city.text.trim() : from!,
        to: abroad ? '한국' : to,
        cc: abroad ? cc : null,
        item: item.text.trim(),
        spec: spec.text.trim().isEmpty ? null : spec.text.trim(),
        price: _price,
        day: day,
        max: unlimited ? 0 : max,
        who: widget.who,
        area: widget.area,
        note: note.text.trim(),
        mine: true,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final problem = _problem;
    return SheetFrame(
      title: '제안하기',
      sub: '다녀오는 길에 사 올 수 있는 걸 올려요. 원하는 이웃이 “구매할래요”를 눌러요',
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (problem != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(problem, style: const TextStyle(fontSize: 12, color: AppColors.sub)),
            ),
          BigButton(label: '제안 올리기', bg: AppColors.ink, fg: Colors.white, height: 52, onTap: problem == null ? _submit : null),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _toggle('해외', abroad, () => setState(() => abroad = true)),
              const SizedBox(width: 6),
              _toggle('국내 지역 이동', !abroad, () => setState(() => abroad = false)),
            ],
          ),
          if (abroad) ...[
            const FieldLabel('어느 나라에 가나요?'),
            _dropdown<String>(
              value: cc,
              items: [for (final c in countries) (c.cc, c.name)],
              onChanged: (v) => setState(() {
                cc = v;
                city.clear();
              }),
            ),
            const FieldLabel('어느 도시예요?'),
            TextField(
              controller: city,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: '예) ${countryOf(cc).cities.isEmpty ? '도쿄' : countryOf(cc).cities.first}'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                children: [
                  for (final c in countryOf(cc).cities.take(4))
                    ActionChip(
                      label: Text(c, style: const TextStyle(fontSize: 12)),
                      onPressed: () => setState(() => city.text = c),
                      backgroundColor: AppColors.page,
                      side: BorderSide.none,
                    ),
                ],
              ),
            ),
          ] else ...[
            const FieldLabel('어디서 사 오나요?'),
            _dropdown<String?>(
              value: from,
              hint: '지역 선택',
              items: [for (final r in proposalRegions) (r, r)],
              onChanged: (v) => setState(() => from = v),
            ),
            const FieldLabel('어디로 가나요?'),
            _dropdown<String>(
              value: to,
              items: [for (final r in proposalRegions) (r, r)],
              onChanged: (v) => setState(() => to = v),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('국내는 다른 지역으로 이동할 때만 올릴 수 있어요. 예) 대전 → 서울', style: TextStyle(fontSize: 12, color: AppColors.sub)),
            ),
          ],
          FieldLabel(abroad ? '출국하는 날' : '이동하는 날'),
          GestureDetector(
            onTap: _pickDay,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  Text(
                    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  Text(dayTag(day), style: const TextStyle(fontSize: 12, color: AppColors.sub)),
                  const Spacer(),
                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.sub),
                ],
              ),
            ),
          ),
          const FieldLabel('무엇을 사 올까요?'),
          TextField(
            controller: item,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: abroad ? '예) 도쿄바나나' : '예) 성심당 빵'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: spec,
            decoration: const InputDecoration(hintText: '구성 (선택) 예) 8개입 1박스'),
          ),
          const FieldLabel('물건 가격 · 1명당'),
          TextField(
            controller: price,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            decoration: const InputDecoration(hintText: '예) 12000', suffixText: '원'),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('사 올 물건의 가격을 정확히 알려 주세요', style: TextStyle(fontSize: 12, color: AppColors.sub)),
          ),
          const SizedBox(height: 12),
          _feeTable(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '가격 고지 · 영수증 안내',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.yellowInk),
                ),
                const SizedBox(height: 6),
                const Text(
                  '실제보다 높게 적을 수도 있지만, 거래 후 영수증을 보여 줘야 해요. 영수증보다 높게 적은 금액은 꼭 환불해 주세요.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.55),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => receiptOk = !receiptOk),
                  child: Row(
                    children: [
                      Icon(
                        receiptOk ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        size: 22,
                        color: receiptOk ? AppColors.ink : AppColors.faint,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text('영수증을 올리고, 초과분은 환불할게요', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const FieldLabel('몇 명까지 받을까요?'),
          Row(
            children: [
              _stepBtn(Icons.remove_rounded, !unlimited && max > 1, () => setState(() => max--)),
              SizedBox(
                width: 70,
                child: Text(
                  unlimited ? '제한 없음' : '$max명',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              _stepBtn(Icons.add_rounded, !unlimited && max < 15, () => setState(() => max++)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => unlimited = !unlimited),
                child: Row(
                  children: [
                    Icon(
                      unlimited ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 20,
                      color: unlimited ? AppColors.ink : AppColors.faint,
                    ),
                    const SizedBox(width: 4),
                    const Text('제한 없이 받기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('정원이 차면 자동으로 마감돼요 (1~15명)', style: TextStyle(fontSize: 12, color: AppColors.sub)),
          ),
          const FieldLabel('한마디', hint: '선택'),
          TextField(
            controller: note,
            maxLines: 2,
            decoration: const InputDecoration(hintText: '예) 아이스박스에 담아 와요'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '이렇게 올라가요',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.sub),
                ),
                const SizedBox(height: 6),
                Text(_preview, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeTable() {
    final cur = _fee;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('추천 심부름료', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          for (final f in feeGuide)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: identical(f, cur) ? AppColors.yellowSoft : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(f.range, style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
                  ),
                  Text(
                    f.fee,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: identical(f, cur) ? AppColors.yellowDeep : AppColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            cur == null ? '가격을 넣으면 이 가격대에 맞는 심부름료를 추천해 드려요' : '${won(_price)}이면 ${cur.fee}가 적당해요',
            style: const TextStyle(fontSize: 11.5, color: AppColors.sub),
          ),
        ],
      ),
    );
  }

  Widget _toggle(String label, bool on, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? AppColors.ink : AppColors.card,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: on ? AppColors.ink : AppColors.outline),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: on ? Colors.white : AppColors.ink2),
      ),
    ),
  );

  Widget _stepBtn(IconData i, bool on, VoidCallback f) => GestureDetector(
    onTap: on ? f : null,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(11)),
      child: Icon(i, size: 20, color: on ? AppColors.ink : AppColors.faint),
    ),
  );

  Widget _dropdown<T>({required T value, String? hint, required List<(T, String)> items, required ValueChanged<T> onChanged}) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      hint: hint == null ? null : Text(hint),
      items: [for (final it in items) DropdownMenuItem<T>(value: it.$1, child: Text(it.$2))],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      decoration: const InputDecoration(),
      borderRadius: BorderRadius.circular(14),
      menuMaxHeight: 360,
    );
  }
}
