import 'package:flutter/material.dart';

import '../models/partner_mission.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
import '../widgets/screen_frame.dart';

class PartnerMissionDetailScreen extends StatelessWidget {
  final PartnerMission m;
  final bool done;
  final VoidCallback onClose;
  final void Function(PartnerMission) onComplete;
  const PartnerMissionDetailScreen({super.key, required this.m, required this.done, required this.onClose, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: '제휴 미션',
      subtitle: '제휴 · ${m.brand}',
      onBack: onClose,
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
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('참여하면 받는 포인트', style: TextStyle(fontSize: 13, color: Colors.white70)),
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
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.only(bottom: 5), child: Text('⚠️ 참여 전 확인', style: TextStyle(fontSize: 11.5, color: AppColors.sub, fontWeight: FontWeight.w700))),
                  const Text('제휴사 정책에 따라 지급 조건·시점이 달라질 수 있어요. 조건을 충족하면 포인트가 자동 적립됩니다.', style: TextStyle(fontSize: 12, color: AppColors.sub, height: 1.6)),
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
