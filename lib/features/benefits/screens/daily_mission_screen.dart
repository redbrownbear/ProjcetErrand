import 'package:flutter/material.dart';

import '../../../core/compliance/disclosures.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/screen_frame.dart';
import '../data/mission_providers.dart';
import '../services/mission_engine.dart';
import '../services/mission_runner.dart';
import '../widgets/daily_mission_row.dart';

/// '가볍게 모으기' 전체 화면.
///
/// 홈에는 지금 바로 되는 것 몇 개만 올리고, 나머지는 여기에 전부 편다.
/// 목록을 '오늘 다시 되는 것 / 한 번만 받는 것'으로 가르는 이유는,
/// 매일 들어와서 할 일과 계정을 만들 때 한 번 하는 일이 섞이면
/// 다 끝낸 사용자에게 화면이 계속 미완성으로 보이기 때문이다.
class DailyMissionScreen extends StatefulWidget {
  final MissionRunner runner;

  /// 적립 여부 판정 — 셸의 적립 원장을 그대로 읽는다
  final MissionEngine engine;

  /// 제휴 캠페인(설문·방문·상담)으로 넘어가기
  final VoidCallback goEarnHub;

  const DailyMissionScreen({
    super.key,
    required this.runner,
    required this.engine,
    required this.goEarnHub,
  });

  @override
  State<DailyMissionScreen> createState() => _DailyMissionScreenState();
}

class _DailyMissionScreenState extends State<DailyMissionScreen> {
  /// 미션을 실행하면 적립 원장이 바뀐다. 셸이 다시 그려 주기를 기다리지 않고
  /// 이 화면이 직접 다시 읽는다 — [MissionEngine]이 콜백으로 원장을 보기 때문에
  /// setState 한 번이면 최신 상태가 된다.
  Future<void> _tap(MissionState s) async {
    await widget.runner.run(context, s);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.engine.all();
    final daily = all.where((s) => s.m.daily).toList();
    final once = all.where((s) => !s.m.daily).toList();
    final (doneCount, openCount) = widget.engine.todayProgress;

    return ScreenFrame(
      title: '가볍게 모으기',
      subtitle: '오늘 몇 분이면 되는 것들',
      onBack: () => Navigator.of(context).pop(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          _summary(doneCount, openCount),
          const SizedBox(height: 16),
          // 재원이 있는 미션만 두다 보니 한쪽이 통째로 빌 수 있다.
          // 제목만 남은 빈 구역은 고장으로 보이므로 아예 그리지 않는다.
          if (daily.isNotEmpty) ...[
            _sectionTitle('오늘 할 수 있는 것', '자정에 다시 열려요'),
            for (final s in daily) DailyMissionRow(s: s, onTap: () => _tap(s)),
            const SizedBox(height: 14),
          ],
          if (once.isNotEmpty) ...[
            _sectionTitle('한 번만 받는 것', '계정당 1회'),
            for (final s in once) DailyMissionRow(s: s, onTap: () => _tap(s)),
            const SizedBox(height: 14),
          ],
          _partnerLink(),
          const SizedBox(height: 12),
          _sources(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(AppRadius.tile)),
            child: Text(Disclosures.partner.body,
                style: AppType.caption.copyWith(color: AppColors.purple, height: 1.6)),
          ),
        ],
      ),
    );
  }

  Widget _summary(int done, int open) {
    final remain = widget.engine.remainToday;
    // 제휴가 하나도 안 붙은 빌드에서는 열 수 있는 미션이 0개다.
    // 그때 '+0P 남았어요 · 0/0개 완료'는 틀린 말이라 문구를 바꾼다.
    final nothingOpen = open == 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nothingOpen ? '미션 준비 중' : '오늘 남은 포인트',
                  style: AppType.caption.copyWith(color: Colors.white60)),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(nothingOpen ? '곧 열려요' : '+${nf(remain)}P',
                    style: AppType.section.copyWith(fontSize: 28, color: AppColors.yellow)),
              ),
            ]),
          ),
          const Text('🪙', style: TextStyle(fontSize: 34)),
        ]),
        if (!nothingOpen) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: done / open,
              minHeight: 6,
              backgroundColor: AppColors.onDarkFill,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Text(
            nothingOpen
                ? '제휴 연동이 끝나는 대로 여기에 올라와요'
                : '오늘 $done / $open개 완료 · 금액이 정해진 미션만 합산해요',
            style: AppType.caption.copyWith(color: AppColors.onDarkSub),
          ),
        ),
      ]),
    );
  }

  Widget _sectionTitle(String title, String hint) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(child: Text(title, style: AppType.sectionSmall)),
          Text(hint, style: AppType.caption),
        ]),
      );

  /// 오래 걸리지만 크게 받는 것은 제휴 미션 쪽에 있다. 여기서 길을 열어 준다.
  Widget _partnerLink() => InkWell(
        onTap: widget.goEarnHub,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(AppRadius.tile)),
          child: Row(children: [
            const Text('📝', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('더 크게 버는 참여·리워드',
                    style: AppType.meta.copyWith(fontSize: 14.5, fontWeight: AppType.w600, color: AppColors.ink)),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('설문 · 좌담회 · 현장 점검 — 시간은 더 들지만 단가가 커요',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppType.caption.copyWith(color: AppColors.yellowDeep)),
                ),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.yellowDeep),
          ]),
        ),
      );

  /// 포인트 재원 공개. 어디서 온 돈인지 보이면 '왜 공짜로 주지?'라는 의심이 줄고,
  /// 개발 중에는 어떤 제휴가 아직 안 붙었는지 한눈에 확인된다.
  Widget _sources() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('이 포인트는 어디서 오나요?', style: AppType.meta.copyWith(fontWeight: AppType.w600, color: AppColors.ink)),
        const SizedBox(height: 8),
        for (final p in missionProviders)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 5, right: 8),
                decoration: BoxDecoration(
                  color: p.usable ? AppColors.green : AppColors.faint,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text('${p.name} · ${p.kindLabel}\n${p.settle}',
                    style: AppType.caption.copyWith(height: 1.5)),
              ),
              Text(p.statusLabel,
                  style: AppType.caption.copyWith(
                      fontSize: 10.5, color: p.usable ? AppColors.green : AppColors.faint)),
            ]),
          ),
      ]),
    );
  }
}
