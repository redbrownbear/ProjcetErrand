import 'package:flutter/material.dart';

import '../theme/colors.dart';

class MeView extends StatelessWidget {
  const MeView({super.key});
  @override
  Widget build(BuildContext context) {
    final rows = [
      ['🛡', '본인인증', '완료'],
      ['✈️', '해외 대행 활동', '가능'],
      ['💰', '수익·정산 내역', ''],
      ['⭐', '받은 후기', '4.9 (11)'],
      ['🚫', '신고 / 차단', ''],
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: 26),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
          child: Row(children: [
            Container(
              width: 58, height: 58, alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.yellowSoft, shape: BoxShape.circle),
              child: const Text('🙂', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('부릉부름 이웃님', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
                Padding(padding: EdgeInsets.only(top: 2), child: Text('✓ 본인인증 완료 · ★ 4.9 (11)', style: TextStyle(fontSize: 12.5, color: AppColors.green, fontWeight: FontWeight.w700))),
              ],
            ),
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(22, 10, 22, 16),
          decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            _stat('41회', '거래 완료'),
            _statDivider(),
            _stat('96%', '응답률'),
            _statDivider(),
            _stat('4.9', '후기 평점'),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(16)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🤝 도와준 횟수', style: TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w700)),
                    Padding(padding: EdgeInsets.only(top: 4), child: Text.rich(TextSpan(text: '27', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.green), children: [TextSpan(text: '번', style: TextStyle(fontSize: 13))]))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(16)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🙋 부탁한 횟수', style: TextStyle(fontSize: 12, color: AppColors.sub, fontWeight: FontWeight.w700)),
                    Padding(padding: EdgeInsets.only(top: 4), child: Text.rich(TextSpan(text: '14', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink), children: [TextSpan(text: '번', style: TextStyle(fontSize: 13))]))),
                  ],
                ),
              ),
            ),
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('이번 달 받은 사례비', style: TextStyle(color: Colors.white60, fontSize: 12)),
                Padding(padding: EdgeInsets.only(top: 3), child: Text('420,000원', style: TextStyle(color: AppColors.yellow, fontSize: 22, fontWeight: FontWeight.w900))),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('보유 포인트', style: TextStyle(color: Colors.white60, fontSize: 12)),
                Padding(padding: EdgeInsets.only(top: 3), child: Text('3,200P', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))),
              ]),
            ],
          ),
        ),
        for (final r in rows)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
            child: Row(children: [
              Text(r[0], style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 12),
              Expanded(child: Text(r[1], style: const TextStyle(fontSize: 14, color: AppColors.ink))),
              Text('${r[2]} ›', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
            ]),
          ),
      ],
    );
  }

  Widget _stat(String v, String l) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(children: [
          Text(v, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 3),
          Text(l, style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
        ]),
      ),
    );
  }

  Widget _statDivider() => Container(width: 1, height: 40, color: AppColors.line);
}
