import 'package:flutter/material.dart';

import '../../../core/compliance/disclosures.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/screen_frame.dart';
import '../data/mission_providers.dart';
import '../models/partner_mission.dart';

class PartnerMissionDetailScreen extends StatelessWidget {
  final PartnerMission m;
  final bool done;
  final void Function(PartnerMission) onComplete;
  const PartnerMissionDetailScreen({super.key, required this.m, required this.done, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final dis = Disclosures.of(m.disclosureKey);
    return ScreenFrame(
      title: '제휴 미션',
      subtitle: '제휴 · ${m.brand}',
      onBack: () => Navigator.of(context).pop(),
      child: Stack(children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            Row(children: [
              Container(width: 64, height: 64, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(18)), child: Text(m.icon, style: const TextStyle(fontSize: 32))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('제휴 · ${m.brand}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.purple)),
                    Padding(padding: const EdgeInsets.only(top: 3), child: Text(m.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.3))),
                  ],
                ),
              ),
            ]),
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(16)),
              // 글자 크기를 키운 기기나 좁은 화면에서 두 글자 덩어리가 한 줄에 못 들어간다.
              // 설명 쪽을 먼저 줄이고 포인트 숫자는 끝까지 온전히 보이게 한다.
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Flexible(
                  child: Text('참여하면 받는 포인트',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.white70)),
                ),
                const SizedBox(width: 10),
                Text('+${nf(m.points)}P', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.yellow)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(children: [
                for (final e in [['예상 소요', m.time], ['참여 조건', m.cond], ['추천 이유', m.reason]])
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: e[0] == '추천 이유' ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(13)),
                      child: Column(children: [
                        Text(e[0], style: const TextStyle(fontSize: 11, color: AppColors.sub)),
                        Padding(padding: const EdgeInsets.only(top: 4), child: Text(e[1], textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.3))),
                      ]),
                    ),
                  ),
              ]),
            ),
            const Padding(padding: EdgeInsets.fromLTRB(0, 18, 0, 6), child: Text('미션 안내', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
              child: Text(m.desc, style: const TextStyle(fontSize: 13.5, color: Color(0xFF3A3D42), height: 1.6)),
            ),
            // 무엇으로 '완료'를 인정하고 언제 주는지를 참여 전에 못박는다.
            // (가이드 §3의 방문 인증, §4의 상담 완료 기준 객관화)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                for (final e in [
                  ['✅', '완료 인정', m.verify],
                  ['💵', '지급 시점', m.payout],
                  // 캠페인을 집행하는 곳과 지금 연동 상태. 제휴가 아직이면
                  // 참여 버튼을 누르기 전에 여기서 먼저 보인다.
                  if (m.providerId.isNotEmpty)
                    ['🔗', '공급', '${providerOf(m.providerId).name} · ${providerOf(m.providerId).statusLabel}'],
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e[0], style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      SizedBox(width: 68, child: Text(e[1], style: const TextStyle(fontSize: 12.5, color: AppColors.sub))),
                      Expanded(child: Text(e[2], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.4))),
                    ]),
                  ),
              ]),
            ),

            // 규제 영역별 필수 고지 (§19)
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(bottom: 5), child: Text('⚠️ 참여 전 확인 · ${dis.label}', style: const TextStyle(fontSize: 11.5, color: AppColors.purple, fontWeight: FontWeight.w800))),
                  Text(dis.body, style: const TextStyle(fontSize: 12, color: AppColors.purple, height: 1.6)),
                  if (m.disclosureKey != 'partner')
                    Padding(padding: const EdgeInsets.only(top: 6), child: Text(Disclosures.partner.body, style: const TextStyle(fontSize: 12, color: AppColors.purple, height: 1.6))),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.line))),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: done ? null : () => onComplete(m),
                style: ElevatedButton.styleFrom(
                  backgroundColor: done ? AppColors.greenSoft : AppColors.yellow,
                  foregroundColor: done ? AppColors.green : AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  disabledBackgroundColor: AppColors.greenSoft,
                  disabledForegroundColor: AppColors.green,
                ),
                child: Text(done ? '참여 완료 ✓ · 포인트 적립됨' : '참여하고 +${nf(m.points)}P 받기', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
