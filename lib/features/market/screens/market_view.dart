import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/kit.dart';
import '../../benefits/data/partner_missions.dart';
import '../../benefits/models/mission_meta.dart';
import '../../benefits/models/partner_mission.dart';
import '../../benefits/repositories/mission_progress.dart';
import '../../benefits/screens/daily_mission_screen.dart';
import '../../benefits/screens/partner_mission_detail_screen.dart';
import '../../benefits/services/mission_engine.dart';
import '../../benefits/services/mission_runner.dart';
import '../../benefits/widgets/daily_mission_row.dart';
import '../../errand/models/task_item.dart';
import '../../home/widgets/home_sections.dart';
import '../../lucky/models/tickets.dart';
import '../../partner/screens/brand_hub_screen.dart';
import '../data/group_buys.dart';
import '../models/used_item.dart';
import '../widgets/used_art.dart';

/// 포인트를 원으로 출금할 수 있는 최소 보유량
const pointWithdrawMin = 5000;

/// 마켓 — 미션 · 공동구매 · 중고장터 · 나눔을 한 탭의 네 칸으로 (시안 v42)
class MarketView extends StatefulWidget {
  final AppNav nav;
  final int points;
  final List<String> doneMissions;
  final void Function(PartnerMission) completeMission;
  final VoidCallback openPointShop;
  final List<TaskItem> items;

  /// 매일 미션 · 오늘의 퀴즈 (가볍게 모으기). 적립 원장은 셸이 들고 있다.
  final MissionEngine Function() engine;
  final MissionRunner runner;
  const MarketView({
    super.key,
    required this.nav,
    required this.points,
    required this.doneMissions,
    required this.completeMission,
    required this.openPointShop,
    required this.items,
    required this.engine,
    required this.runner,
  });

  @override
  State<MarketView> createState() => MarketViewState();
}

class MarketViewState extends State<MarketView> {
  int tab = 0;
  void showTab(int i) => setState(() => tab = i);

  AppNav get nav => widget.nav;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // 중고장터 · 나눔은 시안에서 흰 바탕 목록이다
      if (tab >= 2) const Positioned.fill(child: ColoredBox(color: AppColors.card)),
      ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          if (tab < 2) _LuckyBanner(nav: nav),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: UnderTabs(labels: const ['미션', '공동구매', '중고장터', '나눔'], index: tab, onChanged: showTab),
          ),
          switch (tab) {
            0 => _Missions(
                engine: widget.engine,
                runner: widget.runner,
                points: widget.points,
                doneMissions: widget.doneMissions,
                completeMission: widget.completeMission,
                openPointShop: widget.openPointShop,
              ),
            1 => _GroupBuys(nav: nav),
            2 => _Used(nav: nav, items: widget.items),
            _ => _Share(nav: nav),
          },
          if (tab < 2)
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandHubScreen())),
                child: const Text('브랜드·가게 제휴 문의', style: TextStyle(fontSize: 13, color: AppColors.sub, decoration: TextDecoration.underline)),
              ),
            ),
        ],
      ),
      if (tab >= 2)
        Positioned(
          right: 18,
          bottom: 18,
          child: FloatingActionButton(
            heroTag: 'used-fab',
            backgroundColor: AppColors.yellow,
            foregroundColor: AppColors.ink,
            elevation: 3,
            shape: const CircleBorder(),
            onPressed: () => nav.openUsedForm(context, share: tab == 3),
            child: const Icon(Icons.add_rounded, size: 30),
          ),
        ),
    ]);
  }
}

/// 마켓 맨 위 럭키드로우 띠 (.sld)
class _LuckyBanner extends StatelessWidget {
  final AppNav nav;
  const _LuckyBanner({required this.nav});

