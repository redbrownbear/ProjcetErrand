import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../pay_config.dart';

/// 개발용 금액 입력. [max]를 주면 그 이상은 못 넣는다(출금).
class AmountSheet extends StatefulWidget {
  final String title, hint;
  final int? max;
  const AmountSheet({super.key, required this.title, required this.hint, this.max});
  @override
  State<AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<AmountSheet> {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(onPressed: _submit, child: const Text('확인')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
