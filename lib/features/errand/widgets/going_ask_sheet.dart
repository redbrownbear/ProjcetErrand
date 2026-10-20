import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/task_item.dart';

/// '가는 김에 · 제가 가요' 글에 "부탁할게요" — 무엇을 사다 줄지와 사례비를 적어 보낸다.
/// 글쓴이가 수락하면 그 부탁 하나가 거래가 되고 채팅이 열린다.
Future<({String msg, int price})?> openGoingAskSheet(BuildContext context, TaskItem it) {
  return showModalBottomSheet<({String msg, int price})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _GoingAskSheet(it: it),
  );
}

class _GoingAskSheet extends StatefulWidget {
  final TaskItem it;
  const _GoingAskSheet({required this.it});

  @override
  State<_GoingAskSheet> createState() => _GoingAskSheetState();
}

class _GoingAskSheetState extends State<_GoingAskSheet> {
  final msg = TextEditingController();
  late int price = widget.it.price;

  @override
  void dispose() {
    msg.dispose();
    super.dispose();
  }

  bool get _ok => msg.text.trim().length >= 2;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 18, 22, 18 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('부탁할게요', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(
            '${widget.it.title} — 무엇을 사다 줄지 적어 주세요. 글쓴이가 수락하면 채팅이 열려요.',
            style: const TextStyle(fontSize: 13, color: AppColors.sub, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Text('부탁 내용', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink2)),
          const SizedBox(height: 6),
          TextField(
            controller: msg,
            maxLength: 300,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: '예) 곤약젤리 복숭아맛 2봉, 없으면 포도맛', counterText: ''),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text('사례비 (물건값 별도)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink2)),
              ),
              _step(Icons.remove_rounded, price >= 1000 ? () => setState(() => price -= 1000) : null),
              SizedBox(
                width: 92,
                child: Text(won(price), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              _step(Icons.add_rounded, () => setState(() => price += 1000)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.it.price > 0 ? '글쓴이가 정한 건당 사례비는 ${won(widget.it.price)}이에요.' : '글쓴이가 사례비를 정하지 않았어요. 적당한 금액을 제안해 주세요.',
              style: const TextStyle(fontSize: 12, color: AppColors.sub),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _ok ? () => Navigator.pop(context, (msg: msg.text.trim(), price: price)) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.line,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text('${won(price)}에 부탁 보내기', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
          ),
        ],
      ),
    );
  }

  Widget _step(IconData icon, VoidCallback? onTap) => IconButton.filledTonal(
    onPressed: onTap,
    icon: Icon(icon, size: 18),
    style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
  );
}