  @override
  Widget build(BuildContext context) {
    final draw = LuckyDraw(DateTime.now());
    return ListenableBuilder(
      listenable: nav.store,
      builder: (context, _) => Container(
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFF3C4), Color(0xFFFFE7A0)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.liveLine),
        ),
        child: Tap(
          onTap: () => nav.openLucky(context),
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
                child: Transform.rotate(angle: -0.5, child: const Icon(Icons.flight_rounded, color: AppColors.blue, size: 28)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                      child: Text('${draw.month}월 LUCKY DRAW', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.yellowInk, letterSpacing: 0.4)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(4)),
                      child: Text('D-${draw.dday}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.yellow)),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  const Text('미션 하고 도쿄 왕복 항공권 + 호텔 받아가세요', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 1),
                  Text('미션마다 응모권 +1~+5 · 내 응모권 ${nav.store.wallet.have}장', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
                ]),
              ),
              const SizedBox(width: 8),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(11)),
                child: const Text('응모', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.yellow)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── 미션 ──────────────────────────────────────────────────────────────────

/// 미션 종류별로 받는 응모권
int ticketsFor(PartnerMission m) => switch (m.cat) {
      'visit' => TicketRules.visit.n,
      'research' || 'consult' => 3,
      _ => TicketRules.survey.n,
    };

class _Missions extends StatefulWidget {
  final MissionEngine Function() engine;
  final MissionRunner runner;
  final int points;
  final List<String> doneMissions;
  final void Function(PartnerMission) completeMission;
  final VoidCallback openPointShop;
  const _Missions({required this.engine, required this.runner, required this.points, required this.doneMissions, required this.completeMission, required this.openPointShop});

  @override
  State<_Missions> createState() => _MissionsState();
}

class _MissionsState extends State<_Missions> {
  static const _cats = [
    ('all', '전체'),
    ('survey', '설문조사'),
    ('blog', '블로그·SNS'),
    ('visit', '방문'),
    ('signup', '가입'),
    ('experience', '앱·체험'),
    ('shopping', '쇼핑'),
    ('research', '연구·상담'),
  ];
  static const _sorts = ['추천순', '보상 높은순', '보상 낮은순'];

  int cat = 0;
  int status = 0;
  int sort = 0;
  MissionProgress progress = MissionProgress.load();

  bool _done(PartnerMission m) => widget.doneMissions.contains(m.id);
  bool _active(PartnerMission m) => !_done(m) && progress.stageOf(m.id) != MissionStage.ready;

  List<PartnerMission> get _list {
    final c = _cats[cat].$1;
    final list = partnerMissions.where((m) {
      if (c != 'all') {
        final ok = c == 'research' ? (m.cat == 'research' || m.cat == 'consult') : m.cat == c;
        if (!ok) return false;
      }
      if (status == 1 && !_active(m)) return false;
      if (status == 2 && !_done(m)) return false;
      return true;
    }).toList();
    list.sort((a, b) {
      final ad = _done(a) ? 1 : 0, bd = _done(b) ? 1 : 0;
      if (ad != bd) return ad - bd;
      final aa = _active(a) ? 0 : 1, ba = _active(b) ? 0 : 1;
      if (sort == 0 && aa != ba) return aa - ba;
      return switch (sort) {
        1 => b.points - a.points,
        2 => a.points - b.points,
        _ => 0,
      };
    });
    return list;
  }

