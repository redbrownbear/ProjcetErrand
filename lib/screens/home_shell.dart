import 'package:flutter/material.dart';

import '../models/filters.dart';
import '../models/task_item.dart';
import '../theme/colors.dart';
import '../widgets/filter_sheet.dart';
import 'chat_view.dart';
import 'detail_page.dart';
import 'home_content.dart';
import 'map_view.dart';
import 'me_view.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  String nav = 'home';
  String mode = 'home';
  TaskItem? detail;
  Map<int, String> status = {};
  String? toast;
  bool filterOpen = false;
  bool sortPrice = false;
  Filters flt = Filters();

  void apply(TaskItem it) {
    setState(() {
      status[it.id] = 'pending';
      detail = null;
      toast = '신청했어요! 상대가 수락하면 매칭돼요';
    });
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() {
        status[it.id] = 'matched';
        toast = '${it.who} 님이 수락했어요! 채팅으로 이어져요';
      });
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => toast = null);
      });
    });
  }

  Widget _navBody() {
    switch (nav) {
      case 'map':
        return MapView(status: status, onOpenDetail: (it) => setState(() => detail = it));
      case 'chat':
        return ChatView(status: status);
      case 'me':
        return const MeView();
      default:
        return HomeContent(
          mode: mode,
          setMode: (m) => setState(() => mode = mode == m ? 'home' : m),
          status: status,
          onApply: apply,
          onOpenDetail: (it) => setState(() => detail = it),
          sortPrice: sortPrice,
          setSortPrice: (v) => setState(() => sortPrice = v),
          openFilter: () => setState(() => filterOpen = true),
          flt: flt,
          goMap: () => setState(() => nav = 'map'),
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
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        children: tabs.map((t) {
          final k = t[0], label = t[1], icon = t[2];
          final active = nav == k;
          final badge = k == 'chat' ? status.values.where((v) => v == 'pending' || v == 'matched').length : 0;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() {
                nav = k;
                if (k == 'home') mode = 'home';
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(clipBehavior: Clip.none, children: [
                      Opacity(opacity: active ? 1 : 0.55, child: Text(icon, style: const TextStyle(fontSize: 20))),
                      if (badge > 0)
                        Positioned(
                          right: -10,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.hot, borderRadius: BorderRadius.circular(99)),
                            child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 2),
                    Text(label, style: TextStyle(fontSize: 11, color: active ? AppColors.ink : AppColors.sub, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
            Column(children: [Expanded(child: _navBody()), _bottomNav()]),
            if (toast != null)
              Positioned(
                left: 20,
                right: 20,
                bottom: 78,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                    decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(14)),
                    child: Text(toast!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            if (detail != null)
              DetailPage(item: detail!, status: status[detail!.id], onClose: () => setState(() => detail = null), onApply: apply),
            if (filterOpen)
              FilterSheet(
                flt: flt,
                onClose: () => setState(() => filterOpen = false),
                onApplyFilters: (f) => setState(() {
                  flt = f;
                  filterOpen = false;
                }),
              ),
          ],
        ),
      ),
    );
  }
}
