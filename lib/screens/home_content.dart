import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../data/items.dart';
import '../models/filters.dart';
import '../models/task_item.dart';
import '../theme/colors.dart';
import '../widgets/chip_widget.dart';
import '../widgets/earn_view.dart';
import '../widgets/mode_card.dart';
import '../widgets/task_card.dart';

class HomeContent extends StatelessWidget {
  final String mode;
  final void Function(String) setMode;
  final Map<int, String> status;
  final void Function(TaskItem) onApply;
  final void Function(TaskItem) onOpenDetail;
  final bool sortPrice;
  final void Function(bool) setSortPrice;
  final VoidCallback openFilter;
  final Filters flt;
  final VoidCallback goMap;

  const HomeContent({
    super.key, required this.mode, required this.setMode, required this.status, required this.onApply,
    required this.onOpenDetail, required this.sortPrice, required this.setSortPrice, required this.openFilter,
    required this.flt, required this.goMap,
  });

  @override
  Widget build(BuildContext context) {
    var feed = items.where((i) {
      if (mode == 'ask' || mode == 'earn') return i.mode == 'ask';
      if (mode == 'together') return i.mode == 'together';
      if (mode == 'share') return i.mode == 'share';
      return i.mode == 'ask';
    }).toList();

    if (mode != 'together' && mode != 'share') {
      feed = feed.where((i) => i.price <= flt.maxPrice && i.dist <= flt.maxDist && (flt.gender == 'all' || i.gender == flt.gender) && i.age >= flt.ageMin && i.age <= flt.ageMax).toList();
    }
    feed.sort((a, b) {
      final h = (b.hot ? 1 : 0) - (a.hot ? 1 : 0);
      if (h != 0) return h;
      return sortPrice ? b.price - a.price : 0;
    });

    final free = items.where((i) => i.mode == 'together').toList();
    final shares = items.where((i) => i.mode == 'share').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: const [
                  Text('서초구 서초동', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  SizedBox(width: 4),
                  Text('▾', style: TextStyle(color: AppColors.sub, fontSize: 12)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(99)),
                  child: const Text('3,200P', style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.w800, fontSize: 12.5)),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 2, 20, 12),
            child: Text('오늘 뭐 할까?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink)),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
            child: const Text('🔍 줄서기, 카풀, 나눔, 영화 같이…', style: TextStyle(color: AppColors.sub, fontSize: 13.5)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(children: [
              ModeCard(active: mode == 'ask', onTap: () => setMode('ask'), bg: AppColors.yellow, title: '부탁해요', tcol: AppColors.ink),
              const SizedBox(width: 8),
              ModeCard(active: mode == 'together', onTap: () => setMode('together'), bg: AppColors.gray, title: '같이해요', tcol: AppColors.ink),
              const SizedBox(width: 8),
              ModeCard(active: mode == 'share', onTap: () => setMode('share'), bg: AppColors.greenSoft, title: '나눔', tcol: AppColors.green),
              const SizedBox(width: 8),
              ModeCard(active: mode == 'earn', onTap: () => setMode('earn'), bg: AppColors.blueSoft, title: '돈벌기', tcol: AppColors.blue),
            ]),
          ),
          if (mode == 'earn') EarnView(onOpenDetail: onOpenDetail, status: status, onApply: onApply),
          if (mode != 'earn') ...[
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              padding: const EdgeInsets.fromLTRB(6, 14, 6, 10),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                children: cats.map((c) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42, height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.tone == 'together' ? AppColors.gray : c.tone == 'share' ? AppColors.greenSoft : AppColors.yellowSoft,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(c.icon, style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(height: 5),
                    Text(c.label, style: const TextStyle(fontSize: 10.5, color: AppColors.ink, fontWeight: FontWeight.w500)),
                  ],
                )).toList(),
              ),
            ),
            if (mode == 'home' || mode == 'ask') ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('내 주변 지금 뜬 일', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
                    TextButton(onPressed: goMap, child: const Text('지도 보기 ›', style: TextStyle(color: AppColors.sub, fontSize: 12.5))),
                  ],
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  children: [
                    ChipWidget(label: '💰 높은 금액순', active: sortPrice, onTap: () => setSortPrice(!sortPrice)),
                    const SizedBox(width: 7),
                    ChipWidget(label: '⚙️ 필터', onTap: openFilter),
                    const SizedBox(width: 7),
                    const ChipWidget(label: '🔥 급한 일만'),
                    const SizedBox(width: 7),
                    const ChipWidget(label: '📍 가까운 순'),
                  ],
                ),
              ),
              if (feed.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: Text('조건에 맞는 일이 없어요. 필터를 넓혀보세요.', style: TextStyle(color: AppColors.sub, fontSize: 13))),
                )
              else
                ...feed.map((it) => TaskCard(it: it, onOpen: () => onOpenDetail(it), onApply: () => onApply(it), st: status[it.id])),
            ],
            if (mode == 'home' || mode == 'together') ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: Text('같이할 사람', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
              ),
              if (mode == 'together')
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(12)),
                  child: const Text('🛡 본인인증한 이웃만 · 공개 장소 · 미성년자 보호', style: TextStyle(fontSize: 12, color: Color(0xFF1B8A5A), fontWeight: FontWeight.w600)),
                ),
              ...free.map((it) => TaskCard(it: it, onOpen: () => onOpenDetail(it), onApply: () => onApply(it), st: status[it.id])),
            ],
            if (mode == 'home' || mode == 'share') ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: Text('이웃 나눔 🎁', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
              ),
              ...shares.map((it) => TaskCard(it: it, onOpen: () => onOpenDetail(it), onApply: () => onApply(it), st: status[it.id])),
            ],
            if (mode == 'home')
              Container(
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () => setMode('earn'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('오늘 근처에서\n벌 수 있는 예상 금액', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4)),
                      Text('68,000원', style: TextStyle(color: AppColors.yellow, fontSize: 24, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