  Future<void> _open(PartnerMission m) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PartnerMissionDetailScreen(m: m, done: _done(m), onComplete: widget.completeMission)),
    );
    if (mounted) setState(() => progress = MissionProgress.load());
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.points;
    final list = _list;
    final activeN = partnerMissions.where(_active).length;
    final doneN = partnerMissions.where(_done).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Sec(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('보유 포인트', style: TextStyle(fontSize: 13, color: AppColors.sub)),
                const SizedBox(height: 2),
                Text.rich(TextSpan(children: [
                  TextSpan(text: nf(p), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                  const TextSpan(text: 'P', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.yellowInk)),
                ])),
              ]),
            ),
            GestureDetector(
              onTap: widget.openPointShop,
              child: Container(
                height: 34,
                padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
                decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(10)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('포인트샵', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  Icon(Icons.chevron_right_rounded, size: 17),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (p / pointWithdrawMin).clamp(0, 1).toDouble(),
              minHeight: 5,
              backgroundColor: AppColors.page,
              color: AppColors.yellow,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            p >= pointWithdrawMin ? '원으로 출금할 수 있어요 · 마이 › 내 지갑' : '${nf(pointWithdrawMin - p)}P 더 모으면 원으로 출금할 수 있어요',
            style: const TextStyle(fontSize: 12, color: AppColors.sub),
          ),
        ]),
      ),
      _light(),
      Sec(
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 14, 10),
            child: Row(children: [
              const Expanded(child: Text('참여할 미션', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
              PopupMenuButton<int>(
                onSelected: (v) => setState(() => sort = v),
                itemBuilder: (_) => [for (final (i, s) in _sorts.indexed) PopupMenuItem(value: i, child: Text(s))],
                child: Row(children: [
                  Text(_sorts[sort], style: const TextStyle(fontSize: 13, color: AppColors.sub)),
                  const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.sub),
                ]),
              ),
            ]),
          ),
          Seg(
            labels: ['전체 ${partnerMissions.length}', '참여 중 $activeN', '적립 완료 $doneN'],
            index: status,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            onChanged: (i) => setState(() => status = i),
          ),
          const SizedBox(height: 12),
          ChipRow(labels: [for (final c in _cats) c.$2], index: cat, onChanged: (i) => setState(() => cat = i)),
          const SizedBox(height: 4),
          if (list.isEmpty)
            const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('조건에 맞는 미션이 없어요', style: TextStyle(color: AppColors.sub)))),
          for (final m in list) _row(m),
        ]),
      ),
    ]);
  }

  /// 가볍게 모으기 — 오늘 실제로 받을 수 있는 매일 미션·퀴즈만 (제휴 API 연동분)
  Widget _light() {
    final engine = widget.engine();
    final rows = engine.forHome(take: 3);
    final remain = engine.remainToday;
    final anyOpen = engine.todayProgress.$2 > 0;
    return Sec(
      title: '가볍게 모으기',
      more: '전체 보기',
      onMore: _openDaily,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (remain > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('오늘 아직 +${nf(remain)}P 남았어요', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.yellowInk)),
            ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                anyOpen ? '오늘 할 수 있는 건 다 했어요 · 아래 미션도 둘러보세요' : '오늘 열린 매일 미션이 아직 없어요',
                style: const TextStyle(fontSize: 13, color: AppColors.sub),
              ),
            )
          else
            for (final st in rows)
              DailyMissionRow(s: st, onTap: () async {
                await widget.runner.run(context, st);
                if (mounted) setState(() {});
              }),
        ]),
      ),
    );
  }

  Future<void> _openDaily() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DailyMissionScreen(runner: widget.runner, engine: widget.engine(), goEarnHub: () => Navigator.of(context).pop())),
    );
    if (mounted) setState(() {});
  }

  Widget _row(PartnerMission m) {
    final done = _done(m);
    final active = _active(m);
    final catLabel = _cats.firstWhere((c) => c.$1 == m.cat || (c.$1 == 'research' && m.cat == 'consult'), orElse: () => ('', '미션')).$2;
    return Tap(
      onTap: () => _open(m),
      radius: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Opacity(
          opacity: done ? 0.5 : 1,
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFFFF1E6), borderRadius: BorderRadius.circular(14)),
              child: Text(m.icon, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (done)
                    const Padding(padding: EdgeInsets.only(right: 5), child: Pill('적립 완료', bg: AppColors.greenSoft, fg: AppColors.greenDeep))
                  else if (active)
                    const Padding(padding: EdgeInsets.only(right: 5), child: Pill('참여 중', bg: Color(0xFFEAF0FE), fg: Color(0xFF2F63E8))),
                  Flexible(child: Text('$catLabel · ${m.brand}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.sub))),
                ]),
                const SizedBox(height: 3),
                Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${m.costTag} · ${m.time}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: nf(m.points), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const TextSpan(text: 'P', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.yellowInk)),
              ])),
              const SizedBox(height: 4),
              TicketChip(ticketsFor(m), boxed: false),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── 공동구매 ──────────────────────────────────────────────────────────────

