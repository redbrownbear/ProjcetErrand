import 'package:flutter/material.dart';

import '../../../core/compliance/disclosures.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../dayjob/data/day_jobs.dart';
import '../../dayjob/models/day_job.dart';
import '../../dayjob/screens/day_job_screen.dart';
import '../../earn/models/earn_track.dart';
import '../data/partner_missions.dart';
import '../models/partner_mission.dart';
import '../widgets/earn_row_full.dart';
import 'partner_mission_detail_screen.dart';

/// 1차 메뉴 '오늘 벌기' 허브. (가이드 §6·§15)
///
/// 제휴가 늘어날수록 홈에 카테고리를 하나씩 더 붙이면 앱이 산만해진다.
/// 그래서 심부름 / 참여·리워드 / 단기알바 / 간단 미션 네 개의 2차 메뉴만 두고,
/// 새로 붙는 제휴(모델하우스·임상·연구·행사 스태프…)는 전부 이 아래로 넣는다.
class EarnHubScreen extends StatefulWidget {
  final List<String> doneMissions;
  final void Function(PartnerMission) completeMission;

  /// 심부름 목록으로 보내기 (돈벌기 리스트 화면)
  final VoidCallback onOpenErrand;

  /// 단기알바 지원 (현재는 안내 토스트)
  final void Function(DayJob) onApplyDayJob;

  const EarnHubScreen({
    super.key,
    required this.doneMissions,
    required this.completeMission,
    required this.onOpenErrand,
    required this.onApplyDayJob,
  });
  @override
  State<EarnHubScreen> createState() => _EarnHubScreenState();
}

class _EarnHubScreenState extends State<EarnHubScreen> {
  /// 2차 메뉴 (§15)
  String menu = EarnTrack.reward.key;

  /// 미션 목록 안의 3차 필터
  String cat = 'all';

  @override
  Widget build(BuildContext context) {
    final potential = partnerMissions.fold<int>(0, (s, m) => s + (widget.doneMissions.contains(m.id) ? 0 : m.points));
    final topPay = dayJobs.fold<int>(0, (s, j) => j.pay > s ? j.pay : s);

    return ScreenFrame(
      title: EarnTrack.title,
      subtitle: EarnTrack.sub,
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
                  const Text('지금 참여하면 받을 수 있는 포인트', style: TextStyle(fontSize: 12.5, color: Colors.white60)),
                  Padding(padding: const EdgeInsets.only(top: 4), child: Text('+${nf(potential)}P', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.yellow))),
                  Padding(padding: const EdgeInsets.only(top: 4), child: Text('단기알바은 최대 ${won(topPay)}', style: const TextStyle(fontSize: 11.5, color: Colors.white54))),
                ],
              ),
              const Text('💰', style: TextStyle(fontSize: 34)),
            ]),
          ),

          // 2차 메뉴 — 여기 네 개가 '오늘 벌기'의 전부다
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final m in EarnTrack.menus)
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChipWidget(
                        label: '${m.icon} ${m.label}',
                        active: menu == m.key,
                        onTap: () => setState(() {
                          menu = m.key;
                          cat = 'all';
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_menu.includes, style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
          ),

          ..._section(),
        ],
      ),
    );
  }

  TrackMenu get _menu => EarnTrack.menus.firstWhere((m) => m.key == menu);

  List<Widget> _section() {
    switch (menu) {
      case 'errand':
        return _errandSection();
      case 'dayjob':
        return _dayJobSection();
      default:
        return _missionSection(menu);
    }
  }

  /// 심부름 — 지역 픽업과 기업 심부름. 목록 화면이 이미 있어 그쪽으로 넘긴다.
  List<Widget> _errandSection() => [
        InkWell(
          onTap: widget.onOpenErrand,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Text('🤝', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('근처 심부름 보러 가기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    Padding(padding: EdgeInsets.only(top: 2), child: Text('제휴 매장 예약 픽업 · 개인 부탁 · 기업 심부름', style: TextStyle(fontSize: 11.5, color: AppColors.yellowDeep))),
                  ],
                ),
              ),
              const Text('›', style: TextStyle(fontSize: 20, color: AppColors.yellowDeep)),
            ]),
          ),
        ),
        // 기업 심부름은 개인 심부름과 같은 줄에 열지 않는다 (§7)
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🏢 기업 심부름 (준비 중)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
              Padding(padding: const EdgeInsets.only(top: 6), child: Text(Disclosures.b2b.body, style: const TextStyle(fontSize: 12, color: AppColors.sub, height: 1.6))),
            ],
          ),
        ),
      ];

  /// 단기알바 — 공연·행사·전시·단기알바를 한 카테고리로 묶었다 (§6)
  List<Widget> _dayJobSection() {
    final top = List.of(dayJobs)..sort((a, b) => b.pay - a.pay);
    return [
      for (final j in top.take(3))
        InkWell(
          onTap: _openDayJobs,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(13)), child: Text(j.icon, style: const TextStyle(fontSize: 24))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${j.cat} · ${j.org}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.blue)),
                    Padding(padding: const EdgeInsets.only(top: 1), child: Text(j.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink))),
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text('${j.hours} · ${j.payDate}', style: const TextStyle(fontSize: 11.5, color: AppColors.sub))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(won(j.pay), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  Padding(padding: const EdgeInsets.only(top: 2), child: Text(j.payKind, style: const TextStyle(fontSize: 11, color: AppColors.sub))),
                ],
              ),
            ]),
          ),
        ),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _openDayJobs,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.line),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('단기알바 전체 보기 ›', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        ),
      ),
      Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(12)),
        child: Text(Disclosures.labor.body, style: const TextStyle(fontSize: 11.5, color: AppColors.blue, height: 1.6)),
      ),
    ];
  }

  /// 참여·리워드 / 간단 미션
  List<Widget> _missionSection(String group) {
    final list = List.of(missionsByGroup(group, cat: cat))..sort((a, b) => b.points - a.points);
    final cats = [
      missionCats.first,
      for (final c in missionCats.skip(1))
        if (missionsByGroup(group, cat: c[0]).isNotEmpty) c,
    ];
    return [
      if (cats.length > 2)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in cats)
                  Padding(padding: const EdgeInsets.only(right: 7), child: ChipWidget(label: c[1], active: cat == c[0], onTap: () => setState(() => cat = c[0]))),
              ],
            ),
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text.rich(TextSpan(children: [
          const TextSpan(text: '포인트 높은 순 ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
          TextSpan(text: '· ${list.length}건', style: const TextStyle(fontSize: 11.5, color: AppColors.sub, fontWeight: FontWeight.w600)),
        ])),
      ),
      for (final m in list)
        EarnRowFull(
          m: m,
          done: widget.doneMissions.contains(m.id),
          onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PartnerMissionDetailScreen(
            m: m, done: widget.doneMissions.contains(m.id), onComplete: widget.completeMission,
          ))),
        ),
      Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(12)),
        child: Text(Disclosures.partner.body, style: const TextStyle(fontSize: 11.5, color: AppColors.purple, height: 1.6)),
      ),
    ];
  }

  void _openDayJobs() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DayJobScreen(onApply: widget.onApplyDayJob)),
      );
}
