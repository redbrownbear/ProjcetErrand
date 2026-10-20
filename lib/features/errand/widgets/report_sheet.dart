import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../models/task_item.dart';

/// 부탁 상세의 '신고 · 차단' 시트 (W5).
///
/// 신고는 운영자가 확인하고(functions/src/admin), 차단은 바로 적용된다 —
/// 서로 지원·수락할 수 없고 그 사람의 부탁이 목록에서 사라진다.
Future<void> openReportSheet(
  BuildContext context,
  TaskItem it, {
  required Future<bool> Function(TaskItem it, String reason, String detail) onReport,
  required void Function(TaskItem it) onBlock,
}) => showSheet<void>(context, (ctx) => _ReportSheet(it: it, onReport: onReport, onBlock: onBlock));

class _ReportSheet extends StatefulWidget {
  final TaskItem it;
  final Future<bool> Function(TaskItem it, String reason, String detail) onReport;
  final void Function(TaskItem it) onBlock;
  const _ReportSheet({required this.it, required this.onReport, required this.onBlock});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const reasons = ['금지 품목·불법 부탁', '사기·결제 유도 의심', '노쇼·약속 불이행', '욕설·위협·불쾌한 행동', '연락처·외부 거래 유도', '기타'];

  String? reason;
  bool sending = false;
  final detail = TextEditingController();

  @override
  void dispose() {
    detail.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final r = reason;
    if (r == null || sending) return;
    setState(() => sending = true);
    final ok = await widget.onReport(widget.it, r, detail.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: '신고 · 차단',
      sub: '${widget.it.who}님의 부탁 "${widget.it.title}"',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '신고 사유',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final r in reasons)
                ChoiceChip(
                  label: Text(r, style: const TextStyle(fontSize: 13)),
                  selected: reason == r,
                  onSelected: (_) => setState(() => reason = r),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('report-detail'),
            controller: detail,
            maxLength: 1000,
            maxLines: 3,
            decoration: const InputDecoration(hintText: '무슨 일이 있었는지 적어 주세요 (선택)', border: OutlineInputBorder()),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: reason == null || sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(sending ? '보내는 중…' : '신고하기', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 12),
          const Text(
            '차단하면 서로 지원·수락할 수 없고, 이 사용자의 부탁이 목록에서 사라져요.',
            style: TextStyle(fontSize: 12.5, color: AppColors.sub, height: 1.5),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                widget.onBlock(widget.it);
                Navigator.of(context).pop();
                Navigator.of(context).maybePop(); // 차단한 사람의 상세 화면도 닫는다
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.red),
              child: Text('${widget.it.who}님 차단하기', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