class _GroupBuys extends StatefulWidget {
  final AppNav nav;
  const _GroupBuys({required this.nav});
  @override
  State<_GroupBuys> createState() => _GroupBuysState();
}

class _GroupBuysState extends State<_GroupBuys> {
  int cat = 0;

  static const _icons = {
    'soap': (Icons.soap_outlined, Color(0xFFEAF4F8), Color(0xFF3C8DB0)),
    'granola': (Icons.breakfast_dining_outlined, Color(0xFFFBF1E3), Color(0xFFB7792E)),
    'socks': (Icons.checkroom_rounded, Color(0xFFF1EEFF), AppColors.purple),
    'citrus': (Icons.eco_outlined, Color(0xFFFFF1DC), AppColors.orange),
  };

  @override
  Widget build(BuildContext context) {
    final list = cat == 0 ? groupBuys : groupBuys.where((g) => g.cat == groupBuyCats[cat]).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
        child: Row(children: [
          const Icon(Icons.share_outlined, size: 16, color: AppColors.green),
          const SizedBox(width: 6),
          const Expanded(child: Text('구매 확정 시 공유 수익 적립', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700))),
          MoreLink(label: '이용 안내', onTap: () => _guide(context)),
        ]),
      ),
      ChipRow(labels: groupBuyCats, index: cat, onChanged: (i) => setState(() => cat = i)),
      const SizedBox(height: 4),
      for (final g in list) _card(g),
    ]);
  }

  Widget _card(GroupBuy g) {
    final art = _icons[g.icon]!;
    return Sec(
      padding: const EdgeInsets.all(14),
      child: Tap(
        onTap: () => _open(g),
        radius: 12,
        child: Row(children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(color: art.$2, borderRadius: BorderRadius.circular(14)),
            child: Icon(art.$1, size: 44, color: art.$3),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Pill('공유 시 ${g.share}% 적립', bg: AppColors.greenSoft, fg: AppColors.greenDeep),
              const SizedBox(height: 6),
              Text(g.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.35)),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: '${g.discount}% ', style: const TextStyle(color: AppColors.red)),
                  TextSpan(text: '${nf(g.price)} '),
                  TextSpan(
                    text: nf(g.list),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.faint, decoration: TextDecoration.lineThrough),
                  ),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(value: g.joined / g.target, minHeight: 4, backgroundColor: AppColors.page, color: AppColors.yellow),
              ),
              const SizedBox(height: 4),
              Text('${g.joined}/${g.target}명 · ${g.left}', style: TextStyle(fontSize: 12, color: g.daysLeft == 0 ? AppColors.red : AppColors.sub)),
            ]),
          ),
        ]),
      ),
    );
  }

  void _guide(BuildContext context) => showSheet(
        context,
        (_) => const SheetFrame(
          title: '공동구매 이용 안내',
          child: Text(
            '· 목표 인원이 모이면 주문이 확정돼요. 모이지 않으면 전액 환불돼요.\n'
            '· 내 링크로 지인이 사면 판매가의 일부가 원으로 적립돼요. 구매 확정 후 적립되고, 환불·취소 건은 빠져요.\n'
            '· 상품·배송·반품은 판매자 책임이에요. 겸사겸사는 통신판매중개자예요.\n'
            '· 지금은 체험 화면이라 실제 결제가 이루어지지 않아요.',
            style: TextStyle(fontSize: 14, height: 1.8, color: AppColors.inkSoft),
          ),
        ),
      );

  void _open(GroupBuy g) {
    var n = 3;
    showSheet(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SheetFrame(
          bottom: Row(children: [
            Expanded(
              child: BigButton(label: '같이 사기', bg: AppColors.page, fg: AppColors.inkSoft, onTap: () {
                Navigator.pop(ctx);
                widget.nav.flash('공동구매 결제는 판매자 연동 후 열려요 · 지금은 체험 화면이에요');
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: BigButton(label: '공유하고 벌기', bg: AppColors.ink, fg: Colors.white, onTap: () {
                Navigator.pop(ctx);
                widget.nav.flash('내 공유 링크를 만들었어요 · 지인이 구매 확정하면 적립돼요');
              }),
            ),
          ]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Text('${g.cat} · ', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
              const Pill('판매자 확인', bg: AppColors.greenSoft, fg: AppColors.greenDeep),
            ]),
            const SizedBox(height: 8),
            Text(g.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text.rich(TextSpan(children: [
              TextSpan(text: '${g.discount}% ', style: const TextStyle(color: AppColors.red)),
              TextSpan(text: won(g.price)),
            ]), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('${g.joined}명 참여 · 목표 ${g.target}명 · ${g.left} · 목표 미달 시 전액 환불', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('내 링크로 지인이 사면 · 판매가의 ${g.share}% 적립', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.greenDeep)),
                const SizedBox(height: 10),
                Row(children: [
                  for (final k in const [1, 3, 5, 10])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setS(() => n = k),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: n == k ? AppColors.greenDeep : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text('$k명', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: n == k ? Colors.white : AppColors.inkSoft)),
                        ),
                      ),
                    ),
                ]),
                const SizedBox(height: 10),
                Text('약 ${won(g.shareFor(n))}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.greenDeep)),
                const Text('구매 확정 후 원으로 적립 · 환불·취소 건 제외', style: TextStyle(fontSize: 12, color: AppColors.sub)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── 중고장터 · 나눔 ──────────────────────────────────────────────────────

class _Used extends StatefulWidget {
  final AppNav nav;
  final List<TaskItem> items;
  const _Used({required this.nav, required this.items});
  @override
  State<_Used> createState() => _UsedState();
}

class _UsedState extends State<_Used> {
  int f = 0;

  @override
  Widget build(BuildContext context) {
    final nav = widget.nav;
    return ListenableBuilder(
      listenable: nav.store,
      builder: (context, _) {
        final deliveries = widget.items.where((i) => i.extra == 'used' && !i.isExpired).toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Row(children: [
              _pill('${nav.area()} 물건', f == 0, () => setState(() => f = 0)),
              const SizedBox(width: 6),
              _pill('가는 길 전달', f == 1, () => setState(() => f = 1)),
            ]),
          ),
          if (f == 0)
            for (final u in nav.store.used.where((u) => !u.share)) UsedRow(u: u, liked: nav.store.likedUsed.contains(u.id), onTap: () => nav.openUsed(context, u))
          else ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 6, 20, 6),
              child: Text('다른 동네에서 거래한 물건을 가는 길에 전달해 주면 전달비를 받아요.', style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [for (final it in deliveries) EarnRow(it: it, onTap: () => nav.openTask(context, it))]),
            ),
          ],
        ]);
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
          child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: on ? Colors.white : AppColors.inkSoft)),
        ),
      );
}

