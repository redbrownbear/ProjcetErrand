import 'package:flutter/material.dart';

import '../../../app/neighbor_store.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../../errand/data/countries.dart';
import '../models/com_post.dart';

/// 커뮤니티 글 상세. 답글을 달 때마다 응모권 +1.
/// 후기 글이 제안에서 이어졌으면 그 제안으로 돌아가는 줄이 붙는다(시안 v44).
class ComPostScreen extends StatefulWidget {
  final NeighborStore store;
  final int postId;
  final void Function(int proposalId)? onOpenProposal;
  const ComPostScreen({super.key, required this.store, required this.postId, this.onOpenProposal});

  @override
  State<ComPostScreen> createState() => _ComPostScreenState();
}

class _ComPostScreenState extends State<ComPostScreen> {
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void _send() {
    final t = ctrl.text.trim();
    if (t.isEmpty) return;
    widget.store.addComment(widget.postId, t);
    ctrl.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final p = widget.store.postById(widget.postId);
        if (p == null) return const PageFrame(title: '이야기', child: SizedBox());
        final liked = widget.store.likedPosts.contains(p.id);
        final tone = kindTone(p.kind);
        final place = p.scope == 'abroad' ? countryOf(p.place).name : p.place;
        final linked = p.proposalId == null ? null : widget.store.proposalById(p.proposalId!);

        return PageFrame(
          title: p.scope == 'local' ? '우리 동네 이야기' : (p.scope == 'travel' ? '여행 이야기' : '해외 이야기'),
          background: AppColors.card,
          bottom: Row(children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(hintText: '답글 달면 응모권 +1'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 72, child: BigButton(label: '등록', height: 48, onTap: _send)),
          ]),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Row(children: [
                Pill(p.kind, bg: tone.bg, fg: tone.fg, fontSize: 12),
                if (place.isNotEmpty) ...[const SizedBox(width: 6), Pill(place, bg: AppColors.page, fg: AppColors.inkSoft, fontSize: 12)],
              ]),
              const SizedBox(height: 12),
              Text(p.title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, height: 1.4, letterSpacing: -0.6)),
              const SizedBox(height: 10),
              Row(children: [
                Avatar(p.author, size: 28),
                const SizedBox(width: 8),
                Text(p.author, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Text(p.ago, style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
              ]),
              const SizedBox(height: 16),
              Text(p.body, style: const TextStyle(fontSize: 15.5, height: 1.7, color: AppColors.inkSoft)),
              if (linked != null) ...[
                const SizedBox(height: 16),
                Tap(
                  onTap: () => widget.onOpenProposal?.call(linked.id),
                  radius: 14,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      const Icon(Icons.link_rounded, size: 18, color: AppColors.yellowInk),
                      const SizedBox(width: 8),
                      Expanded(child: Text('이어진 제안 · ${linked.headline}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.yellowInk),
                    ]),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(children: [
                GestureDetector(
                  onTap: () => widget.store.toggleLike(p.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: liked ? AppColors.red : AppColors.outline),
                    ),
                    child: Row(children: [
                      Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: liked ? AppColors.red : AppColors.sub),
                      const SizedBox(width: 5),
                      Text('좋아요 ${p.likes + (liked ? 1 : 0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: liked ? AppColors.red : AppColors.inkSoft)),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              Text('답글 ${p.comments.length}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              if (p.comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('첫 답글을 남겨 주세요', style: TextStyle(color: AppColors.faint)),
                ),
              for (final c in p.comments)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Avatar(c.who, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.who, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(c.text, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.inkSoft)),
                      ]),
                    ),
                  ]),
                ),
            ],
          ),
        );
      },
    );
  }
}
