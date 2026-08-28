import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/task_item.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
import '../widgets/task_card.dart';

class NewRequestData {
  final String mode, cat, title, desc, place, country;
  final int mins, price;
  final bool hot;
  const NewRequestData({
    required this.mode, required this.cat, required this.title, required this.desc,
    required this.place, required this.country, required this.mins, required this.price, required this.hot,
  });
}

class PostRequest extends StatefulWidget {
  final String scope;
  final VoidCallback onClose;
  final void Function(NewRequestData) onSubmit;
  const PostRequest({super.key, required this.scope, required this.onClose, required this.onSubmit});
  @override
  State<PostRequest> createState() => _PostRequestState();
}

class _PostRequestState extends State<PostRequest> {
  int step = 0;
  String kind = 'ask'; // ask | sea
  String cat = 'buy';
  int mins = 30;
  int price = 10000;
  bool hot = false;
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final placeCtrl = TextEditingController();
  final countryCtrl = TextEditingController();

  bool get sea => kind == 'sea';

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    placeCtrl.dispose();
    countryCtrl.dispose();
    super.dispose();
  }

  bool _readyAt(int s) {
    if (s == 0) return titleCtrl.text.trim().isNotEmpty && descCtrl.text.trim().isNotEmpty;
    if (s == 1) return sea ? countryCtrl.text.trim().isNotEmpty : true;
    return true;
  }

  void _submit() {
    widget.onSubmit(NewRequestData(
      mode: kind, cat: cat, title: titleCtrl.text.trim(), desc: descCtrl.text.trim(),
      place: placeCtrl.text.trim(), country: countryCtrl.text.trim(),
      mins: sea ? 0 : mins, price: price, hot: hot,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final canNext = _readyAt(step);
    return Positioned.fill(
      child: Material(
        color: AppColors.page,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
            decoration: const BoxDecoration(color: AppColors.card, border: Border(bottom: BorderSide(color: AppColors.line))),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: step == 0 ? widget.onClose : () => setState(() => step -= 1),
                    borderRadius: BorderRadius.circular(99),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Text(step == 0 ? '✕' : '‹', style: const TextStyle(fontSize: 20, color: AppColors.ink)),
                    ),
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
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
              child: _stepBody(),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
            decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.line))),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: step < 2 ? (canNext ? () => setState(() => step += 1) : null) : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: step < 2 ? (canNext ? AppColors.black : AppColors.line) : AppColors.black,
                  foregroundColor: step < 2 && !canNext ? AppColors.faint : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  step < 2 ? '다음' : (hot ? '1,000원 결제하고 올리기' : '부탁 올리기'),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stepBody() {
    if (step == 0) return _step1();
    if (step == 1) return _step2();
    return _step3();
  }

  Widget _stepTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 20), child: Text(t, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: -0.3)));
  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Text(t, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink)));

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
        Row(children: [
          Expanded(child: _segBtn(!sea, () => setState(() => kind = 'ask'), '🇰🇷 우리 동네', AppColors.yellow, AppColors.yellowSoft)),
          const SizedBox(width: 8),
          Expanded(child: _segBtn(sea, () => setState(() => kind = 'sea'), '✈️ 해외 대행', AppColors.purple, AppColors.purpleSoft)),
        ]),
        const SizedBox(height: 20),
        if (sea)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(12)),
            child: const Text('그 나라에 있는 이웃이 대신 사서 가져다줘요. 물건값은 영수증으로 정산, 사례비는 따로 정해요.', style: TextStyle(fontSize: 12, color: AppColors.purple, height: 1.55, fontWeight: FontWeight.w500)),
          ),
        if (!sea) ...[
          _label('카테고리'),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8, crossAxisSpacing: 8,
            childAspectRatio: 0.95,
            children: cats.map((c) {
              final on = cat == c.k;
              return InkWell(
                onTap: () => setState(() => cat = c.k),
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  decoration: BoxDecoration(
                    color: on ? AppColors.yellowSoft : AppColors.card,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: on ? AppColors.yellow : AppColors.line, width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(c.label, style: TextStyle(fontSize: 10.5, color: AppColors.ink, fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
        ],
        _label('제목'),
        TextField(
          controller: titleCtrl,
          maxLength: 40,
          onChanged: (_) => setState(() {}),
          decoration: _dec(sea ? '예: 돈키호테에서 곤약젤리 사다주세요' : '예: 성심당에서 빵 좀 사다 주세요'),
        ),
        const SizedBox(height: 6),
        _label('간단 설명'),
        TextField(
          controller: descCtrl,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
          decoration: _dec(sea ? '품목·수량, 예산, 귀국 예정일 등을 적어주세요' : '무엇을, 어디서, 언제까지 필요한지 적어주세요'),
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
          _label('어느 나라 · 도시'),
          TextField(controller: countryCtrl, onChanged: (_) => setState(() {}), decoration: _dec('예: 🇯🇵 일본 도쿄')),
          const SizedBox(height: 16),
          _label('구매 장소 (선택)'),
          TextField(controller: placeCtrl, decoration: _dec('예: 시부야 돈키호테')),
        ] else ...[
          _label('어디서요?'),
          TextField(controller: placeCtrl, decoration: _dec('예: 역삼동 / 강남역 3번출구')),
          const SizedBox(height: 18),
          _label('예상 소요시간'),
          _qtyStepper('약 $mins분', () => setState(() => mins = (mins - 5).clamp(5, 999)), () => setState(() => mins += 5)),
          const SizedBox(height: 10),
          Row(children: [
            for (final m in [10, 20, 30, 60])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _quickBtn('$m분', mins == m, () => setState(() => mins = m)),
                ),
              ),
          ]),
        ],
      ],
    );
  }

  Widget _step3() {
    final quickPrices = sea ? [10000, 20000, 30000, 50000] : [5000, 10000, 15000, 20000];
    final preview = TaskItem(
      id: -1, mode: kind, cat: cat,
      title: titleCtrl.text.trim().isEmpty ? '제목을 입력하세요' : titleCtrl.text.trim(),
      price: price, hot: hot,
      distM: sea ? 9e9 : 150, mins: sea ? 0 : mins,
      region: sea ? null : (placeCtrl.text.trim().isEmpty ? '우리 동네' : placeCtrl.text.trim()),
      country: sea ? (countryCtrl.text.trim().isEmpty ? '해외' : countryCtrl.text.trim()) : null,
      place: placeCtrl.text.trim(),
      who: '나', desc: descCtrl.text.trim(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('얼마 드릴까요?'),
        _label(sea ? '사례비 (물건값 별도)' : '사례비'),
        _qtyStepper(won(price), () => setState(() => price = (price - 1000).clamp(0, 9999999)), () => setState(() => price += 1000), big: true),
        const SizedBox(height: 10),
        Row(children: [
          for (final p in quickPrices)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _quickBtn('${p ~/ 1000}천', price == p, () => setState(() => price = p)),
              ),
            ),
        ]),
        const SizedBox(height: 10),
        Text.rich(
          const TextSpan(
            style: TextStyle(fontSize: 12, color: AppColors.sub, height: 1.5),
            children: [
              TextSpan(text: '애매하면 이대로 올려도 돼요. 이웃이 '),
              TextSpan(text: '비공개로 가격을 제안', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
              TextSpan(text: '할 수 있어요.'),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _label('급하게 올릴까요? (선택)'),
        InkWell(
          onTap: () => setState(() => hot = !hot),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: hot ? AppColors.red : AppColors.line, width: 1.5),
            ),
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
        TaskCard(it: preview, onOpen: () {}),
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
        decoration: BoxDecoration(
          color: on ? bg : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? c : AppColors.line, width: 1.5),
        ),
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
        decoration: BoxDecoration(
          color: on ? AppColors.ink : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: on ? AppColors.ink : AppColors.line),
        ),
        child: Text(label, style: TextStyle(color: on ? Colors.white : AppColors.ink, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _qtyStepper(String value, VoidCallback onMinus, VoidCallback onPlus, {bool big = false}) {
    return Row(children: [
      _round('−', onMinus),
      Expanded(child: Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: big ? 26 : 18, fontWeight: FontWeight.w900, color: AppColors.ink))),
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
