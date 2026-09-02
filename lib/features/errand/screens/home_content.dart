import 'package:flutter/material.dart';

import '../../../core/navigation/screen_route.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_header.dart';
import '../../benefits/data/point_rules.dart';
import '../../benefits/models/coupon.dart';
import '../../benefits/models/partner_mission.dart';
import '../../benefits/models/reward_product.dart';
import '../../benefits/screens/earn_hub_screen.dart';
import '../../benefits/screens/point_shop_screen.dart';
import '../../benefits/screens/walk_screen.dart';
import '../../benefits/widgets/walk_ring.dart';
import '../../community/screens/community_screen.dart';
import '../../community/widgets/community_card.dart';
import '../../gongu/screens/gongu_screen.dart';
import '../data/categories.dart';
import '../data/countries.dart';
import '../data/home_ads.dart';
import '../models/task_item.dart';
import '../navigation/errand_actions.dart';
import '../widgets/ad_banner.dart';
import '../widgets/featured_card.dart';
import '../widgets/reco_card.dart';
import '../widgets/task_card.dart';
import 'country_screen.dart';
import 'list_screen.dart';
import 'map_screen.dart';
import 'overseas_screen.dart';
import 'search_screen.dart';

class HomeContent extends StatefulWidget {
  final List<TaskItem> items;
  final String scope;
  final ErrandActions actions;
  final int points;
  final int steps;
  final List<Coupon> coupons;
  final List<String> doneMissions;
  final VoidCallback openPost;
  final VoidCallback openRegion;
  final void Function(int amt, String label) earn;
  final void Function(RewardProduct) redeem;
  final void Function(int id) useCoupon;
  final void Function(PartnerMission) completeMission;
  final void Function(String) flash;
  final VoidCallback goPointsHub;

