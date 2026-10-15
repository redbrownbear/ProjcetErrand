import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/kit.dart';
import '../../errand/data/countries.dart';
import '../../errand/models/task_item.dart';
import '../../lucky/models/tickets.dart';
import '../../overseas/data/local_helps.dart';
import '../../proposal/widgets/live_board.dart';
import '../widgets/hero_card.dart';
import '../widgets/home_sections.dart';

/// 홈 · 해외 — 부탁하기 / 돈벌기 / 현지 이웃. 해외는 파란색이다 (시안 v42~v44).
class OverseasHome extends StatefulWidget {
  final AppNav nav;
  final List<TaskItem> items;
  final int initialSeg;
  const OverseasHome({super.key, required this.nav, required this.items, this.initialSeg = 0});

  @override
  State<OverseasHome> createState() => OverseasHomeState();
}

class OverseasHomeState extends State<OverseasHome> {
  late int seg = widget.initialSeg;
  AppNav get nav => widget.nav;

  void showSeg(int i) => setState(() => seg = i);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Seg(labels: const ['부탁하기', '돈벌기', '현지 이웃'], index: seg, onChanged: showSeg),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: switch (seg) {
          0 => _ask(),
          1 => _earn(),
          _ => _LocalNeighbors(key: const ValueKey('local'), nav: nav),
        },
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 6),
        child: Text(
          seg == 2 ? '예시는 체험용이며 실제 제안은 현지 거주 인증 후 공개돼요' : '해외 사다주기는 안전결제로만 진행돼요',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.faint),
        ),
      ),
    ]);
  }

  Widget _board() => ListenableBuilder(
        listenable: nav.store,
        builder: (context, _) => LiveBoard(
          store: nav.store,
          abroad: true,
          onOpen: (p) => nav.openProposal(context, p),
          onAll: () => nav.openProposalList(context, abroad: true),
          onPropose: () => nav.openPropose(context, abroad: true),
          onSponsor: () => nav.flash('제휴 디저트 매장 쿠폰은 제휴 확정 후 받을 수 있어요'),
        ),
      );

  // ── 부탁하기 ────────────────────────────────────────────────────────────

  Widget _ask() {
    final draw = LuckyDraw(DateTime.now());
    final now = DateTime.now();
    return Column(key: const ValueKey('ask'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      HeroCard(
        blue: true,
        sub: '해외 사다주기',
        title: const [('한국에 없는 물건\n', false), ('여행 가는 이웃', true), ('에게 부탁해요', false)],
        live: const [
          (bold: '미국 코스트코 영양제', meta: '완료 · 서초동 · 어제'),
          (bold: '도쿄 한정 굿즈 사다주기', meta: '완료 · 방배동 · 1시간 전'),
        ],
        drawLabel: draw.label,
        bubbleSub: '해외 부탁 완료 시 응모권 +2',
        onBubble: () => nav.openLucky(context),
        cta: '해외 부탁하기',
        onCta: nav.openSeaForm,
        note: '상품값은 선결제, 가격변동 예비금 30%가 함께 계산돼요',
        floats: const ['globe', 'bag', 'heart'],
      ),
      _board(),
      TripTools(nav: nav, abroad: true),
      Container(
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.liveBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.liveLine)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text('이번 주 출국 이웃 ', style: TextStyle(fontSize: 12, color: AppColors.sub)),
            Text('${departures.fold(0, (s, d) => s + d.people)}명', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            const Spacer(),
            GestureDetector(
              onTap: () => nav.openTripForm(context),
              child: const Text('여행 가세요?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue)),
            ),
          ]),
          const SizedBox(height: 6),
          const Text('여행 가는 이웃이 사다줘요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              for (final (i, d) in departures.indexed)
                Container(
                  height: 32,
                  decoration: BoxDecoration(border: i == departures.length - 1 ? null : const Border(bottom: BorderSide(color: Color(0x12FFFFFF)))),
                  child: Row(children: [
                    Container(
                      width: 34,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(6)),
                      child: Text(d.cc, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.6)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(d.city, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
                    Text(_md(now.add(Duration(days: d.plusDays))), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.yellow)),
                    const SizedBox(width: 10),
                    Text('이웃 ${d.people}명', style: const TextStyle(fontSize: 12, color: Color(0x99FFFFFF))),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
      Sec(
        title: '이렇게 진행돼요',
        child: Column(children: [
          _step(1, '부탁 올리기', '상품과 예상가를 적으면 가격변동 예비금 30%가 자동으로 붙어요'),
          _step(2, '여행자가 수락·구매', '현지에서 사고 영수증을 올려요'),
          _step(3, '받고 정산', '물건을 받으면 부탁 비용이 정산되고, 남은 예비금은 돌려드려요'),
          const _CustomsNote(),
        ]),
      ),
    ]);
  }

  static String _md(DateTime d) => '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} 출국';

  Widget _step(int n, String t, String s) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.blueSoft, shape: BoxShape.circle),
            child: Text('$n', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.blue)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(s, style: const TextStyle(fontSize: 12.5, color: AppColors.sub, height: 1.5)),
            ]),
          ),
        ]),
      );

  // ── 돈벌기 ──────────────────────────────────────────────────────────────

  Widget _earn() {
    final draw = LuckyDraw(DateTime.now());
    return Column(key: const ValueKey('earn'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      HeroCard(
        blue: true,
        sub: '여행이 부업이 되는 시간',
        title: const [('여행 가는 김에 사다주고\n', false), ('부탁 비용', true), ('을 받아요', false)],
        live: const [
          (bold: '타이베이 펑리수 전달', meta: '18,000원 정산 · 하은 님 · 어제'),
          (bold: '도쿄 바나나 전달', meta: '12,000원 정산 · 민지 님 · 2일 전'),
        ],
        drawLabel: draw.label,
        bubbleSub: '사다주면 응모권 +${TicketRules.seaDone.n}',
        onBubble: () => nav.openLucky(context),
        cta: '여행 일정 알리기',
        ctaIcon: 'plane',
        onCta: () => nav.openTripForm(context),
        note: '출국 일정을 알려두면 그 나라 요청이 먼저 보여요',
        floats: const ['plane', 'wallet', 'bag'],
      ),
      _SeaRequests(items: widget.items.where((i) => i.mode == 'sea' && !i.isMine).toList(), nav: nav),
      _board(),
      TripTools(nav: nav, abroad: true),
    ]);
  }
}

