import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/kit.dart';
import '../../../core/widgets/surface.dart';
import '../../errand/data/countries.dart';
import '../../proposal/models/proposal.dart';
import '../models/com_post.dart';

/// 커뮤니티 글 한 칸. 흰 카드 안에서 줄로 이어진다.
class ComPostTile extends StatelessWidget {
  final ComPost p;
  final bool liked;
  final VoidCallback onTap;
  final bool showPlace;
  const ComPostTile({super.key, required this.p, required this.liked, required this.onTap, this.showPlace = false});

  @override
  Widget build(BuildContext context) {
    final tone = kindTone(p.kind);
    final place = p.scope == 'abroad' ? countryOf(p.place).name : p.place;
    return Tap(
      onTap: onTap,
      radius: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusBadge(p.kind, bg: tone.bg, fg: tone.fg),
                if (showPlace && place.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  StatusBadge(place, bg: AppColors.page, fg: AppColors.ink2),
                ],
                const Spacer(),
                Text(p.ago, style: const TextStyle(fontSize: 12, color: AppColors.faint)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              p.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.4,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              p.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppColors.sub, height: 1.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 15,
                  color: liked ? AppColors.red : AppColors.faint,
                ),
                const SizedBox(width: 4),
                Text('${p.likes + (liked ? 1 : 0)}', style: const TextStyle(fontSize: 13, color: AppColors.faint)),
                const SizedBox(width: 14),
                const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.faint),
                const SizedBox(width: 4),
                Text('${p.comments.length}', style: const TextStyle(fontSize: 13, color: AppColors.faint)),
                const Spacer(),
                Text(
                  p.author,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.faint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 피드 사이에 글처럼 섞이는 제안 카드 (시안 v44 '커뮤니티와 제안이 이어져요')
class ProposalFeedTile extends StatelessWidget {
  final Proposal p;
  final bool meJoined;
  final VoidCallback onOpen;
  final VoidCallback onJoin;
  const ProposalFeedTile({super.key, required this.p, required this.meJoined, required this.onOpen, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final status = p.status(meJoined);
    final closed = status == '마감';
    final where = p.abroad ? '${p.from} · ${countryOf(p.cc).name}' : '${p.from} → ${p.to}';
    final count = p.countWith(meJoined);
    return Tap(
      onTap: onOpen,
      radius: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFCF0),
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const StatusBadge('제안', bg: AppColors.yellowSoft, fg: AppColors.yellowDeep),
                const SizedBox(width: 6),
                StatusBadge(where, bg: AppColors.page, fg: AppColors.ink2),
                const Spacer(),
                Text(p.ago, style: const TextStyle(fontSize: 12, color: AppColors.faint)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              p.headline,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                height: 1.4,
                letterSpacing: -0.4,
              ),
            ),
            if (p.departVerified)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: StatusBadge('출국 확인', bg: AppColors.greenSoft, fg: AppColors.greenDeep),
              ),
            const SizedBox(height: 6),
            Text(
              '${p.item} · ${won(p.price)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink2),
            ),
            const SizedBox(height: 2),
            Text(
              p.unlimited ? '$count명 요청 중' : (closed ? '$count/${p.max}명 · 마감' : '$count/${p.max}명 · ${p.left(meJoined)}자리 남음'),
              style: const TextStyle(fontSize: 12.5, color: AppColors.sub),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: BigButton(
                label: meJoined ? '구매 요청함 ✓' : (closed ? '마감' : '저 구매할래요!'),
                height: 42,
                bg: meJoined ? AppColors.page : AppColors.yellow,
                onTap: closed && !meJoined ? null : onJoin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
