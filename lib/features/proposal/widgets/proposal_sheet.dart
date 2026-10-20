import 'package:flutter/material.dart';

import '../../../app/neighbor_store.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/kit.dart';
import '../../../core/widgets/surface.dart';
import '../../community/models/com_post.dart';
import '../../errand/data/countries.dart';
import '../models/proposal.dart';
import 'live_board.dart';

/// 제안 상세 시트 (시안 v43~v44).
///
/// 물건·날짜·인원·결제 → 함께 요청한 이웃 → 그 지역 이웃 이야기 → '저 구매할래요!'.
/// 요청을 보낸 뒤에는 '후기 남기기'가 제목·지역이 채워진 채 열린다.
class ProposalSheet extends StatelessWidget {
  final NeighborStore store;
  final Proposal p;
  final void Function(ComPost) onOpenPost;
  final VoidCallback onMoreStories;
  final void Function(Proposal) onReview;
  final VoidCallback onOtherAsk;
  const ProposalSheet({
    super.key,
    required this.store,
    required this.p,
    required this.onOpenPost,
    required this.onMoreStories,
    required this.onReview,
    required this.onOtherAsk,
  });

  static Future<void> show(
    BuildContext context, {
    required NeighborStore store,
    required Proposal p,
    required void Function(ComPost) onOpenPost,
    required VoidCallback onMoreStories,
    required void Function(Proposal) onReview,
    required VoidCallback onOtherAsk,
  }) => showSheet(
    context,
    (_) => ProposalSheet(
      store: store,
      p: p,
      onOpenPost: onOpenPost,
      onMoreStories: onMoreStories,
      onReview: onReview,
      onOtherAsk: onOtherAsk,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final me = store.joined.contains(p.id);
        final count = p.countWith(me);
        final closed = p.expired || p.isFull(me) && !me;
        final stories = store.related(p).take(2).toList();
        final storyTitle = p.abroad ? '${countryOf(p.cc).name} 이웃 이야기' : '${p.from} · ${p.to} 이웃 이야기';

        return SheetFrame(
          bottom: Row(
            children: [
              Expanded(
                flex: 2,
                child: me
                    ? BigButton(
                        label: '후기 남기기',
                        bg: AppColors.page,
                        fg: AppColors.ink2,
                        height: 54,
                        onTap: () {
                          Navigator.pop(context);
                          onReview(p);
                        },
                      )
                    : BigButton(
                        label: '다른 부탁',
                        bg: AppColors.page,
                        fg: AppColors.ink2,
                        height: 54,
                        onTap: () {
                          Navigator.pop(context);
                          onOtherAsk();
                        },
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: BigButton(
                  label: me ? '구매 요청 취소' : (closed ? '마감됐어요' : (p.mine ? '내가 올린 제안' : '저 구매할래요!')),
                  bg: me ? AppColors.card : AppColors.ink,
                  fg: me ? AppColors.ink : Colors.white,
                  height: 54,
                  onTap: (closed && !me) || p.mine ? null : () => store.toggleJoin(p),
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: p.abroad ? AppColors.blueSoft : const Color(0xFFFFF1C2),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      p.abroad ? '${(p.cc ?? '').toUpperCase()} ${p.from}' : '${p.from} → ${p.to}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.abroad ? AppColors.blue : AppColors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _openStore(context),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                      decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(7)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.mine ? '내 스토어' : p.who,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.ink),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      [p.area, p.ago].where((s) => s.isNotEmpty).join(' · '),
                      style: const TextStyle(fontSize: 12, color: AppColors.sub),
                    ),
                  ),
                ],
              ),
              if (p.departVerified)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: const [
                      StatusBadge('출국 확인', bg: AppColors.greenSoft, fg: AppColors.greenDeep),
                      SizedBox(width: 6),
                      Text('항공권·탑승권을 확인했어요', style: TextStyle(fontSize: 12, color: AppColors.sub)),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                p.headline,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  height: 1.4,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: nf(p.total),
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1),
                    ),
                    const TextSpan(
                      text: '원 · 1명당',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                style: const TextStyle(color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              const _CheckLine('영수증 기준 가격이에요 · 실제 금액보다 높게 적은 부분은 환불돼요', color: AppColors.sub),
              const SizedBox(height: 12),
              _row('1명당', p.fee > 0 ? '물건값 ${won(p.price)} + 심부름료 ${won(p.fee)}' : '물건값 ${won(p.price)} · 심부름료 없음'),
              _row('사 오는 물건', [p.item, ?p.spec].join(' · ')),
              _row(p.abroad ? '출국하는 날' : '이동하는 날', '${p.day.month}/${p.day.day}'),
              _row('모집 인원', p.unlimited ? '$count명 · 제한 없음' : '$count/${p.max}명 · ${p.left(me)}자리 남음'),
              _row('결제', '만나서 직접 주고받아요 · 앱 결제는 준비 중'),
              if (p.note.isNotEmpty) _row('한마디', p.note),
              const SizedBox(height: 14),
              const Text(
                '함께 요청한 이웃',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sub),
              ),
              const SizedBox(height: 8),
              if (count == 0)
                const Text('아직 요청한 이웃이 없어요', style: TextStyle(fontSize: 13, color: AppColors.faint))
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // 프로필 공개 이웃은 노랑, 비공개는 회색 (시안 v44-2)
                    for (var i = 0; i < count; i++)
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: me && i == count - 1 ? AppColors.yellow : (i.isEven ? const Color(0xFFFFE89A) : AppColors.soft2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          me && i == count - 1 ? '나' : '',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 18),
              Text(
                storyTitle,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sub),
              ),
              const SizedBox(height: 6),
              if (stories.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('아직 이 지역 이야기가 없어요', style: TextStyle(fontSize: 13, color: AppColors.faint)),
                ),
              for (final s in stories)
                Tap(
                  onTap: () => onOpenPost(s),
                  radius: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.line)),
                    ),
                    child: Row(
                      children: [
                        StatusBadge(s.kind, bg: AppColors.page, fg: AppColors.ink2),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextLink(label: '이야기 더 보기', onTap: onMoreStories),
              ),
              const SizedBox(height: 10),
              const _CheckLine('영수증을 확인한 뒤 정산돼요 · 정원이 차면 자동으로 마감돼요', color: AppColors.green, bold: true),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String k, String v) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.line)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(k, style: const TextStyle(fontSize: 14, color: AppColors.sub)),
        ),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
        ),
      ],
    ),
  );

  /// 제안자 스토어 — 이 이웃이 올린 다른 제안
  void _openStore(BuildContext context) {
    final mine = store.proposals.where((x) => x.who == p.who).toList();
    showSheet(
      context,
      (ctx) => SheetFrame(
        title: p.mine ? '내 스토어' : '${p.who} 스토어',
        sub: '이 이웃이 올린 제안이에요',
        child: Column(
          children: [
            for (final x in mine) ...[
              ProposalRow(
                p: x,
                meJoined: store.joined.contains(x.id),
                bg: AppColors.page,
                onTap: () {
                  Navigator.pop(ctx);
                  if (x.id != p.id) {
                    show(
                      context,
                      store: store,
                      p: x,
                      onOpenPost: onOpenPost,
                      onMoreStories: onMoreStories,
                      onReview: onReview,
                      onOtherAsk: onOtherAsk,
                    );
                  }
                },
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  final String text;
  final Color color;
  final bool bold;
  const _CheckLine(this.text, {required this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.check_rounded, size: 15, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.5, color: color, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, height: 1.5),
          ),
        ),
      ],
    );
  }
}