  const HomeContent({
    super.key,
    required this.items,
    required this.scope,
    required this.actions,
    required this.points,
    required this.steps,
    required this.coupons,
    required this.doneMissions,
    required this.openPost,
    required this.openRegion,
    required this.earn,
    required this.redeem,
    required this.useCoupon,
    required this.completeMission,
    required this.flash,
    required this.goPointsHub,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  bool walkGot = false;

  bool _inScope(TaskItem i) => widget.scope == '전국' || i.region == widget.scope;

  void goList(ScreenRoute config) => Navigator.push(context, MaterialPageRoute(builder: (_) => ListScreen(config: config, items: widget.items, scope: widget.scope, actions: widget.actions)));
  void goMap() => Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(items: widget.items, scope: widget.scope, actions: widget.actions)));
  void goSearch() => Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen(items: widget.items, actions: widget.actions)));
  void goOverseas() => Navigator.push(context, MaterialPageRoute(builder: (_) => OverseasScreen(items: widget.items, actions: widget.actions)));
  void goCommunity() => Navigator.push(context, MaterialPageRoute(builder: (_) => CommunityScreen(items: widget.items, scope: widget.scope, actions: widget.actions)));
  void goWalk() => Navigator.push(context, MaterialPageRoute(builder: (_) => WalkScreen(
        items: widget.items, scope: widget.scope, steps: widget.steps, points: widget.points, coupons: widget.coupons,
        actions: widget.actions, earn: widget.earn, redeem: widget.redeem, useCoupon: widget.useCoupon, goPointsHub: widget.goPointsHub,
      )));
  void goShop() => Navigator.push(context, MaterialPageRoute(builder: (_) => PointShopScreen(
        points: widget.points, redeem: widget.redeem, coupons: widget.coupons, useCoupon: widget.useCoupon, goPointsHub: widget.goPointsHub,
      )));
  void goGongu() => Navigator.push(context, MaterialPageRoute(builder: (_) => GonguScreen(earn: widget.earn)));
  void goEarnHub() => Navigator.push(context, MaterialPageRoute(builder: (_) => EarnHubScreen(doneMissions: widget.doneMissions, completeMission: widget.completeMission)));
  void goCountry(String cc) => Navigator.push(context, MaterialPageRoute(builder: (_) => CountryScreen(cc: cc, items: widget.items, actions: widget.actions)));
  void openDetail(TaskItem it) => widget.actions.open(context, it);
  void openAd(ScreenRoute route) {
    switch (route.name) {
      case 'shop':
        goShop();
      case 'overseas':
        goOverseas();
      case 'walk':
        goWalk();
      default:
        goList(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final askNat = widget.items.where((i) => i.mode == 'ask' && _inScope(i)).toList();
    final sea = widget.items.where((i) => i.mode == 'sea').toList();
    final community = widget.items.where((i) => i.mode == 'together' && _inScope(i)).toList();

    final nearby = List.of(askNat)..sort((a, b) => a.distM.compareTo(b.distM));
    final nearbyTop = nearby.take(4).toList();

    final quick30 = askNat.where((i) => i.mins > 0 && i.mins <= 30).toList()..sort((a, b) => a.mins.compareTo(b.mins));
    final quick30Top = quick30.take(8).toList();

    final highPay = List.of(askNat)..sort((a, b) => b.price - a.price);
    final highPayTop = highPay.take(8).toList();

    final hotItems = [...askNat, ...sea].where((i) => i.hot).take(4).toList();

    final onTheWay = List.of(askNat)
      ..sort((a, b) {
        final d = a.distM.compareTo(b.distM);
        return d != 0 ? d : a.mins.compareTo(b.mins);
      });
    final onTheWayTop = onTheWay.take(6).toList();

    final newItems = List.of(askNat)..sort((a, b) => b.id - a.id);
    final newTop = newItems.take(5).toList();

    final popular = List.of(askNat)..sort((a, b) => b.deals - a.deals);
    final popularTop = popular.take(3).toList();

    final beginner = askNat.where((i) => i.mins > 0 && i.mins <= 20 && i.price <= 9000).toList()..sort((a, b) => a.mins.compareTo(b.mins));
    final beginnerTop = beginner.take(5).toList();

    final claimable = walkClaimable(widget.steps);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ① 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Image.asset('assets/icon/app_icon.png', width: 26, height: 26),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: widget.openRegion,
                    child: Row(children: [
                      Text('📍 ${shortRegion(widget.scope)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const SizedBox(width: 4),
                      const Text('▾', style: TextStyle(color: AppColors.faint, fontSize: 13)),
                    ]),
                  ),
                ]),
                Row(children: [
                  InkWell(onTap: () => goMap(), child: const Padding(padding: EdgeInsets.all(4), child: Text('🗺️', style: TextStyle(fontSize: 18)))),
                  InkWell(onTap: () => widget.flash('새 알림이 없어요'), child: const Padding(padding: EdgeInsets.all(4), child: Text('🔔', style: TextStyle(fontSize: 18)))),
                ]),
              ],
            ),
          ),
          // 브랜드 카피
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text.rich(
              TextSpan(style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.3), children: [
                const TextSpan(text: '어차피 가는 길에, '),
                TextSpan(text: '하나 더 하고 벌기', style: TextStyle(backgroundColor: AppColors.yellow.withValues(alpha: .6))),
              ]),
            ),
          ),
          // ② 검색
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: InkWell(
              onTap: () => goSearch(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
                child: const Text('🔍 줄서기, 사오기, 사진, 대행, 영화 같이…', style: TextStyle(color: AppColors.sub, fontSize: 13.5)),
              ),
            ),
          ),
          // ②-b 광고 배너 (스와이프 캐러셀)
          AdBanner(ads: homeAds, onTap: openAd),
          // ③ 주요 서비스 바로가기
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Row(children: [
              _Shortcut(icon: '🙋', label: '부탁해요', onTap: widget.openPost),
              _Shortcut(icon: '🤝', label: '돈벌기', onTap: () => goList(const ScreenRoute(name: 'list', title: '돈벌기', subtitle: '가는 길에 부탁 해결하고 사례비 받기', base: 'earn', sortable: true, catChips: true, mapBtn: true))),
              _Shortcut(icon: '🌏', label: '해외', onTap: () => goOverseas()),
              _Shortcut(icon: '👋', label: '같이해요', onTap: () => goCommunity()),
              _Shortcut(icon: '🗺️', label: '지도', onTap: () => goMap()),
            ]),
          ),
          // ④ 업무 카테고리
          const Padding(padding: EdgeInsets.fromLTRB(16, 6, 16, 6), child: Text('할 수 있는 일', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink))),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            child: GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
              children: cats.map((c) {
                return InkWell(
                  onTap: () => goList(ScreenRoute(name: 'list', title: c.label, subtitle: '${c.label} 부탁 모아보기', base: 'ask', cat: c.k, sortable: true, catChips: true, mapBtn: true)),
                  child: Column(children: [
                    Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(13)), child: Text(c.icon, style: const TextStyle(fontSize: 20))),
                    const SizedBox(height: 5),
                    Text(c.label, style: const TextStyle(fontSize: 11, color: AppColors.ink)),
                  ]),
                );
              }).toList(),
            ),
          ),
          // ⑤ 혜택/포인트 배너
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('오늘도 겸사겸사 혜택', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                  InkWell(onTap: () => goWalk(), child: const Text('걷기 전체 ›', style: TextStyle(color: AppColors.yellow, fontSize: 12, fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    flex: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🚶 ${nf(widget.steps)}걸음', style: const TextStyle(fontSize: 11.5, color: Colors.white70)),
                          Padding(padding: const EdgeInsets.only(top: 3), child: Text('+$claimable P 받을 수 있어요', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.yellow))),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: InkWell(
                              onTap: () {
                                if (!walkGot) {
                                  widget.earn(claimable, '걸음 적립');
                                  setState(() => walkGot = true);
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(color: walkGot ? Colors.white.withValues(alpha: .15) : AppColors.yellow, borderRadius: BorderRadius.circular(8)),
                                child: Text(walkGot ? '적립 완료' : '받기', style: TextStyle(color: walkGot ? Colors.white : AppColors.ink, fontSize: 12, fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('👥 친구 추천', style: TextStyle(fontSize: 11.5, color: Colors.white70)),
                          Padding(padding: const EdgeInsets.only(top: 3), child: Text('+${PointRules.referral}P', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))),
                          Padding(padding: const EdgeInsets.only(top: 8), child: Text('출석 +${PointRules.attendance}P', style: const TextStyle(fontSize: 10.5, color: Colors.white54))),
                        ],
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          InkWell(
            onTap: () => goShop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Text('🎁', style: TextStyle(fontSize: 17)),
                const SizedBox(width: 8),
                Expanded(child: Text('${nf(widget.points)}P 보유 · 치킨·커피로 바꿔보세요', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink))),
                const Text('포인트샵 ›', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.yellowDeep)),
              ]),
            ),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 14), child: Text('혜택 탭에서 더 많은 포인트를 모을 수 있어요', style: TextStyle(fontSize: 11, color: AppColors.faint))),

          const HDivider(),

          // ⑥ 내 주변 지금 할 일
          SectionHeader(
            title: '📍 내 주변 지금 할 일',
            onAction: () => goList(const ScreenRoute(name: 'list', title: '내 주변 할 일', subtitle: '가까운 순', base: 'ask', sortable: true, defaultSort: 'dist', catChips: true, mapBtn: true)),
          ),
          if (nearbyTop.isEmpty)
            const EmptyState(msg: '이 지역엔 아직 부탁이 없어요. 지역을 ‘전국’으로 바꿔보세요.')
          else
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [for (final it in nearbyTop) TaskCard(it: it, onOpen: () => openDetail(it), done: widget.actions.grabbed.contains(it.id))])),

          // ⑥-b 오늘 더 벌 수 있어요 (짧게 · 혜택으로 연결)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('💡 오늘 더 벌 수 있어요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
              InkWell(onTap: widget.goPointsHub, child: const Text('혜택에서 더 보기 ›', style: TextStyle(color: AppColors.sub, fontSize: 12.5, fontWeight: FontWeight.w700))),
            ]),
          ),
          SizedBox(
            height: 132,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              children: [
                _EarnTile(icon: '🤝', label: '근처 부탁', val: '+7,000원', valColor: AppColors.ink, bg: AppColors.yellowSoft, onTap: () => goList(const ScreenRoute(name: 'list', title: '근처에서 벌기', subtitle: '가까운 순', base: 'earn', sortable: true, defaultSort: 'dist', catChips: true, mapBtn: true))),
                _EarnTile(icon: '🚶', label: '걷기', val: '+30P', valColor: AppColors.blue, bg: AppColors.blueSoft, onTap: () => goWalk()),
                _EarnTile(icon: '🎁', label: '부업 (제휴·성과)', val: '+50,000원', valColor: AppColors.purple, bg: AppColors.purpleSoft, onTap: () => goEarnHub()),
                _EarnTile(icon: '🛍️', label: '공동구매', val: '성과보상', valColor: AppColors.yellowDeep, bg: AppColors.yellowSoft, onTap: () => goGongu()),
              ],
            ),
          ),

          // ⑦ 30분 안에 끝나요
          if (quick30Top.isNotEmpty) ...[
            SectionHeader(
              title: '⚡ 30분 안에 끝나요',
              sub: '자투리 시간에 겸사겸사',
              onAction: () => goList(const ScreenRoute(name: 'list', title: '30분 안에 끝나요', subtitle: '짧게 할 수 있는 일', base: 'ask', maxMins: 30, sortable: true, defaultSort: 'time', mapBtn: true)),
            ),
            _hScroll(quick30Top),
          ],

          // ⑧ 사례비 높은 부탁
          SectionHeader(
            title: '💰 사례비 높은 부탁',
            onAction: () => goList(const ScreenRoute(name: 'list', title: '사례비 높은 부탁', subtitle: '높은 사례비 순', base: 'earn', sortable: true, defaultSort: 'price', mapBtn: true)),
          ),
          _hScroll(highPayTop),

          // ⑨ 급해요
          if (hotItems.isNotEmpty) ...[
            SectionHeader(
              title: '🔥 지금 급해요',
              sub: '빨리 매칭되면 좋은 부탁',
              onAction: () => goList(const ScreenRoute(name: 'list', title: '지금 급해요', subtitle: 'HOT으로 올라온 부탁', base: 'earn', onlyHot: true, sortable: true, mapBtn: true)),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [for (final it in hotItems) TaskCard(it: it, onOpen: () => openDetail(it), done: widget.actions.grabbed.contains(it.id))])),
          ],

          // ⑩ 걷고 포인트 받기
          const Padding(padding: EdgeInsets.fromLTRB(16, 18, 16, 4), child: Text('🚶 걷고 포인트 받기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink))),
          InkWell(
            onTap: () => goWalk(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                WalkRing(steps: widget.steps, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${nf(widget.steps)}걸음', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      Padding(padding: const EdgeInsets.only(top: 2), child: Text('목표 ${nf(walkGoal)}걸음 · 오늘 +$claimable P 적립 가능', style: const TextStyle(fontSize: 12, color: AppColors.sub))),
                      const Padding(padding: EdgeInsets.only(top: 5), child: Text('500m 더 걸으면 근처 부탁도 할 수 있어요 ›', style: TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w700))),
                    ],
                  ),
                ),
              ]),
            ),
          ),

          const HDivider(thick: true),

          // ⑪ 가는 길에 겸사겸사
          const Padding(padding: EdgeInsets.fromLTRB(16, 18, 16, 3), child: Text('🚶 가는 길에 겸사겸사', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink))),
          const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 10), child: Text('지금 위치에서 가까운 부탁 — "여기 근처니까 해볼까?"', style: TextStyle(fontSize: 12.5, color: AppColors.sub))),
          if (onTheWayTop.isNotEmpty) FeaturedCard(it: onTheWayTop.first, onOpen: () => openDetail(onTheWayTop.first), done: widget.actions.grabbed.contains(onTheWayTop.first.id)),
          _hScroll(onTheWayTop.skip(1).toList()),

          const HDivider(thick: true),

          // ⑫ 해외 대행
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 3),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('🌏 해외에서 사다드려요', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
              InkWell(onTap: () => goOverseas(), child: const Text('전체 국가 ›', style: TextStyle(color: AppColors.purple, fontSize: 12, fontWeight: FontWeight.w700))),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: Text('여행·출장 중인 이웃에게 · 최소 사례비 ${nf(seaMin)}원', style: const TextStyle(fontSize: 12.5, color: AppColors.sub))),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: countries.length > 10 ? 10 : countries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = countries[i];
                return InkWell(
                  onTap: () => goCountry(c.cc),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 62,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c.flag, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 2),
                        Text(c.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          _hScroll(sea.take(6).toList()),

          const HDivider(thick: true),

          // ⑬ 같이해요
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 3),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('👋 같이해요', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
              InkWell(onTap: () => goCommunity(), child: const Text('동네생활 ›', style: TextStyle(color: AppColors.sub, fontSize: 12))),
            ]),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 10), child: Text('본인인증 이웃과 함께 · 공개 장소 권장', style: TextStyle(fontSize: 12.5, color: AppColors.sub))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [for (final it in community.take(3)) CommunityCard(it: it, onOpen: () => openDetail(it), compact: true)])),

          const HDivider(),

          // ⑭ 이번 주 인기
          SectionHeader(
            title: '🏆 이번 주 인기 부탁',
            onAction: () => goList(const ScreenRoute(name: 'list', title: '이번 주 인기', subtitle: '많이 거래된 순', base: 'ask', sortable: true, defaultSort: 'deals', mapBtn: true)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [for (int i = 0; i < popularTop.length; i++) TaskCard(it: popularTop[i], onOpen: () => openDetail(popularTop[i]), done: widget.actions.grabbed.contains(popularTop[i].id), rank: i + 1)]),
          ),

          // ⑮ 처음이라면 이 일부터
          if (beginnerTop.isNotEmpty) ...[
            const SectionHeader(title: '🌱 처음이라면 이 일부터', sub: '초보도 부담 없는 짧고 쉬운 일'),
            _hScroll(beginnerTop),
          ],

          // ⑯ 새로 올라온 부탁
          SectionHeader(
            title: '🆕 새로 올라온 부탁',
            onAction: () => goList(const ScreenRoute(name: 'list', title: '새로 올라온 부탁', subtitle: '최신 순', base: 'ask', sortable: true, defaultSort: 'new', mapBtn: true)),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [for (final it in newTop) TaskCard(it: it, onOpen: () => openDetail(it), done: widget.actions.grabbed.contains(it.id))])),

          // ⑰ 안전 거래
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('🛡 안전하게 거래해요', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink))),
                for (final t in const ['본인인증 회원끼리 매칭', '공개된 장소에서 만나기 권장', '사례비는 완료 확인 전까지 앱이 보관', '언제든 신고·차단할 수 있어요'])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      const Text('✓', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Text(t, style: const TextStyle(fontSize: 12.5, color: AppColors.ink)),
                    ]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hScroll(List<TaskItem> list) {
    if (list.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final it = list[i];
          return RecoCard(it: it, onOpen: () => openDetail(it), done: widget.actions.grabbed.contains(it.id));
        },
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  final String icon, label;
  final VoidCallback onTap;
  const _Shortcut({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: [
            Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(15)), child: Text(icon, style: const TextStyle(fontSize: 22))),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
          ]),
        ),
      ),
    );
  }
}

class _EarnTile extends StatelessWidget {
  final String icon, label, val;
  final Color valColor, bg;
  final VoidCallback onTap;
  const _EarnTile({required this.icon, required this.label, required this.val, required this.valColor, required this.bg, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 122,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)), child: Text(icon, style: const TextStyle(fontSize: 17))),
            Padding(padding: const EdgeInsets.only(top: 8), child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.sub, fontWeight: FontWeight.w600))),
            Padding(padding: const EdgeInsets.only(top: 2), child: Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: valColor))),
          ],
        ),
      ),
    );
  }
}
