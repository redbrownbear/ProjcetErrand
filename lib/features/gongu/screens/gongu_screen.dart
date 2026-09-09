import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../benefits/models/reward_ledger.dart';
import '../repositories/gongu_repository.dart';
import 'gongu_detail_screen.dart';

class GonguScreen extends StatelessWidget {
  final EarnFn earn;
  final IsClaimedFn isClaimed;
  const GonguScreen({super.key, required this.earn, required this.isClaimed});

  @override
  Widget build(BuildContext context) {
    final gonguItems = LocalGonguRepository().fetchItems();
    return ScreenFrame(
      title: '공동구매',
      subtitle: '같이 사고 벌기 · 판매 성과가 곧 부수입',
      onBack: () => Navigator.of(context).pop(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('공구를 만들고, 사람을 모으면', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                Padding(padding: const EdgeInsets.only(top: 4), child: Text('판매 성과의 일부가 내 부수입이 돼요', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.yellow))),
                const Padding(padding: EdgeInsets.only(top: 6), child: Text('싸게 사는 데서 끝이 아니라 — 모집 인원이 늘수록 보상이 커집니다.', style: TextStyle(fontSize: 11.5, color: Colors.white60))),
              ],
            ),
          ),
          const SizedBox(height: 4),
          for (final g in gonguItems)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GonguDetailScreen(g: g, earn: earn, isClaimed: isClaimed))),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 66, height: 66, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(14)), child: Text(g.icon, style: const TextStyle(fontSize: 32))),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('공동구매 · ${g.brand}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.purple)),
                          Padding(padding: const EdgeInsets.only(top: 2), child: Text(g.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink))),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text.rich(TextSpan(children: [
                              TextSpan(text: '${nf(g.price)}원', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                              TextSpan(text: '  ${nf(g.list)}원', style: const TextStyle(fontSize: 12, color: AppColors.faint, decoration: TextDecoration.lineThrough)),
                            ])),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(value: (g.joined / g.target).clamp(0, 1).toDouble(), minHeight: 6, backgroundColor: AppColors.line, color: AppColors.green),
                            ),
                          ),
                          Padding(padding: const EdgeInsets.only(top: 4), child: Text('${g.joined}/${g.target}명 모집 · 성과보상 최대 +5,000원', style: const TextStyle(fontSize: 11, color: AppColors.sub))),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
