import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../../core/widgets/section_header.dart';
import '../models/pay_entry.dart';
import '../pay_config.dart';

/// 겸사페이 — 앱 안에서 돈이 오가는 지갑.
///
/// **아직 실제 이체는 없다.** 충전·출금은 [PayConfig.debugTopUp]이 켜진
/// 디버그 빌드에서만 원장에 줄을 쌓고, 릴리스에서는 안내만 띄운다.
/// 정식으로 열려면 결제사 연동·계좌 인증·서버 트랜잭션에 더해
/// **전자금융거래법 검토**가 먼저다. (`PayConfig` 참고)
class PayScreen extends StatelessWidget {
  final List<PayEntry> entries;
  final void Function(String) flash;

  /// 개발용 충전·출금. 릴리스 빌드에서는 호출되지 않는다.
  final void Function(int amount) onCharge;
  final void Function(int amount) onWithdraw;

  const PayScreen({
    super.key,
    required this.entries,
    required this.flash,
    required this.onCharge,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final balance = PayEntry.balanceOf(entries);

    return ScreenFrame(
      title: '겸사페이',
      onBack: () => Navigator.of(context).pop(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          // ── 잔액 ──────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(22, 18, 22, 0),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(AppRadius.surface)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('내 잔액', style: AppType.meta.copyWith(color: AppColors.onDarkSub)),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: nf(balance)),
                    TextSpan(text: '원', style: AppType.price.copyWith(fontSize: 17, color: AppColors.gold)),
                  ]),
                  style: AppType.price.copyWith(fontSize: 32, color: AppColors.gold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Row(children: [
                  Expanded(
                    child: _PayButton(
                      icon: 'plus',
                      label: '충전',
                      onTap: () => _charge(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PayButton(
                      icon: 'arrowRight',
                      label: '출금',
                      onTap: () => _withdraw(context, balance),
                    ),
                  ),
                ]),
              ),
            ]),
          ),

          _notice(),

          // ── 내역 ──────────────────────────────────────────────────────
          SectionHeader(title: '거래 내역', count: entries.isEmpty ? null : entries.length),
          if (entries.isEmpty)
            const EmptyState(
              compact: true,
              icon: 'clock',
              title: '아직 내역이 없어요',
              msg: '부탁을 완료하면 사례비가 여기에 쌓여요.',
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(children: [for (final e in entries) _EntryRow(entry: e)]),
            ),
        ],
      ),
    );
  }

  // ── 충전·출금 ─────────────────────────────────────────────────────────

  Future<void> _charge(BuildContext context) async {
    if (!PayConfig.debugTopUp) {
      flash('충전은 결제사 연동과 법령 검토 후에 열려요');
      return;
    }
    final amount = await _askAmount(context, title: '개발용 충전', hint: '넣을 금액');
    if (amount != null) onCharge(amount);
  }

  Future<void> _withdraw(BuildContext context, int balance) async {
    if (!PayConfig.debugTopUp) {
      flash(balance == 0 ? '출금할 잔액이 없어요' : '출금은 계좌 인증과 법령 검토 후에 열려요');
      return;
    }
    if (balance == 0) {
      flash('출금할 잔액이 없어요');
      return;
    }
    final amount = await _askAmount(context, title: '개발용 출금', hint: '뺄 금액', max: balance);
    if (amount != null) onWithdraw(amount);
  }

  Future<int?> _askAmount(BuildContext context, {required String title, required String hint, int? max}) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AmountSheet(title: title, hint: hint, max: max),
    );
  }

  /// 지금 상태를 숨기지 않고 그대로 적는다. 될 것처럼 보이는 버튼이 제일 위험하다.
  Widget _notice() {
    final debug = PayConfig.debugTopUp;
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: debug ? AppColors.blueSoft : AppColors.yellowSoft,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline_rounded, size: 18, color: debug ? AppColors.blue : AppColors.yellowDeep),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              debug ? '개발용 모드 · 실제 이체가 아니에요' : '아직 실제 이체는 일어나지 않아요',
              style: AppType.meta.copyWith(
                fontWeight: AppType.w600,
                color: debug ? AppColors.blue : AppColors.yellowDeep,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                debug
                    ? '충전·출금 버튼은 흐름을 확인하려고 열어 둔 거예요.\n'
                        '원장에 기록만 남고 돈은 1원도 움직이지 않아요. 배포 빌드에서는 잠깁니다.'
                    : '결제사 연동·계좌 인증과 전자금융거래법 검토가 끝나야 열립니다.\n'
                        '지금 잔액은 완료한 거래의 사례비를 모아 보여주는 기록이에요.',
                style: AppType.caption.copyWith(
                  color: debug ? AppColors.blue : AppColors.yellowDeep,
                  height: 1.6,
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _PayButton extends StatelessWidget {
  final String icon, label;
  final VoidCallback onTap;
  const _PayButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.onDarkFill, borderRadius: BorderRadius.circular(AppRadius.tile)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(AppIcon.data(icon), size: 17, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: AppType.button.copyWith(color: Colors.white)),
        ]),
      ),
    );
  }
}

/// 개발용 금액 입력. [max]를 주면 그 이상은 못 넣는다(출금).
class _AmountSheet extends StatefulWidget {
  final String title, hint;
  final int? max;
  const _AmountSheet({required this.title, required this.hint, this.max});
  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  final ctrl = TextEditingController();
  String? error;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  int get _cap => widget.max == null ? PayConfig.maxAmount : widget.max!;

  void _submit() {
    final value = int.tryParse(ctrl.text.replaceAll(RegExp(r'[,\s원]'), ''));
    if (value == null || value <= 0) {
      setState(() => error = '금액을 숫자로 입력해 주세요');
      return;
    }
    if (value > _cap) {
      setState(() => error = '${nf(_cap)}원까지 가능해요');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.title, style: AppType.pageTitle.copyWith(fontSize: 16)),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('실제 이체가 아니라 원장에 기록만 남아요', style: AppType.meta),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (error != null) setState(() => error = null);
                },
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(hintText: widget.hint, errorText: error, suffixText: '원'),
                style: AppType.body.copyWith(fontSize: 18, fontWeight: AppType.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final n in PayConfig.quickCharge)
                    if (n <= _cap)
                      OutlinedButton(
                        onPressed: () => setState(() {
                          ctrl.text = '$n';
                          error = null;
                        }),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: Text('${nf(n)}원'),
                      ),
                  if (widget.max != null)
                    OutlinedButton(
                      onPressed: () => setState(() {
                        ctrl.text = '${widget.max}';
                        error = null;
                      }),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text('전액'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: _submit, child: const Text('확인'))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final PayEntry entry;
  const _EntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final income = entry.isIncome;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F1F3)))),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: income ? AppColors.greenSoft : AppColors.page,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(AppIcon.data(entry.kind.icon), size: 18, color: income ? AppColors.green : AppColors.sub),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry.label.isEmpty ? entry.kind.label : entry.label,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppType.body.copyWith(fontWeight: AppType.w500)),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text('${entry.kind.label} · ${dateTimeLabel(entry.at)}', style: AppType.caption),
            ),
          ]),
        ),
        Text(
          '${income ? '+' : '−'}${nf(entry.amount.abs())}원',
          style: AppType.price.copyWith(fontSize: 15, color: income ? AppColors.green : AppColors.ink),
        ),
      ]),
    );
  }
}
