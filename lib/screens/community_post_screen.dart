import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/comment.dart';
import '../models/task_item.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';

class CommunityPostScreen extends StatefulWidget {
  final TaskItem it;
  final List<int> grabbed;
  final VoidCallback onClose;
  final void Function(TaskItem) onGrab;
  const CommunityPostScreen({super.key, required this.it, required this.grabbed, required this.onClose, required this.onGrab});
  @override
  State<CommunityPostScreen> createState() => _CommunityPostScreenState();
}

class _CommunityPostScreenState extends State<CommunityPostScreen> {
  late List<Comment> comments = List.of(widget.it.comments);
  final txtCtrl = TextEditingController();
  bool liked = false;

  @override
  void dispose() {
    txtCtrl.dispose();
    super.dispose();
  }

  void _addComment() {
    final t = txtCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      comments.add(Comment('나', t));
      txtCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.it;
    final t = tcatOf(it.tcat);
    final done = widget.grabbed.contains(it.id);

    return Positioned.fill(
      child: Material(
        color: AppColors.page,
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            height: 52,
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(color: AppColors.card, border: Border(bottom: BorderSide(color: AppColors.line))),
            child: Row(children: [
              InkWell(onTap: widget.onClose, borderRadius: BorderRadius.circular(99), child: const Padding(padding: EdgeInsets.only(right: 2), child: Text('‹', style: TextStyle(fontSize: 24, color: AppColors.ink)))),
              Text('같이해요 · ${t.label}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 42, height: 42, alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.yellowSoft, shape: BoxShape.circle),
                      child: const Text('🙂', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                              children: [
                                TextSpan(text: it.who),
                                if (it.verified) const TextSpan(text: ' ✓ 본인인증', style: TextStyle(fontSize: 12, color: AppColors.green)),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text('${shortRegion(it.region ?? '')} · ${it.ago ?? ''} · ★ ${it.rating.toStringAsFixed(1)} · 거래 ${it.deals}회', style: const TextStyle(fontSize: 12, color: AppColors.sub)),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Text(it.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.35)),
                  const SizedBox(height: 8),
                  Text(it.desc, style: const TextStyle(fontSize: 14.5, color: AppColors.ink, height: 1.7)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)),
                        child: Column(children: [
                          const Text('장소', style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
                          const SizedBox(height: 2),
                          Text(it.place ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        ]),
                      ),
                    ),
                    if (it.joinMax > 0) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(12)),
                          child: Column(children: [
                            const Text('참여 인원', style: TextStyle(fontSize: 11.5, color: Color(0xFF1B8A5A))),
                            const SizedBox(height: 2),
                            Text('${it.joinCur}/${it.joinMax}명', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.green)),
                          ]),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => liked = !liked),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: liked ? AppColors.yellowSoft : AppColors.page, borderRadius: BorderRadius.circular(12)),
                          child: Column(children: [
                            const Text('관심', style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
                            const SizedBox(height: 2),
                            Text('🙋 ${it.likes + (liked ? 1 : 0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(12)),
                    child: const Text('🛡 안전한 장소에서 만나요 — 공개된 장소 권장 · 개인 연락처 노출 최소화 · 앱 내 채팅 이용 · 신고/차단 제공', style: TextStyle(fontSize: 12, color: Color(0xFF1B8A5A), height: 1.6, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 18),
                  Text('댓글 ${comments.length}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  if (comments.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('첫 댓글을 남겨보세요.', style: TextStyle(fontSize: 12.5, color: AppColors.sub))),
                  for (final c in comments)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 30, height: 30, alignment: Alignment.center,
                          decoration: const BoxDecoration(color: AppColors.page, shape: BoxShape.circle),
                          child: const Text('🙂', style: TextStyle(fontSize: 14)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.who, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                              Padding(padding: const EdgeInsets.only(top: 2), child: Text(c.text, style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.5))),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                          controller: txtCtrl,
                          decoration: InputDecoration(
                            hintText: '댓글 달기…',
                            filled: true, fillColor: AppColors.card,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _addComment,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(color: txtCtrl.text.trim().isNotEmpty ? AppColors.ink : AppColors.line, borderRadius: BorderRadius.circular(12)),
                          child: Text('등록', style: TextStyle(color: txtCtrl.text.trim().isNotEmpty ? Colors.white : AppColors.faint, fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.line))),
            child: done
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(14)),
                    child: const Text('신청 완료 ✓ 채팅에서 이어가요', textAlign: TextAlign.center, style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w800, fontSize: 15)),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => widget.onGrab(it),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('같이하기', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}
