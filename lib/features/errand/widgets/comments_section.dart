import 'package:flutter/material.dart';

import '../../../core/backend/server_api.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/kit.dart';
import '../models/task_item.dart';
import '../repositories/comment_repository.dart';

/// 부탁 상세 아래 공개 댓글. 지원·부탁 전에 궁금한 걸 묻고 답한다.
/// 연락처·계좌·링크는 서버가 가린다. 글쓴이가 답하면 댓글 단 사람들에게 알림이 간다.
class CommentsSection extends StatefulWidget {
  final TaskItem it;

  /// 지금 로그인한 내 uid (내 댓글 표시용)
  final String? myUid;
  const CommentsSection({super.key, required this.it, this.myUid});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  late final repo = CommentRepository(widget.it.id);
  late final Stream<List<RequestComment>> stream = repo.watch();
  final ctrl = TextEditingController();
  bool sending = false;
  String? note;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = ctrl.text.trim();
    if (text.isEmpty || sending) return;
    setState(() {
      sending = true;
      note = null;
    });
    try {
      final masked = await repo.add(text);
      ctrl.clear();
      if (mounted) FocusScope.of(context).unfocus();
      note = masked ? '연락처·계좌·링크는 가려서 올렸어요' : null;
    } on ServerException catch (e) {
      note = e.message;
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.it;
    final hint = it.isMine
        ? '궁금한 점에 답해 주세요'
        : it.isGoing
        ? '예) 곤약젤리도 부탁돼요? 몇 시쯤 돌아오세요?'
        : '예) 몇 시까지 가면 될까요?';
    return StreamBuilder<List<RequestComment>>(
      stream: stream,
      builder: (context, snap) {
        final list = snap.data ?? const <RequestComment>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('댓글 ${list.length}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 4),
            const Text(
              '누구나 보는 공개 댓글이에요. 연락처는 쓰면 가려져요. 실제로 맡기거나 맡을 땐 아래 버튼으로 신청해 주세요.',
              style: TextStyle(fontSize: 12, color: AppColors.sub, height: 1.5),
            ),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('아직 댓글이 없어요', style: TextStyle(color: AppColors.faint, fontSize: 13)),
              ),
            for (final c in list)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Avatar(c.author, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(c.author, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              if (c.uid == it.ownerUid) ...[
                                const SizedBox(width: 4),
                                const Text('글쓴이', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.blue)),
                              ] else if (c.uid == widget.myUid) ...[
                                const SizedBox(width: 4),
                                const Text('나', style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
                              ],
                              const SizedBox(width: 6),
                              Text(dateTimeLabel(c.createdAt), style: const TextStyle(fontSize: 11.5, color: AppColors.faint)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(c.text, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.ink2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    maxLength: 300,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(hintText: hint, counterText: '', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 64,
                  child: BigButton(label: sending ? '…' : '등록', height: 44, onTap: sending ? null : _send),
                ),
              ],
            ),
            if (note != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(note!, style: const TextStyle(fontSize: 12, color: AppColors.sub)),
              ),
          ],
        );
      },
    );
  }
}
