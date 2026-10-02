import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../../core/widgets/surface.dart';
import '../../../dayjob/data/day_jobs.dart';
import '../../../deals/data/member_deals.dart';
import '../../data/home_ads.dart';
import '../../models/task_item.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/task_card.dart';
import 'home_content.dart';
import 'home_nav.dart';
import '../../services/nearby_query.dart';
import 'widgets/going_board.dart';
import 'widgets/home_buttons.dart';
import 'widgets/nearby_section.dart';
import 'widgets/pick_carousel.dart';

/// 홈 '돈벌기' 갈래.
///
/// 겸이 카드 → 이번 달 번 금액 → 이거 하나 하고 갈래요? → 지금 내 주변 부탁 →
/// 광고 → 가는 김에 → 우리 동네 혜택 → 해외 부탁 → 미션·공구
class HomeEarnTab extends StatelessWidget {
  final HomeContent home;
  final HomeNav nav;
  final NearbyQuery query;
  final ValueChanged<NearbyQuery> onQuery;

  /// '지금 내 주변 부탁' 카드에 붙이는 키. 겸이 카드의 버튼이 여기로 스크롤한다.
  final GlobalKey nearbyKey;
  final VoidCallback onShowNearby;

  const HomeEarnTab({
    super.key,
    required this.home,
    required this.nav,
    required this.query,
    required this.onQuery,
    required this.nearbyKey,
    required this.onShowNearby,
  });

  @override
  Widget build(BuildContext context) {
    final tasks = query.apply(home.items, home.scope);
    final jobs = List.of(dayJobs)..sort((a, b) => b.pay - a.pay);

    return Column(
      children: [
        HeroCard(
          sub: '누구나 할 수 있는 부업',
          title: '가는 김에 도와주고\n**수익**을 만들어요',
          liveBold: '내 주변 부탁 ${tasks.length}건',
          liveRest: '· ${query.radiusLabel} 이내 · 지금 지원할 수 있어요',
          floats: const ['wallet', 'trend', 'sparkles', 'hand'],
          cta: '지금 할 수 있는 일 보기',
          ctaIcon: 'pin',
          onCta: onShowNearby,
          note: '학생도, 선생님도, 어르신도 시간 날 때 함께해요',
          compact: true,
        ),
        _MonthEarned(amount: home.monthEarn, onOpenPay: home.goPay),
        if (tasks.isNotEmpty) PickCarousel(picks: tasks.take(5).toList(), onOpen: nav.openTask),
        NearbySection(
          key: nearbyKey,
          query: query,
          onQuery: onQuery,
          tasks: tasks,
          jobs: jobs,
          scope: home.scope,
          grabbed: home.actions.grabbed,
          onOpenTask: nav.openTask,
          onOpenJob: nav.openDayJobDetail,
          onOpenAllTasks: nav.localHub,
          onOpenAllJobs: nav.dayJobs,
        ),
        AdBanner(ads: homeAds, onTap: nav.openAd),
        GoingBoard(
          posts: home.items.where((i) => i.mode == 'together' && NearbyQuery.inScope(i, home.scope)).toList(),
          onOpenAll: nav.community,
          onOpen: nav.openTask,
        ),
        _LocalBenefit(onOpen: nav.saveHub),
        _OverseasStrip(
          items: home.items.where((i) => i.mode == 'sea').toList(),
          onOpen: nav.openTask,
          onOpenAll: home.goOverseasTab,
        ),
        _Bridge(onTap: () => home.goSideTab(0)),
        const FootNote('공개된 장소에서 만나고, 대화·정산은 앱 안에서 남겨 주세요'),
      ],
    );
  }
}

/// 이번 달 내가 번 금액
class _MonthEarned extends StatelessWidget {
  final int amount;
  final VoidCallback onOpenPay;
  const _MonthEarned({required this.amount, required this.onOpenPay});

