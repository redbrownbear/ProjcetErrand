import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../../core/widgets/surface.dart';
import '../../../deals/data/member_deals.dart';
import '../../data/categories.dart';
import '../../data/home_ads.dart';
import '../../widgets/ad_banner.dart';
import 'home_content.dart';
import 'home_nav.dart';
import '../../services/nearby_query.dart';
import 'widgets/all_services_sheet.dart';
import 'widgets/going_board.dart';

/// 홈 '부탁하기' 갈래.
///
/// 겸이 카드 → 이런 것도 부탁해도 돼요 → 광고 → 자주 하는 부탁 → 주요 서비스 3개 →
/// 바로가기 4개 → 우리 동네 제휴 가게 → 가는 김에
class HomeAskTab extends StatelessWidget {
  final HomeContent home;
  final HomeNav nav;

  /// 돈벌기로 넘어가 '지금 내 주변 부탁'을 보여 준다. [kind]는 ask | job.
  final void Function(String kind) onShowNearby;

  const HomeAskTab({super.key, required this.home, required this.nav, required this.onShowNearby});

  /// '이런 것도 부탁해도 돼요' 예시. 실제 부탁이 아니라 이런 것도 올려도 된다는 안내다.
  /// 마지막 값은 눌렀을 때 미리 골라 둘 부탁 종류이고, sea는 해외 부탁 쓰기다.
  static const _examples = [
    (icon: 'box', title: '먼 곳 맛집 음식 배달해주기', color: AppColors.blue, target: 'pickup'),
    (icon: 'wrench', title: '막힌 변기 뚫어주기', color: AppColors.green, target: 'etc'),
    (icon: 'bug', title: '바퀴벌레 잡아주기', color: Color(0xFFE57A16), target: 'etc'),
    (icon: 'globe', title: '일본에서 굿즈 사다주기', color: AppColors.red, target: 'sea'),
    (icon: 'pet', title: '강아지 잠깐 봐주기', color: Color(0xFFD99A00), target: 'pet'),
    (icon: 'cart', title: '코스트코 가는 사람에게 장보기 부탁', color: AppColors.purple, target: 'buy'),
  ];

  @override
  Widget build(BuildContext context) {
    // 겸이 카드의 한 줄은 지어낸 거래 소식이 아니라 실제로 올라온 부탁에서 뽑는다.
    final asks = home.items.where((i) => i.mode == 'ask' && !i.isExpired && NearbyQuery.inScope(i, home.scope)).toList()
      ..sort((a, b) => (a.sample ? 1 : 0) - (b.sample ? 1 : 0));
    final latest = asks.firstOrNull;

    return Column(
      children: [
        HeroCard(
          sub: '가는 길에, 하나 더',
          title: '무엇이든 부탁해요\n**가까운 이웃**이 도와드려요',
          liveBold: latest?.title,
          liveRest: latest == null ? null : [shortRegion(latest.region ?? home.scope), latest.sample ? '예시' : '새 부탁'].join(' · '),
          floats: const ['box', 'bag', 'heart', 'pet'],
          cta: '부탁하기',
          ctaIcon: 'plus',
          onCta: home.goPost,
          note: '누구나 가는 김에 도와주고 수익을 얻을 수 있어요',
        ),
        ExampleRotator(
          question: '이런 것도 부탁해도 돼요',
          items: [for (final e in _examples) (icon: e.icon, title: e.title, color: e.color)],
          onTap: (i) {
            final target = _examples[i].target;
            target == 'sea' ? home.goPostSea() : home.goPostCat(target);
          },
          footLabel: '목록에 없어도 괜찮아요. 어떤 부탁이든 올려보세요',
          onFoot: home.goPost,
        ),
        AdBanner(ads: homeAds, onTap: nav.openAd),
        _FrequentCats(onPick: home.goPostCat),
        _services(),
        _quickRow(context),
        _PartnerShops(onOpen: nav.saveHub),
        GoingBoard(
          posts: home.items.where((i) => i.mode == 'together' && NearbyQuery.inScope(i, home.scope)).toList(),
          onOpenAll: nav.community,
          onOpen: nav.openTask,
        ),
        const FootNote('이웃에게 직접 부탁하려면 마이 › 지원한 부탁에서 이어서 진행해요'),
      ],
    );
  }