class _Share extends StatelessWidget {
  final AppNav nav;
  const _Share({required this.nav});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: nav.store,
      builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Text('${nav.area()} 이웃이 나눔하는 물건이에요. 필요한 분이 가져가세요.', style: const TextStyle(fontSize: 13, color: AppColors.sub)),
        ),
        for (final u in nav.store.used.where((u) => u.share)) UsedRow(u: u, liked: nav.store.likedUsed.contains(u.id), onTap: () => nav.openUsed(context, u)),
      ]),
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
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          UsedArt(u.art),
          const SizedBox(width: 14),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 98),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(u.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.35)),
                const SizedBox(height: 3),
                Text('${u.area}${u.distM > 0 ? ' · ${u.distLabel}' : ''} · ${u.ago}', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
                const SizedBox(height: 3),
                u.share
                    ? const Pill('나눔', bg: AppColors.greenSoft, fg: AppColors.greenDeep)
                    : Text(won(u.price), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (u.chats > 0) ...[
                    const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.sub),
                    const SizedBox(width: 3),
                    Text('${u.chats}', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
                    const SizedBox(width: 8),
                  ],
                  Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 14, color: liked ? AppColors.red : AppColors.sub),
                  const SizedBox(width: 3),
                  Text('${u.likes + (liked ? 1 : 0)}', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
