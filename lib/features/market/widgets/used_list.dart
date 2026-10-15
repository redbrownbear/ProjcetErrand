import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/kit.dart';
import '../../../core/widgets/surface.dart';
import '../../errand/models/task_item.dart';
import '../models/used_item.dart';
import 'used_art.dart';

/// 마켓 › 중고장터 · 나눔 (v77). 다른 동네 물건은 '가는 길 전달'로 이웃에게 맡긴다.

class UsedTab extends StatefulWidget {
  final AppNav nav;
  final List<TaskItem> items;
  const UsedTab({super.key, required this.nav, required this.items});
  @override
  State<UsedTab> createState() => UsedTabState();
}

class UsedTabState extends State<UsedTab> {
  int f = 0;

  @override
  Widget build(BuildContext context) {
    final nav = widget.nav;
    return ListenableBuilder(
      listenable: nav.store,
      builder: (context, _) {
        final deliveries = widget.items.where((i) => i.extra == 'used' && !i.isExpired).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Row(
                children: [
                  _pill('${nav.area()} 물건', f == 0, () => setState(() => f = 0)),
                  const SizedBox(width: 6),
                  _pill('가는 길 전달', f == 1, () => setState(() => f = 1)),
                ],
              ),
            ),
            if (f == 0)
              for (final u in nav.store.used.where((u) => !u.share))
                UsedRow(u: u, liked: nav.store.likedUsed.contains(u.id), onTap: () => nav.openUsed(context, u))
            else ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 6, 20, 6),
                child: Text('다른 동네에서 거래한 물건을 가는 길에 전달해 주면 전달비를 받아요.', style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [for (final it in deliveries) EarnRow(it: it, onTap: () => nav.openTask(context, it))],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _pill(String label, bool on, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: on ? AppColors.ink : Colors.transparent, borderRadius: BorderRadius.circular(19)),
      child: Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: on ? Colors.white : AppColors.ink2),
      ),
    ),
  );
}

class ShareTab extends StatelessWidget {
  final AppNav nav;
  const ShareTab({super.key, required this.nav});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: nav.store,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Text(
              '${nav.area()} 이웃이 나눔하는 물건이에요. 필요한 분이 가져가세요.',
              style: const TextStyle(fontSize: 13, color: AppColors.sub),
            ),
          ),
          for (final u in nav.store.used.where((u) => u.share))
            UsedRow(u: u, liked: nav.store.likedUsed.contains(u.id), onTap: () => nav.openUsed(context, u)),
        ],
      ),
    );
  }
}

/// 중고 · 나눔 목록 한 줄 (사진 + 제목 + 가격 + 채팅·관심)
class UsedRow extends StatelessWidget {
  final UsedItem u;
  final bool liked;
  final VoidCallback onTap;
  const UsedRow({super.key, required this.u, required this.liked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      radius: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UsedArt(u.art),
            const SizedBox(width: 14),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 98),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      u.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.35),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${u.area}${u.distM > 0 ? ' · ${u.distLabel}' : ''} · ${u.ago}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.sub),
                    ),
                    const SizedBox(height: 3),
                    u.share
                        ? const StatusBadge('나눔', bg: AppColors.greenSoft, fg: AppColors.greenDeep)
                        : Text(won(u.price), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (u.chats > 0) ...[
                          const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.sub),
                          const SizedBox(width: 3),
                          Text('${u.chats}', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 14,
                          color: liked ? AppColors.red : AppColors.sub,
                        ),
                        const SizedBox(width: 3),
                        Text('${u.likes + (liked ? 1 : 0)}', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 돈벌기 목록 한 줄 (.row)
class EarnRow extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onTap;
  final int tickets;
  const EarnRow({super.key, required this.it, required this.onTap, this.tickets = 3});

  @override
  Widget build(BuildContext context) {
    final used = it.extra == 'used';
    final tone = AppColors.taskIcon[used ? 'used' : it.cat] ?? AppColors.taskIconFallback;
    return Tap(
      onTap: onTap,
      radius: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(14)),
              child: Icon(used ? Icons.storefront_outlined : AppIcon.cat(it.cat), size: 23, color: tone.fg),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    it.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      it.place ?? '',
                      if (it.distM != null) distLabel(it),
                      if (it.mins > 0) '약 ${it.mins}분',
                    ].where((s) => s.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.sub),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (used)
                  const StatusBadge('중고', bg: Color(0xFFE6F6EE), fg: AppColors.greenDeep)
                else if (it.hot)
                  const StatusBadge('급해요', bg: AppColors.redSoft, fg: AppColors.red)
                else
                  const StatusBadge.green('지금 가능'),
                const SizedBox(height: 3),
                Text(won(it.price), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.45)),
                const SizedBox(height: 3),
                TicketChip(tickets, boxed: false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
