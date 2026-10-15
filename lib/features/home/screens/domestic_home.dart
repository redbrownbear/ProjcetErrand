import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/kit.dart';
import '../../dayjob/data/day_jobs.dart';
import '../../dayjob/models/day_job.dart';
import '../../dayjob/screens/day_job_detail_screen.dart';
import '../../dayjob/widgets/day_job_card.dart';
import '../../errand/data/categories.dart';
import '../../errand/models/task_item.dart';
import '../../lucky/models/tickets.dart';
import '../../proposal/widgets/live_board.dart';
import '../data/local_shops.dart';
import '../widgets/hero_card.dart';
import '../widgets/home_sections.dart';

/// 홈 · 국내 — 부탁하기 / 돈벌기 (시안 v77)
class DomesticHome extends StatefulWidget {
  final AppNav nav;
  final List<TaskItem> items;
  final String scope;
  final int monthEarn;
  final VoidCallback goWallet;
  final void Function(int tab) goMarket;
  final void Function(String cat) openCat;
  final VoidCallback openAllAsks;
  final VoidCallback openTripFeed;
  final VoidCallback openAllServices;
  final VoidCallback goOverseasEarn;
  final void Function(DayJob) applyDayJob;
  const DomesticHome({
    super.key,
    required this.nav,
    required this.items,
    required this.scope,
    required this.monthEarn,
    required this.goWallet,
    required this.goMarket,
    required this.openCat,
    required this.openAllAsks,
    required this.openTripFeed,
    required this.openAllServices,
    required this.goOverseasEarn,
    required this.applyDayJob,
  });

  @override
  State<DomesticHome> createState() => _DomesticHomeState();
}

class _DomesticHomeState extends State<DomesticHome> {
  int seg = 0;
  AppNav get nav => widget.nav;

