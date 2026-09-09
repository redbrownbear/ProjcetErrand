import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../benefits/models/reward_ledger.dart';
import '../models/gongu.dart';

class GonguDetailScreen extends StatefulWidget {
  final Gongu g;
  final EarnFn earn;
  final IsClaimedFn isClaimed;
  const GonguDetailScreen({super.key, required this.g, required this.earn, required this.isClaimed});
  @override
  State<GonguDetailScreen> createState() => _GonguDetailScreenState();
}

class _GonguDetailScreenState extends State<GonguDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final g = widget.g;
    // 공구당 1회성 보상. 화면을 나갔다 다시 들어와도 중복 지급되지 않는다.
    final made = widget.isClaimed('gongu:${g.id}:make', daily: false);
    final shared = widget.isClaimed('gongu:${g.id}:refer', daily: false);
    return ScreenFrame(
      title: '공동구매 상세',
      subtitle: '공동구매 · ${g.brand}',
      onBack: () => Navigator.of(context).pop(),
      child: Stack(children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(width: 72, height: 72, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(18)), child: Text(g.icon, style: const TextStyle(fontSize: 36))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('공동구매 · ${g.brand}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.purple)),
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text(g.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink))),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: '${nf(g.price)}원', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        TextSpan(text: '  ${nf(g.list)}원', style: const TextStyle(fontSize: 13, color: AppColors.faint, decoration: TextDecoration.lineThrough)),
                      ])),
                    ),
                  ],
                ),
              ),
            ]),
            const Padding(padding: EdgeInsets.fromLTRB(0, 18, 0, 6), child: Text('모집할수록 커지는 성과보상', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink))),
            for (int i = 0; i < g.steps.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(11)), child: Text('${g.steps[i].n}명', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.yellowDeep))),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${g.steps[i].n}명 구매 완료', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink))),
                  Text(g.steps[i].label, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: i == 0 ? AppColors.sub : AppColors.green)),
                ]),
              ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(12)),
              child: const Text('내가 만든 판매 성과가 곧 내 부수입이 됩니다.', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.yellowDeep)),
            ),
            const Padding(padding: EdgeInsets.fromLTRB(0, 18, 0, 6), child: Text('공구를 안 만들어도 — 추천하고 벌기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(11)), child: const Text('🔗', style: TextStyle(fontSize: 20))),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('내 추천 링크로 친구가 같이 구매하면', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: AppColors.sub), children: const [
                            TextSpan(text: '친구 1명 구매마다 '),
                            TextSpan(text: '+1,000원', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w800)),
                            TextSpan(text: ' · 3명 이상이면 '),
                            TextSpan(text: '+5,000원', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w800)),
                          ])),
                        ),
                      ],
                    ),
                  ),
                ]),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(children: [
                    for (final e in const [['친구 1명', '+1,000원'], ['3명', '+5,000원'], ['5명', '+10,000원']])
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: e[0] == '5명' ? 0 : 6),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(10)),
                          child: Column(children: [
                            Text(e[0], style: const TextStyle(fontSize: 11, color: AppColors.sub, fontWeight: FontWeight.w700)),
                            Padding(padding: const EdgeInsets.only(top: 2), child: Text(e[1], style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.blue))),
                          ]),
                        ),
                      ),
                  ]),
                ),
              ]),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)),
              child: const Text('보상 금액은 예시이며 브랜드·캠페인에 따라 달라질 수 있어요. 성과는 실제 구매 완료 기준으로 정산됩니다.', style: TextStyle(fontSize: 11.5, color: AppColors.sub, height: 1.6)),
            ),
          ],
        ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.line))),
            child: Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: made
                      ? null
                      : () async {
                          await widget.earn(500, '공구 성과 보상', key: 'gongu:${g.id}:make', daily: false);
                          if (mounted) setState(() {});
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: made ? AppColors.greenSoft : AppColors.ink,
                    foregroundColor: made ? AppColors.green : Colors.white,
                    disabledBackgroundColor: AppColors.greenSoft,
                    disabledForegroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(made ? '공구 개설됨 ✓' : '공구 만들기', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: shared
                      ? null
                      : () async {
                          await widget.earn(1000, '공구 추천 보상', key: 'gongu:${g.id}:refer', daily: false);
                          if (mounted) setState(() {});
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    backgroundColor: shared ? AppColors.blueSoft : AppColors.card,
                    disabledForegroundColor: AppColors.blue,
                    disabledBackgroundColor: AppColors.blueSoft,
                    side: const BorderSide(color: AppColors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(shared ? '링크 공유됨 ✓' : '추천 링크 공유', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow, foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('바로 참여', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
