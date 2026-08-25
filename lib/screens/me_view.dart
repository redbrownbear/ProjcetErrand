import 'package:flutter/material.dart';

import '../theme/colors.dart';

class MeView extends StatelessWidget {
  const MeView({super.key});
  @override
  Widget build(BuildContext context) {
    final rows = [
      ['🛡', '안전 · 본인인증', '인증 완료'],
      ['📍', '위치 노출 범위', '동 단위'],
      ['🚻', '매칭 성별 설정', '제한 없음'],
      ['🚫', '차단한 이웃', '0명'],
      ['⭐', '받은 후기', '4.9 (11)'],
    ];
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(children: [
            Container(
              width: 58, height: 58, alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.yellowSoft, shape: BoxShape.circle),
              child: const Text('🌱', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('새싹 이웃님', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
                Text('서초동 · 품온도 40.6℃', style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
              ],
            ),
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('이번 달 번 돈', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('420,000원', style: TextStyle(color: AppColors.yellow, fontSize: 22, fontWeight: FontWeight.w900)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('완료', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('6건', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              ]),
            ],
          ),
        ),
        for (final r in rows)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
            child: Row(children: [
              Text(r[0], style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(child: Text(r[1], style: const TextStyle(fontSize: 14, color: AppColors.ink))),
              Text('${r[2]} ›', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
            ]),
          ),
      ],
    );
  }
}