  @override
  Widget build(BuildContext context) {
    final draw = LuckyDraw(DateTime.now());
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Seg(labels: const ['부탁하기', '돈벌기'], index: seg, onChanged: (i) => setState(() => seg = i)),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: seg == 0 ? _ask(draw) : _earn(draw),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 6),
        child: Text(
          seg == 0 ? '이웃에게 직접 부탁하려면 마이 › 이웃에게 직접 부탁' : '체험 화면 · 실제 정산은 안전결제 연동 후 이루어져요',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.faint),
        ),
      ),
    ]);
  }

  // ── 부탁하기 ────────────────────────────────────────────────────────────

  Widget _ask(LuckyDraw draw) {
    return Column(key: const ValueKey('ask'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      HeroCard(
        sub: '가는 길에, 하나 더',
        title: const [('무엇이든 부탁해요\n', false), ('가까운 이웃', true), ('이 도와드려요', false)],
        live: const [
          (bold: '성심당 빵 사다주기', meta: '완료 · 반포동 · 14분 전'),
          (bold: '택배 받아 사무실에 전달', meta: '완료 · 서초동 · 방금'),
          (bold: '강아지 30분 산책', meta: '완료 · 잠원동 · 32분 전'),
        ],
        drawLabel: draw.label,
        bubbleSub: '부탁이 끝나면 응모권 +${TicketRules.myDone.n}',
        onBubble: () => nav.openLucky(context),
        cta: '부탁하기',
        onCta: nav.openAskForm,
        note: '누구나 가는 김에 도와주고 수익을 얻을 수 있어요',
        floats: const ['box', 'heart', 'pet'],
      ),
      ListenableBuilder(
        listenable: nav.store,
        builder: (context, _) => LiveBoard(
          store: nav.store,
          abroad: false,
          onOpen: (p) => nav.openProposal(context, p),
          onAll: () => nav.openProposalList(context, abroad: false),
          onPropose: () => nav.openPropose(context),
          onSponsor: () => nav.flash('제휴 베이커리 10% 할인 쿠폰은 제휴 확정 후 받을 수 있어요'),
        ),
      ),
      TripTools(nav: nav),
      AskIdeas(onAsk: nav.openAskForm),
      ShopBanner(onOpen: _openShop),
      CatGrid(onCat: widget.openCat),
      QuickLinks(items: [
        ('gift', '미션', () => widget.goMarket(0)),
        ('cart', '공동구매', () => widget.goMarket(1)),
        ('store', '중고장터', () => widget.goMarket(2)),
        ('pencil', '가는 김에', widget.openTripFeed),
        ('sparkles', '전체', widget.openAllServices),
      ]),
      ShopStrip(onOpen: _openShop, onAll: () => widget.goMarket(0)),
      TripFeedSection(nav: nav, onAll: widget.openTripFeed),
    ]);
  }

  void _openShop(LocalShop s) => openShopSheet(context, s, onMissions: () => widget.goMarket(0));

  // ── 돈벌기 ──────────────────────────────────────────────────────────────

  List<TaskItem> get _near {
    final list = widget.items
        .where((i) => i.mode == 'ask' && !i.isMine && !i.isExpired && (widget.scope == '전국' || i.region == widget.scope))
        .toList()
      ..sort((a, b) => (a.distM ?? 9e9).compareTo(b.distM ?? 9e9));
    return list;
  }

  Widget _earn(LuckyDraw draw) {
    final near = _near;
    return Column(key: const ValueKey('earn'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      HeroCard(
        sub: '누구나 할 수 있는 부업',
        title: const [('가는 김에 도와주고\n', false), ('수익', true), ('을 만들어요', false)],
        live: const [
          (bold: '택배 전달 4,000원', meta: '정산 · 반포동 이웃 · 방금'),
          (bold: '성심당 빵 12,000원', meta: '정산 · 서초동 이웃 · 8분 전'),
          (bold: '강아지 산책 15,000원', meta: '정산 · 잠원동 이웃 · 20분 전'),
        ],
        drawLabel: draw.label,
        bubbleSub: '도와주면 응모권 +${TicketRules.helpDone.n}',
        onBubble: () => nav.openLucky(context),
        cta: '지금 할 수 있는 일 보기',
        ctaIcon: 'pin',
        onCta: widget.openAllAsks,
        note: '학생도, 선생님도, 어르신도 시간 날 때 함께해요',
        floats: const ['wallet', 'sparkles', 'hand'],
      ),
      Sec(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('이번 달 내가 번 금액', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.sub)),
              const SizedBox(height: 3),
              Text.rich(TextSpan(children: [
                TextSpan(text: nf(widget.monthEarn), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -1)),
                const TextSpan(text: '원', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ])),
            ]),
          ),
          GestureDetector(
            onTap: widget.goWallet,
            child: Container(
              height: 34,
              padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
              decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('지갑', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                Icon(Icons.chevron_right_rounded, size: 17, color: AppColors.inkSoft),
              ]),
            ),
          ),
        ]),
      ),
      if (near.isNotEmpty) _PickCarousel(items: near.take(5).toList(), onOpen: (t) => nav.openTask(context, t)),
      _NearList(items: near, nav: nav, openAll: widget.openAllAsks, applyDayJob: widget.applyDayJob),
      ShopBanner(onOpen: _openShop),
      ListenableBuilder(
        listenable: nav.store,
        builder: (context, _) => LiveBoard(
          store: nav.store,
          abroad: false,
          onOpen: (p) => nav.openProposal(context, p),
          onAll: () => nav.openProposalList(context, abroad: false),
          onPropose: () => nav.openPropose(context),
        ),
      ),
      TripTools(nav: nav),
      TripFeedSection(nav: nav, onAll: widget.openTripFeed),
      Sec(
        title: '우리 동네 혜택',
        more: '혜택 전체보기',
        onMore: () => widget.goMarket(0),
        margin: const EdgeInsets.fromLTRB(10, 16, 10, 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _AdCard(shop: localShops.first, onTap: () => _openShop(localShops.first)),
        ),
      ),
      _SeaStrip(items: widget.items.where((i) => i.mode == 'sea' && !i.isMine).toList(), nav: nav, onAll: widget.goOverseasEarn),
      Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
        child: Tap(
          onTap: () => widget.goMarket(0),
          radius: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.card_giftcard_rounded, color: AppColors.orange, size: 21),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('미션·공구로 더 벌기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  Text('설문·체험 미션, 공동구매', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.sub)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
            ]),
          ),
        ),
      ),
    ]);
  }
}

