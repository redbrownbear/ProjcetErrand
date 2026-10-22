import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/colors.dart';
import '../models/proposal.dart';

typedef ProposalAskInput = ({String item, int? est, String note});

/// 제안자에게 따로 부탁(A29) — 제안에 없는 물건도 같이 사다 줄 수 있는지 묻는다.
/// 제안자가 수락하면 그 부탁 하나가 거래가 되고 채팅이 열린다.
Future<ProposalAskInput?> openProposalAskSheet(BuildContext context, Proposal p) {
  return showModalBottomSheet<ProposalAskInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _ProposalAskSheet(p: p),
  );
}

class _ProposalAskSheet extends StatefulWidget {
  final Proposal p;
  const _ProposalAskSheet({required this.p});

  @override
  State<_ProposalAskSheet> createState() => _ProposalAskSheetState();
}

class _ProposalAskSheetState extends State<_ProposalAskSheet> {
  final item = TextEditingController();
  final est = TextEditingController();
  final note = TextEditingController();

  @override
  void dispose() {
    item.dispose();
    est.dispose();
    note.dispose();
    super.dispose();
  }

  bool get _ok => item.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final where = widget.p.abroad ? widget.p.from : '${widget.p.from}에서';
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 18, 22, 18 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('제안자에게 따로 부탁', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(
            '${widget.p.who}님이 $where 오는 길에 다른 것도 사다 줄 수 있는지 물어봐요. 수락하면 채팅이 열려요.',
            style: const TextStyle(fontSize: 13, color: AppColors.sub, height: 1.5),
          ),
          const SizedBox(height: 16),
          _label('사다 줬으면 하는 것'),
          TextField(
            key: const Key('ask-item'),
            controller: item,
            maxLength: 40,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: '예) 돌산 갓김치 말고 고들빼기 1kg', counterText: ''),
          ),
          const SizedBox(height: 12),
          _label('예상 물건값 (선택)'),
          TextField(
            key: const Key('ask-est'),
            controller: est,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
            decoration: const InputDecoration(hintText: '모르면 비워 두세요', suffixText: '원'),
          ),
          const SizedBox(height: 12),
          _label('한마디 (선택)'),
          TextField(
            controller: note,
            maxLength: 200,
            maxLines: 2,
            decoration: const InputDecoration(hintText: '없으면 비슷한 걸로 괜찮아요', counterText: ''),
          ),
          const SizedBox(height: 6),
          const Text(
            '돈은 만나서 영수증을 보고 직접 주고받아요 · 앱 안의 결제는 없어요',
            style: TextStyle(fontSize: 12, color: AppColors.sub),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('ask-send'),
            onPressed: _ok
                ? () => Navigator.pop(context, (item: item.text.trim(), est: int.tryParse(est.text), note: note.text.trim()))
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.line,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('부탁 보내기', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink2)),
  );
}
