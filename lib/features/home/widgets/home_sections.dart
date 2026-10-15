import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_nav.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/kit.dart';
import '../../errand/data/categories.dart';
import '../../errand/models/task_item.dart';
import '../../trip/models/trip_post.dart';
import '../data/local_shops.dart';

/// 홈 여러 갈래(국내 부탁하기 · 돈벌기 · 해외)가 같이 쓰는 카드들.

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
          ? Row(children: [
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
            ])
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
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.red, width: 5)),
        alignment: Alignment.center,
        child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle)),
      ),
    );
  }
}

/// '이런 것도 부탁해도 돼요' — 예시가 한 줄씩 넘어간다 (.can)
class AskIdeas extends StatefulWidget {
  final VoidCallback onAsk;
  const AskIdeas({super.key, required this.onAsk});
  @override
  State<AskIdeas> createState() => _AskIdeasState();
}

class _AskIdeasState extends State<AskIdeas> {
  int i = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 2800), (_) {
      if (mounted) setState(() => i = (i + 1) % askIdeas.length);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final idea = askIdeas[i];
    return Sec(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('이런 것도 부탁해도 돼요', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
        const SizedBox(height: 8),
        Container(
          height: 46,
          decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(14)),
          child: Tap(
            onTap: widget.onAsk,
            radius: 14,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (c, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a), child: c),
              ),
              child: Padding(
                key: ValueKey(i),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
                    child: AppIcon(idea.icon, size: 18, color: AppColors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(idea.text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700))),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var k = 0; k < askIdeas.length; k++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: k == i ? 14 : 5,
              height: 5,
              decoration: BoxDecoration(color: k == i ? AppColors.ink : AppColors.outline, borderRadius: BorderRadius.circular(3)),
            ),
        ]),
        Tap(
          onTap: widget.onAsk,
          radius: 8,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(
                child: Text(
                  '목록에 없어도 괜찮아요. 어떤 부탁이든 올려보세요',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.sub),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.sub),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// 동네 가게 광고 배너 — 넘겨 보는 카드 (.bn)
class ShopBanner extends StatefulWidget {
  final void Function(LocalShop) onOpen;
  const ShopBanner({super.key, required this.onOpen});
  @override
  State<ShopBanner> createState() => _ShopBannerState();
}

class _ShopBannerState extends State<ShopBanner> {
  final ctrl = PageController();
  int page = 0;
  Timer? _t;
  static final _shops = localShops.take(5).toList();

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !ctrl.hasClients) return;
      ctrl.animateToPage((page + 1) % _shops.length, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      height: 92,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Stack(children: [
        PageView.builder(
          controller: ctrl,
          itemCount: _shops.length,
          onPageChanged: (p) => setState(() => page = p),
          itemBuilder: (_, k) {
            final s = _shops[k];
            return GestureDetector(
              onTap: () => widget.onOpen(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFF6EC), Color(0xFFFDF1E6)])),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
                    child: AppIcon(s.icon, size: 22, color: const Color(0xFFE5772E)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Row(children: [
                        Flexible(child: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD27700)))),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0x0F000000), borderRadius: BorderRadius.circular(4)),
                          child: const Text('광고', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.sub)),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text(s.benefit, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      Text('${s.area} · ${s.dist}${s.extra == null ? '' : ' · ${s.extra}'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.sub)),
                    ]),
                  ),
                ]),
              ),
            );
          },
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(color: const Color(0x59191F28), borderRadius: BorderRadius.circular(8)),
            child: Text('${page + 1} / ${_shops.length}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

/// 가게 시트 — 혜택 · 위치 · 지도 열기 (국내는 네이버 지도)
void openShopSheet(BuildContext context, LocalShop s, {required VoidCallback onMissions}) {
  showSheet(
    context,
    (ctx) => SheetFrame(
      title: s.name,
      sub: '${s.cat} · ${s.area} · ${s.dist}',
      bottom: Row(children: [
        Expanded(
          child: BigButton(
            label: '지도에서 보기',
            bg: AppColors.page,
            fg: AppColors.inkSoft,
            onTap: () => launchUrl(Uri.parse('https://map.naver.com/p/search/${Uri.encodeComponent(s.name)}'), mode: LaunchMode.externalApplication),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: BigButton(label: '방문 미션 보기', onTap: () {
            Navigator.pop(ctx);
            onMissions();
          }),
        ),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFFFF6EC), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: AppIcon(s.icon, size: 24, color: const Color(0xFFE5772E)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(s.benefit, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.4))),
          ]),
        ),
        const SizedBox(height: 12),
        const Text(
          '광고 · 체험용 예시 가게예요. 제휴가 확정되면 방문 인증과 매장 후기(사진 · 0.1점 단위 별점)를 남길 수 있어요.',
          style: TextStyle(fontSize: 12.5, color: AppColors.sub, height: 1.55),
        ),
      ]),
    ),
  );
}