/// 이거 하나 하고 갈래요? — 한 장씩 넘겨 보는 가까운 부탁 (.pick)
class _PickCarousel extends StatefulWidget {
  final List<TaskItem> items;
  final void Function(TaskItem) onOpen;
  const _PickCarousel({required this.items, required this.onOpen});
  @override
  State<_PickCarousel> createState() => _PickCarouselState();
}

class _PickCarouselState extends State<_PickCarousel> {
  final ctrl = PageController();
  int page = 0;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void _go(int d) {
    final n = (page + d).clamp(0, widget.items.length - 1);
    ctrl.animateToPage(n, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Sec(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(children: [
            const Expanded(child: Text('이거 하나 하고 갈래요?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.sub))),
            Text('${page + 1} / ${widget.items.length}', style: const TextStyle(fontSize: 12.5, color: AppColors.faint)),
            const SizedBox(width: 8),
            _arrow(Icons.chevron_left_rounded, page > 0, () => _go(-1)),
            const SizedBox(width: 4),
            _arrow(Icons.chevron_right_rounded, page < widget.items.length - 1, () => _go(1)),
          ]),
        ),
        SizedBox(
          height: 100,
          child: PageView.builder(
            controller: ctrl,
            itemCount: widget.items.length,
            onPageChanged: (p) => setState(() => page = p),
            itemBuilder: (_, i) {
              final it = widget.items[i];
              final tone = AppColors.taskIcon[it.cat] ?? AppColors.taskIconFallback;
              return GestureDetector(
                onTap: () => widget.onOpen(it),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(7)),
                        child: Icon(AppIcon.cat(it.cat), size: 13, color: tone.fg),
                      ),
                      const SizedBox(width: 8),
                      Text('${catOf(it.cat).label} · ${it.place ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.sub)),
                    ]),
                    const SizedBox(height: 8),
                    Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text('+${won(it.price)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                      const Spacer(),
                      if (it.mins > 0) _chip(Icons.schedule_rounded, '약 ${it.mins}분'),
                      const SizedBox(width: 5),
                      if (it.distM != null) _chip(Icons.place_outlined, distLabel(it)),
                      const SizedBox(width: 5),
                      const TicketChip(3),
                    ]),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _chip(IconData i, String t) => Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(7)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 13, color: AppColors.sub),
          const SizedBox(width: 3),
          Text(t, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
        ]),
      );

  Widget _arrow(IconData i, bool on, VoidCallback f) => GestureDetector(
        onTap: on ? f : null,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.outline)),
          child: Icon(i, size: 20, color: on ? AppColors.ink : AppColors.faint),
        ),
      );
}

/// 지금 내 주변 부탁 — 동네 부탁 / 단기알바, 거리 · 정렬 (.sec.near)
class _NearList extends StatefulWidget {
  final List<TaskItem> items;
  final AppNav nav;
  final VoidCallback openAll;
  final void Function(DayJob) applyDayJob;
  const _NearList({required this.items, required this.nav, required this.openAll, required this.applyDayJob});
  @override
  State<_NearList> createState() => _NearListState();
}

class _NearListState extends State<_NearList> {
  int tab = 0;
  int radius = 3000;
  bool byPrice = false;

  static const _radii = [500, 1000, 3000, 5000, 10000, 30000];
  String _rLabel(int m) => m >= 1000 ? '${m ~/ 1000}km 이내' : '${m}m 이내';

