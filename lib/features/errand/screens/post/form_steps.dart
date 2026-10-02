import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../benefits/data/point_rules.dart';
import '../../data/categories.dart';
import '../../data/countries.dart';
import '../../widgets/task_card.dart';
import 'form_widgets.dart';
import 'request_form.dart';

/// 폼 값을 바꾸고 화면을 다시 그리게 하는 함수. 바꿀 내용이 없으면 다시 그리기만 한다.
typedef FormUpdate = void Function([VoidCallback? change]);

/// 1단계 — 무엇을 부탁할까요?
class WhatStep extends StatelessWidget {
  final RequestForm form;
  final FormUpdate update;
  const WhatStep({super.key, required this.form, required this.update});

  @override
  Widget build(BuildContext context) {
    final sea = form.sea;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepTitle('무엇을 부탁할까요?'),
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text('작성 중인 내용은 이 기기에 자동 보관돼요.', style: TextStyle(fontSize: 12, color: AppColors.sub)),
        ),
        Row(
          children: [
            Expanded(child: _kindButton('ask', '우리 동네', AppColors.yellow, AppColors.yellowSoft, AppColors.ink)),
            const SizedBox(width: 8),
            Expanded(child: _kindButton('sea', '해외 대행', AppColors.purple, AppColors.purpleSoft, AppColors.purple)),
          ],
        ),
        const SizedBox(height: 20),
        if (sea)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: NoteBox(
              '그 나라에 있는 이웃이 대신 사서 가져다줘요. 물건값은 영수증으로 정산, 사례비는 최소 ${nf(seaMin)}원부터예요.',
              bg: AppColors.purpleSoft,
              fg: AppColors.purple,
            ),
          )
        else ...[
          const FieldLabel('카테고리'),
          _categoryGrid(),
          const SizedBox(height: 20),
        ],
        const FieldLabel('제목'),
        TextField(
          controller: form.title,
          maxLength: 40,
          onChanged: (_) => update(),
          decoration: formFieldDecoration(sea ? '예: 돈키호테에서 곤약젤리 사다주세요' : '예: 성심당에서 빵 좀 사다 주세요'),
        ),
        const FieldLabel('간단 설명'),
        TextField(
          controller: form.desc,
          maxLines: 4,
          maxLength: 2000,
          onChanged: (_) => update(),
          decoration: formFieldDecoration(sea ? '품목·수량, 예산, 귀국 예정일 등을 적어주세요' : '필요한 물건, 수량, 전달 방법을 알려주세요'),
        ),
      ],
    );
  }

  Widget _kindButton(String kind, String label, Color accent, Color tint, Color selectedInk) {
    final on = form.kind == kind;
    return ChoiceBox(
      selected: on,
      onTap: () => update(() => form.setKind(kind)),
      accent: accent,
      tint: tint,
      padding: const EdgeInsets.symmetric(vertical: 13),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: on ? selectedInk : AppColors.ink),
      ),
    );
  }

  Widget _categoryGrid() {
    return GridView(
      // 비율이 아니라 픽셀로 높이를 고정한다. 비율을 쓰면 넓은 화면에서 셀이 같이 커진다.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 68,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 58,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final c in cats)
          ChoiceBox(
            selected: form.cat == c.k,
            onTap: () => update(() => form.cat = c.k),
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(c.icon, size: 19, color: AppColors.ink2),
                const SizedBox(height: 3),
                Text(
                  c.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.ink,
                    fontWeight: form.cat == c.k ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 2단계 — 언제 어디서요?
class WhereStep extends StatelessWidget {
  final RequestForm form;
  final FormUpdate update;
  final VoidCallback onPickDeadline;
  const WhereStep({super.key, required this.form, required this.update, required this.onPickDeadline});

  @override
  Widget build(BuildContext context) {
    final sea = form.sea;
    final deadline = form.deadline;
    final expired = deadline != null && !form.deadlineOk;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepTitle('언제 어디서요?'),
        if (sea) ..._overseasFields() else ..._localFields(),
        const SizedBox(height: 18),
        const FieldLabel('전달·완료 장소'),
        TextField(controller: form.delivery, onChanged: (_) => update(), decoration: formFieldDecoration('예: 서초역 2번 출구 / 같은 장소')),
        const SizedBox(height: 18),
        const FieldLabel('완료해야 하는 날짜와 시각'),
        _deadlineBox(deadline, expired),
        FieldHint(expired ? '이미 지난 시각이에요. 현재보다 이후 시각을 선택해 주세요.' : '현재보다 이후 시각을 선택해 주세요.'),
        const SizedBox(height: 14),
        NoteBox(sea ? '매장 이름을 자세히 적어주세요.' : '여러 사람이 오가는 공개된 장소가 좋아요.'),
      ],
    );
  }

  List<Widget> _overseasFields() => [
    const FieldLabel('어느 나라'),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in countries)
          _pill(
            c.name,
            selected: form.cc == c.cc,
            accent: AppColors.purple,
            tint: AppColors.purpleSoft,
            onTap: () => update(() {
              form.cc = c.cc;
              form.city = '';
            }),
          ),
      ],
    ),
    const SizedBox(height: 16),
    const FieldLabel('도시'),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final city in countryOf(form.cc).cities)
          _pill(
            city,
            selected: form.city == city,
            accent: AppColors.ink,
            tint: AppColors.ink,
            selectedInk: Colors.white,
            onTap: () => update(() => form.city = form.city == city ? '' : city),
          ),
      ],
    ),
    const SizedBox(height: 16),
    const FieldLabel('구매할 매장'),
    TextField(controller: form.place, onChanged: (_) => update(), decoration: formFieldDecoration('예: 시부야 돈키호테')),
  ];

  List<Widget> _localFields() => [
    const FieldLabel('만날 장소'),
    TextField(controller: form.place, onChanged: (_) => update(), decoration: formFieldDecoration('예: 역삼동 / 강남역 3번출구')),
    const SizedBox(height: 18),
    const FieldLabel('예상 소요시간'),
    ValueStepper(
      value: '약 ${form.mins}분',
      onMinus: () => update(() => form.mins = (form.mins - 5).clamp(5, 999)),
      onPlus: () => update(() => form.mins += 5),
    ),
    const SizedBox(height: 10),
    QuickPicks<int>(
      values: const [10, 20, 30, 60],
      selected: form.mins,
      label: (m) => '$m분',
      onPick: (m) => update(() => form.mins = m),
    ),
  ];

  Widget _pill(
    String label, {
    required bool selected,
    required Color accent,
    required Color tint,
    Color selectedInk = AppColors.ink,
    required VoidCallback onTap,
  }) {
    return ChoiceBox(
      selected: selected,
      onTap: onTap,
      accent: accent,
      tint: tint,
      radius: 11,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? selectedInk : AppColors.ink),
      ),
    );
  }

  Widget _deadlineBox(DateTime? deadline, bool expired) {
    return InkWell(
      onTap: onPickDeadline,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: expired ? AppColors.red : AppColors.line),
        ),
        child: Row(
          children: [
            const AppIcon('calendar', size: 14, color: AppColors.ink2),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                deadline == null ? '날짜와 시각 선택' : '${dateTimeLabel(deadline)}까지',
                style: TextStyle(
                  fontSize: 14.5,
                  color: deadline == null ? AppColors.faint : AppColors.ink,
                  fontWeight: deadline == null ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.faint),
          ],
        ),
      ),
    );
  }
}