  @override
  Widget build(BuildContext context) {
    return SecCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('이번 달 내가 번 금액', style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w500)),
                const SizedBox(height: 3),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: nf(amount)),
                      const TextSpan(text: '원', style: TextStyle(fontSize: 17)),
                    ],
                  ),
                  style: const TextStyle(fontSize: 26, fontWeight: AppType.w700, color: AppColors.ink, letterSpacing: -1.04),
                ),
              ],
            ),
          ),
          SoftPillButton(label: '지갑', onTap: onOpenPay),
        ],
      ),
    );
  }
}

/// 우리 동네 혜택 — 회원 전용가 한 장
class _LocalBenefit extends StatelessWidget {
  final VoidCallback onOpen;
  const _LocalBenefit({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final d = memberDeals.where((d) => d.menu != 'finance').firstOrNull;
    if (d == null) return const SizedBox.shrink();
    return SecCard(
      child: Column(
        children: [
          SecHead(title: '우리 동네 혜택', action: '혜택 전체보기', onAction: onOpen),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Material(
              color: AppColors.page,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onOpen,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconTile(icon: d.icon, bg: const Color(0xFFF0EDEA), fg: const Color(0xFF6B4A2E), size: 64, iconSize: 30),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.brand,
                              style: AppType.body.copyWith(fontWeight: AppType.w600, color: AppColors.ink2),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text(
                                d.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.body.copyWith(fontSize: 16, fontWeight: AppType.w700),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                [if (d.isPriced) '회원가 ${nf(d.memberPrice)}원', d.area].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.meta.copyWith(fontWeight: AppType.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (d.isPriced) StatusBadge.red('${d.percent}%'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 여행 가는 길에, 해외 부탁 — 가로로 넘기는 카드
class _OverseasStrip extends StatelessWidget {
  /// 해외 부탁 전체 (마감 포함). 화면에는 마감 안 된 것만 올린다.
  final List<TaskItem> items;
  final void Function(TaskItem) onOpen;
  final VoidCallback onOpenAll;
  const _OverseasStrip({required this.items, required this.onOpen, required this.onOpenAll});

  @override
  Widget build(BuildContext context) {
    final open = items.where((i) => !i.isExpired).take(6).toList();
    if (open.isEmpty) return const SizedBox.shrink();
    return SecCard(
      child: Column(
        children: [
          SecHead(
            title: '여행 가는 길에, 해외 부탁',
            count: '${items.length}',
            action: '전체',
            onAction: onOpenAll,
            sub: '사다주고 부탁 비용 받기 · 상품가는 요청자가 선결제해요',
          ),
          SizedBox(
            height: 151,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: open.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _OverseasCard(it: open[i], onOpen: () => onOpen(open[i])),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverseasCard extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onOpen;
  const _OverseasCard({required this.it, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.page,
      borderRadius: BorderRadius.circular(AppRadius.surface),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.surface),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CountryFlag(cc: it.cc, size: 30, radius: 9),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      seaPlace(it),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.meta.copyWith(fontWeight: AppType.w700),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  it.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.body.copyWith(fontSize: 15, fontWeight: AppType.w700, height: 1.35),
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      '부탁 비용\n영수증으로 정산',
                      style: AppType.caption.copyWith(fontSize: 11.5, fontWeight: AppType.w600, height: 1.45),
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: nf(it.price)),
                        const TextSpan(text: '원', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    style: const TextStyle(fontSize: 18, fontWeight: AppType.w700, color: AppColors.ink, letterSpacing: -0.54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 미션·공구 탭으로 넘어가는 한 줄
class _Bridge extends StatelessWidget {
  final VoidCallback onTap;
  const _Bridge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.surface),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.surface),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const IconTile(icon: 'gift', bg: Color(0xFFFBF5E6), fg: Color(0xFFD99A00)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('미션·공구로 더 벌기', style: AppType.body.copyWith(fontWeight: AppType.w700)),
                      Text('설문·체험 미션, 공동구매', style: AppType.meta.copyWith(fontWeight: AppType.w600)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
