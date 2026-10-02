import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../models/new_request_data.dart';
import 'form_steps.dart';
import 'request_form.dart';

/// 부탁 쓰기. 세 단계(무엇을 → 언제 어디서 → 비용과 완료 조건)로 나눠 받는다.
///
/// 값과 검증은 [RequestForm]이, 각 단계의 화면은 [WhatStep]·[WhereStep]·[CostStep]이 맡는다.
/// 여기서는 지금 몇 단계인지와 위아래 틀(진행 막대 · 다음 버튼)만 다룬다.
class PostRequest extends StatefulWidget {
  final String scope;
  final void Function(NewRequestData) onSubmit;

  /// 미리 정해 온 종류 — ask | sea. 지정하면 임시글의 종류보다 이 값을 따른다.
  final String? initialKind;

  /// 홈의 '자주 하는 부탁'에서 고른 종류. 지정하면 임시글의 종류보다 이 값을 따른다.
  final String? initialCat;

  const PostRequest({super.key, required this.scope, required this.onSubmit, this.initialKind, this.initialCat});

  @override
  State<PostRequest> createState() => _PostRequestState();
}

class _PostRequestState extends State<PostRequest> {
  late final RequestForm _form = RequestForm.restore(kind: widget.initialKind, cat: widget.initialCat);
  int _step = 0;

  bool get _lastStep => _step == RequestForm.stepCount - 1;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// 폼 값을 바꾸고 다시 그린 뒤, 바뀐 내용을 임시글로 남긴다.
  void _update([VoidCallback? change]) {
    setState(() => change?.call());
    _form.save();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initial = _form.deadlineOk ? _form.deadline! : now.add(const Duration(hours: 2));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null || !mounted) return;
    _update(() => _form.deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step -= 1);
    }
  }

  void _next() {
    if (!_lastStep) {
      setState(() => _step += 1);
      return;
    }
    if (!_form.ready) return;
    widget.onSubmit(_form.toData());
    _form.clear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.page,
      child: SafeArea(
        child: Column(
          children: [
            _progressHeader(),
            Expanded(
              child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(18, 20, 18, 24), child: _stepBody()),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _stepBody() => switch (_step) {
    0 => WhatStep(form: _form, update: _update),
    1 => WhereStep(form: _form, update: _update, onPickDeadline: _pickDeadline),
    _ => CostStep(form: _form, update: _update),
  };

  Widget _progressHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: _back,
                borderRadius: BorderRadius.circular(99),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(_step == 0 ? Icons.close_rounded : Icons.arrow_back_rounded, size: 22, color: AppColors.ink),
                ),
              ),
              Text(
                '${_step + 1} / ${RequestForm.stepCount}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sub),
              ),
              const SizedBox(width: 20),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (int i = 0; i < RequestForm.stepCount; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < RequestForm.stepCount - 1 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: i <= _step ? AppColors.yellow : AppColors.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    final canNext = _form.readyAt(_step);
    final hint = _form.hintAt(_step);
    final label = !_lastStep ? '다음' : (_form.hot ? '1,000원 결제하고 올리기' : '부탁 올리기');

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                hint,
                style: const TextStyle(fontSize: 12, color: AppColors.sub, fontWeight: FontWeight.w600),
              ),
            ),
          ElevatedButton(
            onPressed: canNext ? _next : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.line,
              disabledForegroundColor: AppColors.faint,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