class _CustomsNote extends StatelessWidget {
  const _CustomsNote();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(14)),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline_rounded, size: 17, color: AppColors.sub),
        SizedBox(width: 9),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('통관비용은 따로 상의해 주세요', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            SizedBox(height: 3),
            Text('구매 금액과 상품 종류에 따라 관세·부가세가 달라져요. 부탁하기 전에 여행자와 꼭 이야기해 주세요.', style: TextStyle(fontSize: 12, color: AppColors.sub, height: 1.5)),
          ]),
        ),
      ]),
    );
  }
}

/// 해외 요청 사다주기 — 나라 칩 + 예상가 · 예비금 30% · 부탁 비용
class _SeaRequests extends StatefulWidget {
  final List<TaskItem> items;
  final AppNav nav;
  const _SeaRequests({required this.items, required this.nav});
  @override
  State<_SeaRequests> createState() => _SeaRequestsState();
}

class _SeaRequestsState extends State<_SeaRequests> {
  int f = 0;
  static const _ccs = ['', 'jp', 'us', 'gb', 'vn', 'tw'];

  String _man(int won) {
    final v = won / 10000;
    return v == v.roundToDouble() ? '${v.round()}만원' : '${v.toStringAsFixed(1)}만원';
  }

  @override
  Widget build(BuildContext context) {
    final list = f == 0 ? widget.items : widget.items.where((i) => i.cc == _ccs[f]).toList();
    return Sec(
      title: '해외 요청 사다주기',
      more: '전체보기',
      onMore: () => setState(() => f = 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ChipRow(labels: ['전체', for (final c in _ccs.skip(1)) countryOf(c).name], index: f, onChanged: (i) => setState(() => f = i)),
        const SizedBox(height: 6),
        if (list.isEmpty)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('이 나라 요청이 아직 없어요', style: TextStyle(color: AppColors.sub)))),
        for (final it in list)
          Tap(
            onTap: () => widget.nav.openTask(context, it),
            radius: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
              child: Row(children: [
                CodeBox((it.cc ?? '').toUpperCase(), bg: AppColors.redSoft, fg: AppColors.red, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${countryOf(it.cc).name} ${it.city ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.sub)),
                    const SizedBox(height: 2),
                    Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    if (it.budget > 0) ...[
                      const SizedBox(height: 4),
                      Wrap(spacing: 4, runSpacing: 4, children: [
                        Pill('예상가 ${_man(it.budget)}', bg: AppColors.page, fg: AppColors.inkSoft),
                        Pill('예비금 30% ${_man((it.budget * 0.3).round())}', bg: AppColors.blueSoft, fg: AppColors.blue),
                      ]),
                    ],
                  ]),
                ),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('부탁 비용', style: TextStyle(fontSize: 11, color: AppColors.sub)),
                  Text(won(it.price), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ]),
              ]),
            ),
          ),
        const _CustomsNote(),
      ]),
    );
  }
}