  Widget _services() {
    final seaCount = home.items.where((i) => i.mode == 'sea').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Row(
        children: [
          Expanded(
            child: _ServiceTile(
              icon: 'hand',
              title: '동네 부탁',
              sub: '가까운 곳에서 하나 더',
              bg: const Color(0xFFFFF4D6),
              fg: const Color(0xFFD99A00),
              onTap: () => onShowNearby('ask'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ServiceTile(
              icon: 'globe',
              title: '해외 부탁',
              sub: seaCount > 0 ? '${nf(seaCount)}건 모집 중' : '여행길에 사다줘요',
              bg: const Color(0xFFE8F0FE),
              fg: AppColors.blue,
              onTap: home.goOverseasTab,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ServiceTile(
              icon: 'brief',
              title: '단기알바',
              sub: '하루만 도와줘요',
              bg: AppColors.purpleSoft,
              fg: AppColors.purple,
              onTap: () => onShowNearby('job'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickRow(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.tile)),
      child: Row(
        children: [
          _QuickItem(icon: 'gift', label: '미션', onTap: () => home.goSideTab(0)),
          _QuickItem(icon: 'cart', label: '공동구매', onTap: () => home.goSideTab(1)),
          _QuickItem(icon: 'pencil', label: '가는 김에', onTap: nav.community),
          _QuickItem(
            icon: 'sparkles',
            label: '전체',
            onTap: () => showAllServicesSheet(context, [
              ('handshake', '동네 부탁 전체', nav.localHub),
              ('globe', '해외 부탁', home.goOverseasTab),
              ('brief', '단기알바', nav.dayJobs),
              ('users', '같이해요', nav.community),
              ('gift', '제휴 미션', nav.earnHub),
              ('check', '매일 미션', nav.dailyMissions),
              ('cart', '공동구매', () => home.goSideTab(1)),
              ('store', '회원 전용가', nav.saveHub),
              ('ticket', '포인트샵', nav.shop),
              ('map', '지도로 보기', () => nav.fullMap(const NearbyQuery().apply(home.items, home.scope))),
            ]),
          ),
        ],
      ),
    );
  }
}

/// 자주 하는 부탁 — 종류를 누르면 그 종류로 부탁 쓰기가 열린다.
class _FrequentCats extends StatelessWidget {
  final void Function(String cat) onPick;
  const _FrequentCats({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return SecCard(
      child: Column(
        children: [
          const SecHead(title: '자주 하는 부탁'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 8,
                mainAxisExtent: 73,
              ),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final c in cats)
                  InkWell(
                    onTap: () => onPick(c.k),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        IconTile(icon: c.icon, size: 48, iconSize: 24, radius: 15),
                        const SizedBox(height: 7),
                        Text(
                          c.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.caption.copyWith(fontSize: 12, fontWeight: AppType.w700, color: AppColors.ink2),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 우리 동네 제휴 가게 — 회원 전용가를 가로로 넘겨 본다.
class _PartnerShops extends StatelessWidget {
  final VoidCallback onOpen;
  const _PartnerShops({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final deals = memberDeals.where((d) => d.menu != 'finance').toList();
    if (deals.isEmpty) return const SizedBox.shrink();
    return SecCard(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SecHead(title: '우리 동네 제휴 가게', action: '전체', onAction: onOpen),
          SizedBox(
            height: 98,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: deals.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final d = deals[i];
                return Material(
                  color: AppColors.page,
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                  child: InkWell(
                    onTap: onOpen,
                    borderRadius: BorderRadius.circular(AppRadius.tile),
                    child: Container(
                      width: 93,
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconTile(icon: d.icon, bg: AppColors.card, size: 34, iconSize: 19, radius: 10),
                          const SizedBox(height: 8),
                          Text(
                            d.brand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.caption.copyWith(fontSize: 12.5, fontWeight: AppType.w700, color: AppColors.ink),
                          ),
                          Text(
                            d.isPriced ? '${d.percent}% 할인' : d.cond,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.caption.copyWith(fontWeight: AppType.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 주요 서비스 타일 (동네 부탁 · 해외 부탁 · 단기알바)
class _ServiceTile extends StatelessWidget {
  final String icon, title, sub;
  final Color bg, fg;
  final VoidCallback onTap;
  const _ServiceTile({
    required this.icon,
    required this.title,
    required this.sub,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 9),
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
                child: Icon(AppIcon.data(icon), size: 16, color: fg),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.body.copyWith(fontSize: 13, fontWeight: AppType.w700, letterSpacing: -0.39),
              ),
              const SizedBox(height: 1),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.caption.copyWith(fontSize: 10.5, fontWeight: AppType.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 바로가기 한 칸 (미션 · 공동구매 · 가는 김에 · 전체)
class _QuickItem extends StatelessWidget {
  final String icon, label;
  final VoidCallback onTap;
  const _QuickItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            children: [
              Icon(AppIcon.data(icon), size: 20, color: AppColors.ink2),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppType.caption.copyWith(fontWeight: AppType.w500, color: AppColors.ink2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
