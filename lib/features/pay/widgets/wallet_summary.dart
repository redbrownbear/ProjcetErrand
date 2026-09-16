import 'package:flutter/material.dart';

import '../../../core/storage/local_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../benefits/data/point_rules.dart';
import '../../profile/models/trust_level.dart';

/// 홈 최상단 지갑 카드.
///
/// 한 줄에 세 가지를 나란히 둔다 — **신뢰 레벨 · 겸사페이 잔액 · 포인트**.
/// 셋은 성격이 완전히 다르다.
///
/// - 레벨: 쌓인 기록. 쓸 수 없고, 남에게 보이는 값이다.
/// - 겸사페이: **실제 돈(원)**. 충전하고 출금한다.
/// - 포인트: 부업·미션으로 받는 리워드(P). 상품 교환에 쓴다.
///
/// 원과 P를 한 숫자로 합쳐 보여주면 "출금하면 얼마 들어오나"를 알 수 없게 된다.
/// 그래서 합계는 목표 달성률에만 쓰고, 위쪽은 끝까지 따로 둔다.
///
/// 기획 시안 v9의 `CompactEarnings`(`.income-compact`) 자리를 이어받았다.
class WalletSummary extends StatefulWidget {
  /// 겸사페이 잔액(원)
  final int payBalance;

  /// 보유 포인트(P)
  final int points;

  /// 신뢰 레벨
  final TrustLevel trust;

  final VoidCallback onOpenPay;
  final VoidCallback onOpenPoints;
  final VoidCallback onOpenLevel;

  const WalletSummary({
    super.key,
    required this.payBalance,
    required this.points,
    required this.trust,
    required this.onOpenPay,
    required this.onOpenPoints,
    required this.onOpenLevel,
  });

  @override
  State<WalletSummary> createState() => _WalletSummaryState();
}

class _WalletSummaryState extends State<WalletSummary> {
  static const _key = 'incomeGoal';
  static const _min = 1000;
  static const _max = 100000000;

  late int goal = LocalStore.read<int>(_key, 0);
  bool editing = false;
  String? error;
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void _openEditor() {
    ctrl.text = goal > 0 ? '$goal' : '';
    setState(() {
      error = null;
      editing = !editing;
    });
  }

  void _save() {
    final v = int.tryParse(ctrl.text.replaceAll(RegExp(r'[,\s]'), ''));
    if (v == null || v < _min || v > _max) {
      setState(() => error = '${nf(_min)}원부터 ${nf(_max)}원까지 숫자로 입력해 주세요');
      return;
    }
    LocalStore.write(_key, v);
    setState(() {
      goal = v;
      editing = false;
      error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 목표 달성률에서만 둘을 합친다 (1P = pointValue원 기준)
    final total = widget.payBalance + widget.points * pointValue;
    final percent = goal > 0 ? (total * 100 / goal).floor().clamp(0, 100) : 0;
    final trust = widget.trust;

    return Container(
      margin: const EdgeInsets.fromLTRB(22, 6, 22, 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(children: [
              Expanded(
                child: _Cell(
                  label: '신뢰 레벨',
                  value: 'Lv.${trust.level}',
                  unit: '',
                  sub: trust.name,
                  accent: _onDark(trust.color),
                  onTap: widget.onOpenLevel,
                ),
              ),
              const _CellDivider(),
              Expanded(
                child: _Cell(
                  label: '겸사페이',
                  value: nf(widget.payBalance),
                  unit: '원',
                  sub: '충전·출금',
                  accent: AppColors.gold,
                  onTap: widget.onOpenPay,
                ),
              ),
              const _CellDivider(),
              Expanded(
                child: _Cell(
                  label: '포인트',
                  value: nf(widget.points),
                  unit: 'P',
                  sub: '부업으로 모아요',
                  accent: Colors.white,
                  onTap: widget.onOpenPoints,
                ),
              ),
            ]),
          ),

          // ── 목표 ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(children: [
              Expanded(
                child: Text(goal > 0 ? '목표 ${won(goal)}' : '나의 목표 금액',
                    style: AppType.meta.copyWith(color: AppColors.onDarkSub)),
              ),
              if (goal > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('$percent%',
                      style: AppType.meta.copyWith(fontWeight: AppType.w700, color: AppColors.gold)),
                ),
              InkWell(
                onTap: _openEditor,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.onDarkFill, borderRadius: BorderRadius.circular(8)),
                  child: Text(goal > 0 ? '수정' : '설정',
                      style: AppType.caption.copyWith(fontWeight: AppType.w600, color: Colors.white)),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: goal > 0 ? percent / 100 : 0,
                minHeight: 6,
                backgroundColor: AppColors.onDarkFill,
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              goal > 0
                  ? (total >= goal ? '목표 달성! 다음 목표를 정해볼까요?' : '${won(goal - total)}만큼 더 모으면 달성해요')
                  : '겸사페이와 포인트를 합쳐 목표까지 얼마나 왔는지 볼 수 있어요',
              style: AppType.caption.copyWith(color: AppColors.onDarkFaint),
            ),
          ),

          if (editing) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: AppType.body.copyWith(fontSize: 15, fontWeight: AppType.w600),
                decoration: const InputDecoration(hintText: '예: 300000', fillColor: Colors.white),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(error!, style: AppType.caption.copyWith(color: const Color(0xFFFFB3A0))),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => editing = false),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.onDarkFill,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('목표 저장'),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  /// 짙은 바탕에서 너무 어두운 레벨 색(회색·남색)은 안 보인다. 그럴 때만 흰색으로 올린다.
  Color _onDark(Color c) => c.computeLuminance() < 0.35 ? Colors.white : c;
}

class _Cell extends StatelessWidget {
  final String label, value, unit, sub;
  final Color accent;
  final VoidCallback onTap;
  const _Cell({
    required this.label,
    required this.value,
    required this.unit,
    required this.sub,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppType.caption.copyWith(fontSize: 11, color: AppColors.onDarkSub)),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: value),
                    if (unit.isNotEmpty)
                      TextSpan(text: unit, style: AppType.price.copyWith(fontSize: 12, color: accent, fontWeight: AppType.w500)),
                  ]),
                  style: AppType.price.copyWith(fontSize: 19, color: accent),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.caption.copyWith(fontSize: 10, color: AppColors.onDarkFaint)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CellDivider extends StatelessWidget {
  const _CellDivider();
  @override
  Widget build(BuildContext context) => Container(width: 1, color: AppColors.onDarkFill);
}
