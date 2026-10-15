import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../../../core/widgets/surface.dart';
import '../models/trip_post.dart';

/// 홈 · 해외 탭이 같이 쓰는 v77 조각 — 여행 도구 칸과 '가는 김에' 글 목록.

/// '여행 어디 갈까?' · '세계 제안 지도' 회색 도구 칸 (.pp-tools)
class TripTools extends StatelessWidget {
  final AppNav nav;
  final bool abroad;
  const TripTools({super.key, required this.nav, this.abroad = false});

  @override
  Widget build(BuildContext context) {
    final dart = ToolTile(
      lead: const _Target(),
      title: '여행 어디 갈까?',
      sub: abroad ? '다트를 던져 정해요' : '다트를 던져 정해요 · 명소·맛집·숙소까지',
      compact: abroad,
      onTap: () => nav.openDart(context, abroad: abroad),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: abroad
          ? Row(
              children: [
                Expanded(
                  child: ToolTile(
                    lead: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.public_rounded, size: 20, color: AppColors.blue),
                    ),
                    title: '세계 제안 지도',
                    sub: '나라별 제안, 요청 한눈에',
                    compact: true,
                    onTap: () => nav.openWorld(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: dart),
              ],
            )
          : dart,
    );
  }
}

class _Target extends StatelessWidget {
  const _Target();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.red, width: 5),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// 가는 김에 — 사람들은 지금 어디로 가고 있을까요? (.gkm)
class TripFeedSection extends StatelessWidget {
  final AppNav nav;
  final VoidCallback onAll;
  final int take;
  const TripFeedSection({super.key, required this.nav, required this.onAll, this.take = 2});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: nav.store,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('가는 김에', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                        SizedBox(height: 3),
                        Text('사람들은 지금 어디로 가고 있을까요?', style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
                      ],
                    ),
                  ),
                  LineButton(label: '글쓰기', icon: 'pencil', height: 28, onTap: () => nav.openTripForm(context)),
                  const SizedBox(width: 6),
                  TextLink(label: '전체보기', onTap: onAll),
                ],
              ),
            ),
            for (final t in nav.store.trips.take(take)) ...[
              TripCard(t: t, onCta: () => t.going ? nav.openAskForm() : nav.flash('도와주기 의사를 전했어요 · ${t.author} 님이 확인하면 채팅이 열려요')),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  final TripPost t;
  final VoidCallback onCta;
  const TripCard({super.key, required this.t, required this.onCta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(t.author),
              const SizedBox(width: 8),
              Text(t.mine ? '나' : t.author, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Text('${t.area} · ${t.ago}', style: const TextStyle(fontSize: 12, color: AppColors.sub)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (t.cc != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(5)),
                  child: Text(
                    t.cc!.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.ink2),
                  ),
                )
              else
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(5)),
                  child: const Icon(Icons.shopping_bag_outlined, size: 12, color: AppColors.ink2),
                ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  t.when,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.faint),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text('“${t.quote}”', style: const TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.sub),
              const SizedBox(width: 4),
              Text('댓글 ${t.comments}', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
              const Spacer(),
              if (!t.mine) LineButton(label: t.going ? '부탁하기' : '도와주기', onTap: onCta),
            ],
          ),
        ],
      ),
    );
  }
}