/// 3단계 — 비용과 완료 조건
class CostStep extends StatelessWidget {
  final RequestForm form;
  final FormUpdate update;
  const CostStep({super.key, required this.form, required this.update});

  @override
  Widget build(BuildContext context) {
    final sea = form.sea;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepTitle('비용과 완료 조건을 알려주세요'),
        FieldLabel(sea ? '사례비 (최소 ${nf(seaMin)}원, 물건값 별도)' : '사례비 (물건값 별도)'),
        ValueStepper(
          value: won(form.price),
          onMinus: () => update(() => form.price = (form.price - 1000).clamp(form.floor, 9999999)),
          onPlus: () => update(() => form.price += 1000),
          big: true,
        ),
        const SizedBox(height: 10),
        QuickPicks<int>(
          values: sea ? const [20000, 30000, 50000, 100000] : const [5000, 10000, 15000, 20000],
          selected: form.price,
          label: (p) => '${p ~/ 1000}천',
          onPick: (p) => update(() => form.price = p),
        ),
        const SizedBox(height: 10),
        const Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 12, color: AppColors.sub, height: 1.5),
            children: [
              TextSpan(text: '애매하면 이대로 올려도 돼요. 이웃이 '),
              TextSpan(
                text: '비공개로 가격을 제안',
                style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
              ),
              TextSpan(text: '할 수 있어요.'),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const FieldLabel('물품 구매비 부담 방식'),
        for (final e in paymentLabels.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: ChoiceBox(
                selected: form.payment == e.key,
                onTap: () => update(() => form.payment = e.key),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.ink,
                    fontWeight: form.payment == e.key ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        if (form.payment != 'none') ...[
          const SizedBox(height: 8),
          const FieldLabel('물품 예산 (원)'),
          TextField(
            controller: form.budgetText,
            keyboardType: TextInputType.number,
            onChanged: (_) => update(),
            decoration: formFieldDecoration('예: 15000'),
          ),
          const FieldHint('사례비와 별도로 물건값에 쓰는 금액이에요.'),
        ],
        const SizedBox(height: 18),
        const FieldLabel('완료 확인 방법'),
        TextField(
          controller: form.completion,
          maxLines: 2,
          onChanged: (_) => update(),
          decoration: formFieldDecoration('예: 물품 전달 후 요청자가 수령 확인 (5자 이상)'),
        ),
        const SizedBox(height: 22),
        const FieldLabel('급하게 올릴까요? (선택)'),
        _hotToggle(),
        const SizedBox(height: 22),
        const FieldLabel('이렇게 올라가요'),
        TaskCard(it: form.preview(), onOpen: () {}, rich: true, last: true),
      ],
    );
  }

  Widget _hotToggle() {
    final hot = form.hot;
    return ChoiceBox(
      selected: hot,
      onTap: () => update(() => form.hot = !hot),
      accent: AppColors.red,
      tint: AppColors.card,
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          const AppIcon('fire', size: 17, color: AppColors.ink2),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '급해요 표시 + 목록 맨 위 노출',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                SizedBox(height: 2),
                Text('더 빨리 매칭돼요 · 1,000원', style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hot ? AppColors.red : AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: hot ? AppColors.red : AppColors.line, width: 2),
            ),
            child: hot ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
          ),
        ],
      ),
    );
  }
}
