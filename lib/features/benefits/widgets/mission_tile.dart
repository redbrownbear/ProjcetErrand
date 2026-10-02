import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/surface.dart';
import '../models/mission_meta.dart';
import '../models/partner_mission.dart';

/// 미션 목록의 한 줄 (시안 v33 `.row.mission-clean`).
///
/// 종류·소요시간 / 제목 / 참여 조건과 비용 / 보상 순으로 읽힌다.
/// **비용이 드는 미션인지**([MissionMeta.costTag])를 조건 옆에 같이 두는 게 핵심이다.
class MissionTile extends StatelessWidget {
  final PartnerMission m;
  final bool done;
  final bool active;
  final VoidCallback onTap;
  final bool last;

  const MissionTile({super.key, required this.m, required this.done, required this.active, required this.onTap, this.last = false});

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

  /// 종류별 아이콘 (시안 `MIS[].ic`)
  static const _catIcons = {
    'survey': 'pencil',
    'signup': 'check',
    'visit': 'store',
    'shopping': 'bag',
    'experience': 'phone',
    'blog': 'pencil',
    'research': 'laptop',
    'consult': 'chat',
  };

  @override
  Widget build(BuildContext context) {
    final cat = _catLabels[m.cat] ?? '미션';

    return Opacity(
      opacity: done ? 0.55 : 1,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.line))),
          child: Row(children: [
            IconTile(icon: _catIcons[m.cat] ?? 'sparkles'),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (active || done)
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: done ? AppColors.page : AppColors.blueSoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(done ? '적립 완료' : '참여 중',
                            style: AppType.caption.copyWith(fontSize: 10, fontWeight: AppType.w700, color: done ? AppColors.sub : AppColors.blue)),
                      ),
                    ),
                  Flexible(
                    child: Text('$cat · ${m.time}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.caption.copyWith(fontSize: 10, fontWeight: AppType.w600, color: const Color(0xFF92969D))),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.taskTitle),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${m.cond} · ${m.costTag}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.meta.copyWith(fontWeight: AppType.w500)),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: '+${nf(m.points)}'),
                const TextSpan(text: 'P', style: TextStyle(fontSize: 13, color: AppColors.ink2, fontWeight: AppType.w600)),
              ]),
              style: AppType.price,
            ),
          ]),
        ),
      ),
    );
  }
}