/// 현지 이웃 — 그 나라에 사는 이웃이 직접 도와드려요
class _LocalNeighbors extends StatefulWidget {
  final AppNav nav;
  const _LocalNeighbors({super.key, required this.nav});
  @override
  State<_LocalNeighbors> createState() => _LocalNeighborsState();
}

class _LocalNeighborsState extends State<_LocalNeighbors> {
  int kind = 0;
  int country = 0;

  @override
  Widget build(BuildContext context) {
    final ccs = ['', ...{for (final h in localHelps) h.cc}];
    final list = localHelps.where((h) {
      if (kind > 0 && h.kind != localHelpKinds[kind - 1]) return false;
      if (country > 0 && h.cc != ccs[country]) return false;
      return true;
    }).toList();

    return ListenableBuilder(
      listenable: widget.nav.store,
      builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.heroBlue, Colors.white]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('현지 이웃', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue)),
            SizedBox(height: 4),
            Text('그 나라에 사는 이웃이\n직접 도와드려요', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.35, letterSpacing: -1)),
            SizedBox(height: 6),
            Text('쉐어하우스, 가이드, 통역, 정착까지 · 현지에서 직접 만나서 진행해요', style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
          ]),
        ),
        const SizedBox(height: 10),
        ChipRow(labels: const ['전체', ...localHelpKinds], index: kind, onChanged: (i) => setState(() => kind = i)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
          child: Row(children: [
            Expanded(child: ChipRow(labels: [for (final c in ccs) c.isEmpty ? '전체' : countryOf(c).name], index: country, onChanged: (i) => setState(() => country = i))),
            Text('${list.length}건', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.sub)),
          ]),
        ),
        for (final h in list) _card(h),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
          child: BigButton(
            label: '현지에서 도움 제안하기',
            icon: 'plus',
            bg: AppColors.blue,
            fg: Colors.white,
            onTap: () => widget.nav.flash('현지 거주 인증을 마친 이웃만 제안할 수 있어요 · 인증은 준비 중이에요'),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text('택배·배송은 할 수 없고, 현지에서 직접 하는 일만 올릴 수 있어요', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.sub)),
        ),
      ]),
    );
  }

  Widget _card(LocalHelp h) {
    final applied = widget.nav.store.appliedLocal.contains(h.id);
    final n = h.applied + (applied ? 1 : 0);
    final full = n >= h.max && !applied;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Avatar(h.who, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h.who, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              Text(h.lives, style: const TextStyle(fontSize: 12, color: AppColors.sub)),
            ]),
          ),
          const Pill('현지 거주 확인', bg: AppColors.greenSoft, fg: AppColors.greenDeep),
        ]),
        const SizedBox(height: 12),
        Text(h.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        const SizedBox(height: 6),
        Row(children: [
          Pill(h.kind, bg: AppColors.blueSoft, fg: AppColors.blue),
          const SizedBox(width: 6),
          Expanded(child: Text(h.detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.sub))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Text(won(h.price), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Text('신청 $n/${h.max}', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
          const Spacer(),
          SizedBox(
            width: 112,
            child: BigButton(
              label: applied ? '신청 취소' : (full ? '마감' : '저 신청할래요!'),
              height: 38,
              bg: applied ? AppColors.page : AppColors.ink,
              fg: applied ? AppColors.inkSoft : Colors.white,
              onTap: full ? null : () => widget.nav.store.applyLocal(h.id),
            ),
          ),
        ]),
      ]),
    );
  }
}