  @override
  Widget build(BuildContext context) {
    final list = widget.items.where((i) => (i.distM ?? 9e9) <= radius).toList();
    if (byPrice) list.sort((a, b) => b.price - a.price);
    return Sec(
      title: '지금 내 주변 부탁',
      more: '부탁 전체보기',
      onMore: widget.openAll,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        UnderTabs(
          labels: const ['동네 부탁', '단기알바'],
          counts: {1: '${dayJobs.length}'},
          index: tab,
          fontSize: 14,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          onChanged: (i) => setState(() => tab = i),
        ),
        if (tab == 0) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(children: [
              _select<int>(Icons.place_outlined, radius, [for (final r in _radii) (r, _rLabel(r))], (v) => setState(() => radius = v)),
              const SizedBox(width: 6),
              _select<bool>(null, byPrice, const [(false, '가까운순'), (true, '금액 높은순')], (v) => setState(() => byPrice = v)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '${list.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
              TextSpan(text: '개의 부탁 · ${_rLabel(radius)}'),
            ]), style: const TextStyle(fontSize: 12, color: AppColors.sub)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: Text('이 거리 안에는 아직 부탁이 없어요', style: TextStyle(color: AppColors.sub))),
                  )
                : Column(children: [
                    for (final it in list.take(5)) EarnRow(it: it, onTap: () => widget.nav.openTask(context, it)),
                  ]),
          ),
          GrayButton(label: '부탁 전체 보기', onTap: widget.openAll),
        ] else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(children: [
              for (final j in dayJobs.take(3))
                DayJobCard(
                  j: j,
                  compact: true,
                  onOpen: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DayJobDetailScreen(j: j, onApply: () => widget.applyDayJob(j))),
                  ),
                ),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text('겸사겸사는 구인업체가 아니에요. 근로계약은 구인업체와 맺어요.', style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
          ),
        ],
      ]),
    );
  }

  Widget _select<T>(IconData? icon, T value, List<(T, String)> items, ValueChanged<T> onChanged) {
    final label = items.firstWhere((e) => e.$1 == value).$2;
    return PopupMenuButton<T>(
      onSelected: onChanged,
      itemBuilder: (_) => [for (final e in items) PopupMenuItem(value: e.$1, child: Text(e.$2))],
      child: Container(
        height: 36,
        padding: const EdgeInsets.fromLTRB(10, 0, 6, 0),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.outline)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 16, color: AppColors.ink), const SizedBox(width: 4)],
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.sub),
        ]),
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  final LocalShop shop;
  final VoidCallback onTap;
  const _AdCard({required this.shop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(16)),
      child: Tap(
        onTap: onTap,
        radius: 16,
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: const Color(0xFFF0EDEA), borderRadius: BorderRadius.circular(12)),
                child: AppIcon(shop.icon, size: 30, color: const Color(0xFF9A6B44)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(shop.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                  const SizedBox(height: 1),
                  Text(shop.benefit, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text('${shop.cat} · ${shop.area} · ${shop.dist}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.sub)),
                ]),
              ),
            ]),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
              child: const Text('광고', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.sub)),
            ),
          ),
        ]),
      ),
    );
  }
}

/// 여행 가는 길에, 해외 부탁 — 가로로 넘겨 보는 카드 (.hsc .oscard)
class _SeaStrip extends StatelessWidget {
  final List<TaskItem> items;
  final AppNav nav;
  final VoidCallback onAll;
  const _SeaStrip({required this.items, required this.nav, required this.onAll});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Sec(
      title: '여행 가는 길에, 해외 부탁',
      titleTrailing: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Text('${items.length}', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.blue)),
      ),
      more: '전체',
      onMore: onAll,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text('사다주고 부탁 비용 받기 · 상품가는 요청자가 선결제해요', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.sub)),
        ),
        SizedBox(
          height: 151,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length.clamp(0, 6),
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => SeaCard(it: items[i], onTap: () => nav.openTask(context, items[i])),
          ),
        ),
      ]),
    );
  }
}

/// 해외 부탁 카드 (.oscard)
class SeaCard extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onTap;
  final double width;
  const SeaCard({super.key, required this.it, required this.onTap, this.width = 250});

  @override
  Widget build(BuildContext context) {
    final place = (it.country ?? '').replaceAll(RegExp(r'[^가-힣A-Za-z ]'), '').trim();
    return Container(
      width: width,
      decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(20)),
      child: Tap(
        onTap: onTap,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CodeBox((it.cc ?? '').toUpperCase(), bg: AppColors.redSoft, fg: AppColors.red),
              const SizedBox(width: 8),
              Text(place, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.sub)),
            ]),
            const SizedBox(height: 10),
            Text(it.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.35)),
            const Spacer(),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('부탁 비용\n영수증으로 정산', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.sub, height: 1.45)),
              const Spacer(),
              Text(won(it.price), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            ]),
          ]),
        ),
      ),
    );
  }
}
