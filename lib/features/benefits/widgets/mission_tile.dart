import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_icon.dart';
import '../models/mission_meta.dart';
import '../models/partner_mission.dart';

/// 부업 목록의 미션 한 줄. 시안(`gyumsa-refined`)의 `.mission-v8`.
///
/// 종류·소요시간 / 제목 / 참여 조건과 비용 / 보상 순으로 읽힌다.
/// **비용이 드는 미션인지**([MissionMeta.costTag])를 조건 옆에 같이 두는 게 핵심이다.
class MissionTile extends StatelessWidget {
  final PartnerMission m;
  final bool done;
  final bool active;
  final VoidCallback onTap;

  const MissionTile({super.key, required this.m, required this.done, required this.active, required this.onTap});

  static const _catLabels = {
    'survey': '설문조사',
    'signup': '가입',
    'visit': '방문',
    'shopping': '쇼핑',
    'experience': '앱·체험',
    'blog': '블로그·SNS',
    'research': '연구',
    'consult': '상담',
  };

  /// 종류마다 아이콘 타일 색을 돌려 쓴다. (시안의 `.mission-icon-v8:nth-of-type`)
  static const _tints = [
    (bg: Color(0xFFEAF4EC), fg: Color(0xFF6A9D7B)),
    (bg: Color(0xFFF8EDDC), fg: Color(0xFFBC9861)),
    (bg: Color(0xFFECEDFA), fg: Color(0xFF9E8CBE)),
  ];

  @override
  Widget build(BuildContext context) {
    final tint = _tints[m.id.hashCode.abs() % _tints.length];
    final cat = _catLabels[m.cat] ?? '미션';

    return Opacity(
      opacity: done ? 0.6 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5.5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.card)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: tint.bg, borderRadius: BorderRadius.circular(AppRadius.tile)),
              child: Text(m.icon, style: const TextStyle(fontSize: 19)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text('$cat · ${m.time}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.caption.copyWith(fontSize: 11, color: const Color(0xFF9AABA2))),
                  ),
                  if (active) ...[
                    const SizedBox(width: 6),
                    _badge('참여 중', AppColors.goalMintBg, AppColors.goalMintInk),
                  ],
                  if (done) ...[
                    const SizedBox(width: 6),
                    _badge('적립 완료', AppColors.page, AppColors.sub),
                  ],
                ]),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(m.title,
                      style: AppType.body.copyWith(fontSize: 14, height: 1.5, fontWeight: AppType.w600, color: AppColors.inkSoft)),
                ),
                Text('${m.cond} · ${m.costTag}',
                    style: AppType.caption.copyWith(fontSize: 11, color: const Color(0xFF8E9992))),
              ]),
            ),
            const SizedBox(width: 10),
            if (done)
              const AppIcon('check', size: 20, color: AppColors.goalMintInk)
            else
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: const Color(0xFFFFF7DF), borderRadius: BorderRadius.circular(10)),
                child: Text('+${nf(m.points)}P',
                    style: AppType.body.copyWith(fontSize: 12, fontWeight: AppType.w700, color: const Color(0xFFD49D27))),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _badge(String label, Color bg, Color ink) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: AppType.caption.copyWith(fontSize: 10, color: ink)),
      );
}
