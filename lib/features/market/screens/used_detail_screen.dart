import 'package:flutter/material.dart';

import '../../../app/neighbor_store.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/kit.dart';
import '../models/used_item.dart';
import '../widgets/used_art.dart';

/// 중고 · 나눔 물건 상세.
///
/// 거래 장소가 멀면 '전달 부탁하기'로 이웃에게 운반을 맡긴다. 그 부탁은
/// 돈벌기 목록에 '중고' 배지를 달고 올라간다(시안 v42).
class UsedDetailScreen extends StatelessWidget {
  final NeighborStore store;
  final UsedItem item;
  final void Function(UsedItem) onDeliver;
  final void Function(String) flash;
  const UsedDetailScreen({super.key, required this.store, required this.item, required this.onDeliver, required this.flash});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final liked = store.likedUsed.contains(item.id);
        return PageFrame(
          title: item.share ? '나눔' : '중고장터',
          background: AppColors.card,
          bottom: Row(
            children: [
              GestureDetector(
                onTap: () => store.toggleUsedLike(item.id),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(14)),
                  child: Icon(
                    liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: liked ? AppColors.red : AppColors.sub,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BigButton(
                  label: '전달 부탁하기',
                  bg: AppColors.page,
                  fg: AppColors.ink2,
                  onTap: item.mine ? null : () => onDeliver(item),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BigButton(
                  label: item.share ? '나눔 받기' : '채팅하기',
                  bg: AppColors.ink,
                  fg: Colors.white,
                  onTap: item.mine ? null : () => flash('채팅은 연결 준비 중이에요 · 관심 저장으로 먼저 찜해 두세요'),
                ),
              ),
            ],
          ),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AspectRatio(
                  aspectRatio: 1.3,
                  child: LayoutBuilder(builder: (_, b) => UsedArt(item.art, size: b.maxWidth, radius: 20)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Avatar(item.seller, size: 36),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.mine ? '나' : item.seller,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                            ),
                            Text(item.area, style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.4, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.area}${item.distM > 0 ? ' · ${item.distLabel}' : ''} · ${item.ago}',
                      style: const TextStyle(fontSize: 13, color: AppColors.sub),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.share ? '나눔' : won(item.price),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: item.share ? AppColors.green : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.desc.isEmpty ? '설명이 없어요' : item.desc,
                      style: const TextStyle(fontSize: 15, height: 1.7, color: AppColors.ink2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '채팅 ${item.chats} · 관심 ${item.likes + (liked ? 1 : 0)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.faint),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(14)),
                      child: const Text(
                        '거래 장소가 멀다면 \'전달 부탁하기\'로 가는 길인 이웃에게 운반을 맡길 수 있어요. 전달비는 직접 정해요.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.sub, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
