import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../app/neighbor_store.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/kit.dart';
import '../data/proposals.dart';
import '../models/proposal.dart';
import '../../trip/widgets/trip_widgets.dart';

/// LIVE 제안 보드 (.pp-live) — "이동하는 길에, 필요한 분?" / "가는 김에 사다 드려요"
class LiveBoard extends StatelessWidget {
  final NeighborStore store;
  final bool abroad;
  final void Function(Proposal) onOpen;
  final VoidCallback onAll;
  final VoidCallback onPropose;
  final VoidCallback? onSponsor;
  const LiveBoard({
    super.key,
    required this.store,
    required this.abroad,
    required this.onOpen,
    required this.onAll,
    required this.onPropose,
    this.onSponsor,
  });

  @override
  Widget build(BuildContext context) {
    final list = store.board(abroad: abroad);
    final open = list.where((p) => !p.expired && !p.isFull(store.joined.contains(p.id))).length;
    final sponsor = abroad ? abroadSponsor : domesticSponsor;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.liveBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.liveLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _LiveTag(),
                    const SizedBox(height: 5),
                    Text(
                      abroad ? '가는 김에 사다 드려요' : '이동하는 길에, 필요한 분?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.9,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: abroad ? '해외 가는 이웃이 지금 올려요 · ' : '지역 간 이동 중인 이웃이 지금 올려요 · '),
                          TextSpan(
                            text: '$open',
                            style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
                          ),
                          const TextSpan(text: '건 모집 중'),
                        ],
                      ),
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.sub),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onAll,
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.fromLTRB(10, 0, 6, 0),
                  decoration: BoxDecoration(color: const Color(0xB3FFFFFF), borderRadius: BorderRadius.circular(15)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '전체',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink2),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.ink2),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          SponsorBoardRow(sponsor: sponsor, onTap: onSponsor),
          for (final p in list.take(4)) ...[
            const SizedBox(height: 6),
            ProposalRow(p: p, meJoined: store.joined.contains(p.id), onTap: () => onOpen(p)),
          ],
          const SizedBox(height: 13),
          BigButton(
            label: abroad ? '내가 가는 길에 제안하기' : '내가 이동하는 길에 제안하기',
            icon: 'plus',
            bg: AppColors.ink,
            fg: Colors.white,
            height: 48,
            onTap: onPropose,
          ),
          const SizedBox(height: 8),
          Text(
            '${abroad ? '가격과 인원을 정하면 이웃이 구매를 눌러요' : '다른 지역으로 이동할 때만 올릴 수 있어요'}'
            '${list.any((p) => !p.mine) ? '\n지금 보이는 제안은 체험용 예시예요' : ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.sub),
          ),
        ],
      ),
    );
  }
}

class _LiveTag extends StatefulWidget {
  const _LiveTag();
  @override
  State<_LiveTag> createState() => _LiveTagState();
}

class _LiveTagState extends State<_LiveTag> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'LIVE',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.red, letterSpacing: 0.9),
        ),
      ],
    );
  }
}

/// 경로 칩 — '여수 → 서울' 또는 'JP 도쿄'
class RouteChip extends StatelessWidget {
  final Proposal? p;
  final String? place;
  final String? cc;
  final bool dim;
  const RouteChip({super.key, this.p, this.place, this.cc, this.dim = false});

  @override
  Widget build(BuildContext context) {
    final abroad = p?.abroad ?? cc != null;
    final code = (p?.cc ?? cc)?.toUpperCase();
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(color: dim ? AppColors.faint : AppColors.ink, borderRadius: BorderRadius.circular(9)),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (abroad && code != null) ...[
            Text(
              code,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.yellow),
            ),
            const SizedBox(width: 4),
            Text(
              p?.from ?? place ?? '',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ] else if (p != null) ...[
            Text(
              p!.from,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                '→',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.yellow),
              ),
            ),
            Text(
              p!.to,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ] else
            Text(
              place ?? '',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

/// 보드 한 줄 (.pp-row)
class ProposalRow extends StatelessWidget {
  final Proposal p;
  final bool meJoined;
  final VoidCallback onTap;
  final Color bg;
  const ProposalRow({super.key, required this.p, required this.meJoined, required this.onTap, this.bg = AppColors.card});

  @override
  Widget build(BuildContext context) {
    final status = p.status(meJoined);
    final closed = status == '마감';
    final tag = dayTag(p.day);
    final statusColor = closed
        ? AppColors.green
        : status == '1자리'
        ? AppColors.red
        : AppColors.ink2;
    return Opacity(
      opacity: closed ? 0.55 : 1,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: meJoined ? Border.all(color: AppColors.yellow, width: 1.5) : null,
        ),
        child: Tap(
          onTap: onTap,
          radius: 12,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
            child: Row(
              children: [
                RouteChip(p: p, dim: closed),
                const SizedBox(width: 9),
                Expanded(
                  // 이름이 우선이다. 자리가 좁으면 날짜 태그를 뺀다.
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final showTag = box.maxWidth >= 110;
                      return Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.item,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          if (p.departVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 3),
                              child: Icon(Icons.check_rounded, size: 14, color: AppColors.green),
                            ),
                          if (showTag) ...[
                            const SizedBox(width: 5),
                            if (isNearDay(p.day) && !closed)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(color: const Color(0xFFFFF1C2), borderRadius: BorderRadius.circular(5)),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.yellowDeep,
                                  ),
                                ),
                              )
                            else
                              Text(
                                tag,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.faint),
                              ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  won(p.total),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.sub),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 38,
                  child: Text(
                    status,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: statusColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 보드 맨 위 제휴 줄 (.pp-row.ad)
class SponsorBoardRow extends StatelessWidget {
  final SponsorRow sponsor;
  final VoidCallback? onTap;
  const SponsorBoardRow({super.key, required this.sponsor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purpleLine, width: 1.5),
      ),
      child: Tap(
        onTap: onTap,
        radius: 12,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
          child: Row(
            children: [
              RouteChip(place: sponsor.place, cc: sponsor.cc),
              const SizedBox(width: 9),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        sponsor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(5)),
                      child: const Text(
                        'AD',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.purple, letterSpacing: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                sponsor.benefit,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.purple),
              ),
              const SizedBox(width: 10),
              const SizedBox(
                width: 38,
                child: Text(
                  '쿠폰',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 홈 · 해외 탭에 끼워 넣는 v77 묶음 — LIVE 제안 보드와 여행 도구 칸.
class LiveSection extends StatelessWidget {
  final AppNav nav;
  final bool abroad;
  const LiveSection({super.key, required this.nav, this.abroad = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListenableBuilder(
          listenable: nav.store,
          builder: (context, _) => LiveBoard(
            store: nav.store,
            abroad: abroad,
            onOpen: (p) => nav.openProposal(context, p),
            onAll: () => nav.openProposalList(context, abroad: abroad),
            onPropose: () => nav.openPropose(context, abroad: abroad),
            onSponsor: () => nav.flash('제휴 매장 쿠폰은 제휴가 확정되면 받을 수 있어요'),
          ),
        ),
        TripTools(nav: nav, abroad: abroad),
      ],
    );
  }
}
