import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/kit.dart';
import '../../../core/widgets/surface.dart';
import '../../errand/data/countries.dart';
import '../data/local_helps.dart';

/// 현지 이웃 — 그 나라에 사는 이웃이 직접 도와드려요
class LocalNeighbors extends StatefulWidget {
  final AppNav nav;
  const LocalNeighbors({super.key, required this.nav});
  @override
  State<LocalNeighbors> createState() => LocalNeighborsState();
}

class LocalNeighborsState extends State<LocalNeighbors> {
  int kind = 0;
  int country = 0;

  @override
  Widget build(BuildContext context) {
    final ccs = [
      '',
      ...{for (final h in localHelps) h.cc},
    ];
    final list = localHelps.where((h) {
      if (kind > 0 && h.kind != localHelpKinds[kind - 1]) return false;
      if (country > 0 && h.cc != ccs[country]) return false;
      return true;
    }).toList();

    return ListenableBuilder(
      listenable: widget.nav.store,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEEF4FF), Colors.white],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '현지 이웃',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue),
                ),
                SizedBox(height: 4),
                Text(
                  '그 나라에 사는 이웃이\n직접 도와드려요',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.35, letterSpacing: -1),
                ),
                SizedBox(height: 6),
                Text('쉐어하우스, 가이드, 통역, 정착까지 · 현지에서 직접 만나서 진행해요', style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ChipRow(labels: const ['전체', ...localHelpKinds], index: kind, onChanged: (i) => setState(() => kind = i)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: ChipRow(
                    labels: [for (final c in ccs) c.isEmpty ? '전체' : countryOf(c).name],
                    index: country,
                    onChanged: (i) => setState(() => country = i),
                  ),
                ),
                Text(
                  '${list.length}건',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.sub),
                ),
              ],
            ),
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
            child: Text(
              '택배·배송은 할 수 없고, 현지에서 직접 하는 일만 올릴 수 있어요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.sub),
            ),
          ),
        ],
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(h.who, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.who, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    Text(h.lives, style: const TextStyle(fontSize: 12, color: AppColors.sub)),
                  ],
                ),
              ),
              const StatusBadge('현지 거주 확인', bg: AppColors.greenSoft, fg: AppColors.greenDeep),
            ],
          ),
          const SizedBox(height: 12),
          Text(h.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          const SizedBox(height: 6),
          Row(
            children: [
              StatusBadge(h.kind, bg: AppColors.blueSoft, fg: AppColors.blue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  h.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.sub),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: won(h.price),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink),
                      ),
                      TextSpan(text: '  신청 $n/${h.max}'),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.sub),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 112,
                child: BigButton(
                  label: applied ? '신청 취소' : (full ? '마감' : '저 신청할래요!'),
                  height: 38,
                  bg: applied ? AppColors.page : AppColors.ink,
                  fg: applied ? AppColors.ink2 : Colors.white,
                  onTap: full ? null : () => widget.nav.store.applyLocal(h.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
