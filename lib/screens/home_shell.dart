import 'package:flutter/material.dart';

import '../data/items.dart';
import '../models/offer.dart';
import '../models/task_item.dart';
import '../theme/colors.dart';
import '../widgets/region_sheet.dart';
import 'chat_view.dart';
import 'detail_page.dart';
import 'home_content.dart';
import 'list_screen.dart';
import 'map_view.dart';
import 'me_view.dart';
import 'post_request.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  String tab = 'home'; // home | map | chat | me
  String? listKind; // null | help | sea
  TaskItem? detail;
  bool post = false;
  bool regionOpen = false;
  List<int> grabbed = [];
  Map<int, List<Offer>> offers = {};
  String? toast;
  late List<TaskItem> items;
  String scope = '서울 서초구';

  @override
  void initState() {
    super.initState();
    items = List.of(seedItems);
  }

  void flash(String m) {
    setState(() => toast = m);
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => toast = null);
    });
  }

  void grab(TaskItem it) {
    setState(() {
      if (!grabbed.contains(it.id)) grabbed.add(it.id);
      detail = null;
    });
    flash(it.mode == 'together' ? '신청했어요. 채팅으로 이어드릴게요' : '지원했어요. 요청자가 확인하면 매칭돼요');
  }

  void sendOffer(TaskItem it, int price, String msg) {
    setState(() {
      offers.putIfAbsent(it.id, () => []).add(Offer(price, msg));
    });
    flash('가격 제안을 보냈어요. 요청자에게만 보여요');
  }

  void addRequest(NewRequestData data) {
    final it = TaskItem(
      id: DateTime.now().millisecondsSinceEpoch,
      mode: data.mode,
      cat: data.cat,
      title: data.title,
      desc: data.desc,
      place: data.place.isEmpty ? (data.mode == 'sea' ? null : '우리 동네') : data.place,
      country: data.country.isEmpty ? null : data.country,
      region: data.mode == 'sea' ? null : (scope == '전국' ? '우리 동네' : scope),
      distM: 150,
      mins: data.mode == 'sea' ? 0 : data.mins,
      price: data.price,
      who: '나',
      hot: data.hot,
      x: 50, y: 50,
    );
    setState(() {
      if (it.hot) {
        items.insert(0, it);
      } else {
        final i = items.indexWhere((x) => !x.hot);
        if (i == -1) {
          items.add(it);
        } else {
          items.insert(i, it);
        }
      }
      post = false;
    });
    flash(it.hot ? '급해요로 목록 맨 위에 올렸어요' : '부탁을 올렸어요');
  }

  Widget _body() {
    switch (tab) {
      case 'map':
        return MapView(items: items, grabbed: grabbed, openDetail: (it) => setState(() => detail = it));
      case 'chat':
        return ChatView(items: items, grabbed: grabbed);
      case 'me':
        return const MeView();
      default:
        return HomeContent(
          items: items,
          scope: scope,
          grabbed: grabbed,
          openDetail: (it) => setState(() => detail = it),
          openPost: () => setState(() => post = true),
          openList: (k) => setState(() => listKind = k),
          openRegion: () => setState(() => regionOpen = true),
        );
    }
  }

  Widget _bottomNav() {
    final tabs = [
      ['home', '홈', '🏠'],
      ['map', '지도', '🗺️'],
      ['chat', '채팅', '💬'],
      ['me', '내정보', '👤'],
    ];
    return Container(
      decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.line))),
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          _navBtn(tabs[0]),
          _navBtn(tabs[1]),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: InkWell(
                    onTap: () => setState(() => post = true),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 52, height: 52, alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(18)),
                      child: const Text('＋', style: TextStyle(fontSize: 26, color: AppColors.ink)),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                const Text('부탁', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ],
            ),
          ),
          _navBtn(tabs[2], badge: grabbed.length),
          _navBtn(tabs[3]),
        ],
      ),
    );
  }

  Widget _navBtn(List<String> t, {int badge = 0}) {
    final k = t[0], label = t[1], icon = t[2];
    final active = tab == k;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => tab = k),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(clipBehavior: Clip.none, children: [
                Opacity(opacity: active ? 1 : 0.55, child: Text(icon, style: const TextStyle(fontSize: 19))),
                if (badge > 0)
                  Positioned(
                    right: -10, top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(99)),
                      child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ]),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(fontSize: 11, color: active ? AppColors.ink : AppColors.faint, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Stack(
          children: [
            Column(children: [Expanded(child: _body()), _bottomNav()]),
            if (listKind != null)
              ListScreen(
                kind: listKind!,
                items: items,
                scope: scope,
                grabbed: grabbed,
                onClose: () => setState(() => listKind = null),
                openDetail: (it) => setState(() => detail = it),
              ),
            if (detail != null)
              DetailPage(
                it: detail!,
                grabbed: grabbed,
                myOffers: offers[detail!.id] ?? const [],
                onClose: () => setState(() => detail = null),
                onGrab: grab,
                onOffer: sendOffer,
              ),
            if (post) PostRequest(scope: scope, onClose: () => setState(() => post = false), onSubmit: addRequest),
            if (regionOpen)
              RegionSheet(
                scope: scope,
                onPick: (r) => setState(() {
                  scope = r;
                  regionOpen = false;
                }),
                onClose: () => setState(() => regionOpen = false),
              ),
            if (toast != null)
              Positioned(
                left: 22, right: 22, bottom: 92,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(14)),
                    child: Text(toast!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
