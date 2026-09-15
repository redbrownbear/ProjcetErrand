import 'package:flutter/material.dart';

import '../../../core/compliance/disclosures.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../benefits/models/reward_ledger.dart';
import '../../earn/models/earn_track.dart';
import '../../gongu/screens/gongu_screen.dart';
import '../data/member_deals.dart';
import '../models/member_deal.dart';

/// 1차 메뉴 '생활비 아끼기' 허브. (가이드 §10·§15)
///
/// 2차 메뉴는 겸사특가 / 생활서비스 / 금융 혜택 세 개로 고정하고,
/// 지역업체·프랜차이즈·공동구매 같은 제휴 유형은 전부 그 아래로 넣는다.
class SaveHubScreen extends StatefulWidget {
  final EarnFn earn;
  final IsClaimedFn isClaimed;
  final void Function(MemberDeal) onUse;
  const SaveHubScreen({super.key, required this.earn, required this.isClaimed, required this.onUse});
  @override
  State<SaveHubScreen> createState() => _SaveHubScreenState();
}

class _SaveHubScreenState extends State<SaveHubScreen> {
  String menu = 'all';

  @override
  Widget build(BuildContext context) {
    final list = dealsByMenu(menu);
    final maxSave = memberDeals.fold<int>(0, (s, d) => s + d.save);

    return ScreenFrame(
      title: SaveTrack.title,
      subtitle: SaveTrack.sub,
      onBack: () => Navigator.of(context).pop(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('지금 열린 회원 전용가로', style: TextStyle(fontSize: 12.5, color: Colors.white60)),
                  Padding(padding: const EdgeInsets.only(top: 4), child: Text('${won(maxSave)} 아낄 수 있어요', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.yellow))),
                ],
              ),
              const Text('🏷️', style: TextStyle(fontSize: 34)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(padding: const EdgeInsets.only(right: 7), child: ChipWidget(label: '전체', active: menu == 'all', onTap: () => setState(() => menu = 'all'))),
                  for (final m in SaveTrack.menus)
                    Padding(padding: const EdgeInsets.only(right: 7), child: ChipWidget(label: '${m.icon} ${m.label}', active: menu == m.key, onTap: () => setState(() => menu = m.key))),
                ],
              ),
            ),
          ),

          // 공동구매는 겸사특가의 한 갈래라 여기서 이어간다 (§9·§15)
          if (menu == 'all' || menu == 'deal')
            InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GonguScreen(earn: widget.earn, isClaimed: widget.isClaimed))),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Text('🛍️', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('공동구매로 더 싸게', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        Padding(padding: EdgeInsets.only(top: 2), child: Text('주문을 모아 도매 단가를 만들어요 · 픽업으로 배송비도 절약', style: TextStyle(fontSize: 11.5, color: AppColors.yellowDeep))),
                      ],
                    ),
                  ),
                  const Text('›', style: TextStyle(fontSize: 20, color: AppColors.yellowDeep)),
                ]),
              ),
            ),

          for (final d in list) _DealCard(d: d, onUse: () => widget.onUse(d)),

          // §10: '최저가' 대신 기준가를 투명하게 — 화면 하단에 원칙을 명시한다
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)),
            child: Text(Disclosures.pricing.body, style: const TextStyle(fontSize: 11.5, color: AppColors.sub, height: 1.6)),
          ),
        ],
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final MemberDeal d;
  final VoidCallback onUse;
  const _DealCard({required this.d, required this.onUse});

  @override
  Widget build(BuildContext context) {
    final dis = Disclosures.of(d.disclosureKey);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 52, height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(13)), child: Text(d.icon, style: const TextStyle(fontSize: 26))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${d.kind} · ${d.brand}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.yellowDeep)),
                  Padding(padding: const EdgeInsets.only(top: 1), child: Text(d.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink))),
                  if (d.isPriced)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: '회원가 ${nf(d.memberPrice)}원', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        TextSpan(text: '  ${nf(d.basePrice)}원', style: const TextStyle(fontSize: 12, color: AppColors.faint, decoration: TextDecoration.lineThrough)),
                      ])),
                    )
                  else
                    const Padding(padding: EdgeInsets.only(top: 4), child: Text('제휴사 승인 프로모션', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink))),
                  // 기준가를 쓴 근거를 반드시 함께 적는다 (§10)
                  if (d.isPriced)
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text('비교 기준: ${d.baseSource} · ${d.percent}% 절약', style: const TextStyle(fontSize: 11, color: AppColors.sub))),
                ],
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('이 가격이 가능한 이유 — ${d.howMade}', style: const TextStyle(fontSize: 11.5, color: AppColors.ink, height: 1.5)),
                  Padding(padding: const EdgeInsets.only(top: 4), child: Text('${d.area} · ${d.cond}', style: const TextStyle(fontSize: 11.5, color: AppColors.sub, height: 1.5))),
                  if (d.disclosureKey != 'pricing')
                    Padding(padding: const EdgeInsets.only(top: 6), child: Text('⚠️ ${dis.label} — ${dis.body}', style: const TextStyle(fontSize: 11, color: AppColors.purple, height: 1.6))),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow, foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: Text(d.isPriced ? '회원가로 받기' : '프로모션 보기', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
