import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/surface.dart';
import '../../../models/task_item.dart';
import 'home_buttons.dart';

/// '가는 김에' — 이웃들이 함께할 사람을 찾는 글 두 개. '같이해요' 글을 보여 준다.
class GoingBoard extends StatelessWidget {
  final List<TaskItem> posts;
  final VoidCallback onOpenAll;
  final void Function(TaskItem) onOpen;
  const GoingBoard({super.key, required this.posts, required this.onOpenAll, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 4, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('가는 김에', style: AppType.sectionSmall),
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text('이웃들은 지금 무엇을 함께하고 싶을까요?', style: AppType.meta.copyWith(fontSize: 12.5)),
                      ),
                    ],
                  ),
                ),
                OutlineSmallButton(icon: 'pencil', label: '글쓰기', onTap: onOpenAll),
                const SizedBox(width: 6),
                TextLink(label: '전체보기', onTap: onOpenAll),
              ],
            ),
          ),
          for (final p in posts.take(2)) ...[_GoingCard(it: p, onOpen: () => onOpen(p)), const SizedBox(height: 8)],
        ],
      ),
    );
  }
}

class _GoingCard extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onOpen;
  const _GoingCard({required this.it, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final who = it.who.isEmpty ? '이웃' : it.who;
    final tone = it.id.isEven ? AppColors.blue : AppColors.green;
    final where = [shortRegion(it.region ?? ''), it.ago ?? '', if (it.sample) '예시'].where((s) => s.isNotEmpty).join(' · ');

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: tone.withValues(alpha: 0.14), shape: BoxShape.circle),
                    child: Text(
                      who.characters.first,
                      style: TextStyle(fontSize: 11, fontWeight: AppType.w700, color: tone),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$who  ',
                            style: const TextStyle(fontWeight: AppType.w600, color: AppColors.ink2),
                          ),
                          TextSpan(text: where),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.meta,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  it.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.body.copyWith(fontSize: 14.5, fontWeight: AppType.w700, letterSpacing: -0.43),
                ),
              ),
              if (it.desc.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    '“${it.desc}”',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.body.copyWith(fontSize: 13, color: AppColors.ink2),
                  ),
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.mode_comment_outlined, size: 14, color: AppColors.sub),
                  const SizedBox(width: 4),
                  Text('댓글 ${it.comments.length}', style: AppType.meta.copyWith(fontSize: 12.5, fontWeight: AppType.w500)),
                  const Spacer(),
                  OutlineSmallButton(label: it.joinMax > 0 ? '같이하기' : '보러가기', onTap: onOpen),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
