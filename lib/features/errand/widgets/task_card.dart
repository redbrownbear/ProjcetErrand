import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/utils/formatters.dart';
import '../data/countries.dart';
import '../models/task_item.dart';

/// 부탁 한 줄 (기획 시안 v9 `TaskTile` / `.task-tile`).
///
/// 시안의 목록은 카드가 아니라 **1px 밑줄로 구분되는 행**이다. 종류 아이콘 타일,
/// 위치·급함 표시, 두 줄 제목, 마감 문구, 그리고 거리·시간과 금액이 맞물린 아래 줄로 이뤄진다.
///
/// - [rich] : 신뢰 지표(별점·거래 수·본인인증) 한 줄을 덧붙인다.
/// - [rank] : 순위 목록에서 앞에 번호를 붙인다.
class TaskCard extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onOpen;
  final bool done;
  final bool rich;
  final int? rank;
  const TaskCard({super.key, required this.it, required this.onOpen, this.done = false, this.rich = false, this.rank});

  @override
  Widget build(BuildContext context) {
    final sea = it.mode == 'sea';
    final paid = it.mode != 'together';

    return InkWell(
      onTap: onOpen,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F1F3))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (rank != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6, top: 14),
                  child: SizedBox(
                    width: 18,
                    child: Text(
                      '$rank',
                      textAlign: TextAlign.center,
                      style: AppType.price.copyWith(fontSize: 15, color: rank! <= 3 ? AppColors.ink : AppColors.faint),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: sea
                    ? Container(
                        width: 49,
                        height: 53,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(AppRadius.emblem)),
                        child: Text(countryOf(it.cc).flag, style: const TextStyle(fontSize: 22)),
                      )
                    : CatEmblem(cat: it.cat, size: 49, iconSize: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 위치 · 내가 올림/예시 · 급함
                    // 배지가 들어가면 17px을 넘을 수 있으므로 높이를 고정하지 않고
                    // 최소 높이만 준다. (시안의 .task-meta { min-height:17px })
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 17),
                      child: Row(children: [
                        Flexible(
                          child: Text(
                            sea ? (it.country ?? '해외') : (it.place ?? it.region ?? ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.meta.copyWith(color: const Color(0xFF73777C)),
                          ),
                        ),
                        // 내가 올린 글인지, 미리 만들어 둔 예시인지 목록에서부터 밝힌다.
                        // (예시는 실제 모집 중인 부탁이 아니고, 내 글에는 지원할 수 없다)
                        if (it.isMine)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(5)),
                              child: Text('내가 올림',
                                  style: AppType.caption.copyWith(fontSize: 11, fontWeight: AppType.w600, color: AppColors.yellowDeep)),
                            ),
                          )
                        else if (it.sample)
                          Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: Text('(예시)', style: AppType.meta.copyWith(color: AppColors.faint)),
                          ),
                        if (it.hot)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text('지금 필요해요',
                                style: AppType.meta.copyWith(color: AppColors.urgent, fontWeight: AppType.w500)),
                          ),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(it.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppType.taskTitle),
                    ),
                    if (it.deadline != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(
                          [
                            it.isExpired ? '마감됨' : deadlineLabel(it),
                            if (it.deliveryPlace != null) '전달: ${it.deliveryPlace}',
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.meta.copyWith(
                            fontSize: 13.5,
                            color: it.isExpired ? AppColors.faint : const Color(0xFF565C63),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 9),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Expanded(
                          child: Text(
                            [
                              sea ? '해외 부탁' : '${distLabel(it)} · ${it.mins > 0 ? it.mins : 10}분',
                              if (done) '지원 완료',
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.meta.copyWith(color: done ? AppColors.green : const Color(0xFF73767B)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(text: paid ? nf(it.price) : '무료'),
                            if (paid)
                              TextSpan(text: '원', style: AppType.price.copyWith(fontSize: 13, fontWeight: AppType.w500)),
                          ]),
                          style: AppType.price,
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ]),
            if (rich)
              Padding(
                padding: const EdgeInsets.only(top: 11, left: 62),
                child: Row(children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: AppType.caption,
                        children: [
                          TextSpan(
                            text: '★ ${it.rating.toStringAsFixed(1)}',
                            style: AppType.caption.copyWith(color: AppColors.ink, fontWeight: AppType.w600),
                          ),
                          TextSpan(text: ' · 거래 ${it.deals}회'),
                          if (it.verified)
                            TextSpan(text: ' · 본인인증', style: AppType.caption.copyWith(color: AppColors.green, fontWeight: AppType.w600)),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('도움 ${it.helpCnt} · 요청 ${it.reqCnt}', style: AppType.caption.copyWith(color: AppColors.faint)),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