/// 자주 하는 부탁 — 10칸 (.cats)
class CatGrid extends StatelessWidget {
  final void Function(String cat) onCat;
  const CatGrid({super.key, required this.onCat});

  @override
  Widget build(BuildContext context) {
    return Sec(
      title: '자주 하는 부탁',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          childAspectRatio: 0.82,
          children: [
            for (final c in cats)
              Tap(
                onTap: () => onCat(c.k),
                radius: 12,
                child: Column(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: AppColors.catTileBg, borderRadius: BorderRadius.circular(15)),
                    child: Icon(AppIcon.cat(c.k), size: 23, color: AppColors.catTileFg),
                  ),
                  const SizedBox(height: 7),
                  Text(c.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

/// 미션 · 공동구매 · 중고장터 · 가는 김에 · 전체 숏컷 (.hq)
class QuickLinks extends StatelessWidget {
  final List<(String icon, String label, VoidCallback onTap)> items;
  const QuickLinks({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        for (final (icon, label, onTap) in items)
          Expanded(
            child: Tap(
              onTap: onTap,
              radius: 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(children: [
                  AppIcon(icon, size: 22, color: AppColors.inkSoft),
                  const SizedBox(height: 4),
                  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.inkSoft)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

/// 우리 동네 제휴 가게 가로 목록 (.sr)
class ShopStrip extends StatelessWidget {
  final void Function(LocalShop) onOpen;
  final VoidCallback onAll;
  const ShopStrip({super.key, required this.onOpen, required this.onAll});

  @override
  Widget build(BuildContext context) {
    return Sec(
      title: '우리 동네 제휴 가게',
      more: '전체',
      onMore: onAll,
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
      child: SizedBox(
        height: 98,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: localShops.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final s = localShops[i];
            return Container(
              width: 93,
              decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(14)),
              child: Tap(
                onTap: () => onOpen(s),
                radius: 14,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: AppIcon(s.icon, size: 19, color: const Color(0xFFE5772E)),
                    ),
                    const Spacer(),
                    Text(s.short, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    Text(s.shortBenefit, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
                  ]),
                ),
              ),
            );
          },
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('가는 김에', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                  SizedBox(height: 3),
                  Text('사람들은 지금 어디로 가고 있을까요?', style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
                ]),
              ),
              LineButton(label: '글쓰기', icon: 'pencil', height: 28, onTap: () => nav.openTripForm(context)),
              const SizedBox(width: 6),
              MoreLink(label: '전체보기', onTap: onAll),
            ]),
          ),
          for (final t in nav.store.trips.take(take)) ...[
            TripCard(t: t, onCta: () => t.going ? nav.openAskForm() : nav.flash('도와주기 의사를 전했어요 · ${t.author} 님이 확인하면 채팅이 열려요')),
            const SizedBox(height: 8),
          ],
        ]),
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
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Avatar(t.author),
          const SizedBox(width: 8),
          Text(t.mine ? '나' : t.author, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text('${t.area} · ${t.ago}', style: const TextStyle(fontSize: 12, color: AppColors.sub)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          if (t.cc != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(5)),
              child: Text(t.cc!.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.inkSoft)),
            )
          else
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(5)),
              child: const Icon(Icons.shopping_bag_outlined, size: 12, color: AppColors.inkSoft),
            ),
          const SizedBox(width: 6),
          Flexible(child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
          const SizedBox(width: 6),
          Flexible(child: Text(t.when, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.faint))),
        ]),
        const SizedBox(height: 5),
        Text('“${t.quote}”', style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.5)),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.sub),
          const SizedBox(width: 4),
          Text('댓글 ${t.comments}', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
          const Spacer(),
          if (!t.mine) LineButton(label: t.going ? '부탁하기' : '도와주기', onTap: onCta),
        ]),
      ]),
    );
  }
}

/// 돈벌기 목록 한 줄 (.row)
class EarnRow extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onTap;
  final int tickets;
  const EarnRow({super.key, required this.it, required this.onTap, this.tickets = 3});

  @override
  Widget build(BuildContext context) {
    final used = it.extra == 'used';
    final tone = AppColors.taskIcon[used ? 'used' : it.cat] ?? AppColors.taskIconFallback;
    return Tap(
      onTap: onTap,
      radius: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(14)),
            child: Icon(used ? Icons.storefront_outlined : AppIcon.cat(it.cat), size: 23, color: tone.fg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                [it.place ?? '', if (it.distM != null) distLabel(it), if (it.mins > 0) '약 ${it.mins}분'].where((s) => s.isNotEmpty).join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.sub),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (used)
              const Pill('중고', bg: Color(0xFFE6F6EE), fg: AppColors.greenDeep)
            else if (it.hot)
              const Pill('급해요', bg: AppColors.redSoft, fg: AppColors.red)
            else
              const Pill('지금 가능'),
            const SizedBox(height: 3),
            Text(won(it.price), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.45)),
            const SizedBox(height: 3),
            TicketChip(tickets, boxed: false),
          ]),
        ]),
      ),
    );
  }
}
