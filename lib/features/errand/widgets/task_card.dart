import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surface.dart';
import '../../../core/utils/formatters.dart';
import '../data/countries.dart';
import '../models/task_item.dart';

/// 부탁 한 줄 (시안 v33 `.row`).
///
/// 카드가 아니라 **1px 밑줄로 구분되는 행**이다. 왼쪽에 종류 아이콘 타일(40px),
/// 가운데 제목과 '장소 · 거리 · 약 N분', 오른쪽에 상태 배지와 금액이 세로로 붙는다.
///
/// - [rich] : 신뢰 지표(별점·거래 수·본인인증) 한 줄을 덧붙인다.
/// - [rank] : 순위 목록에서 앞에 번호를 붙인다.
/// - [last] : 목록의 마지막 행이면 밑줄을 그리지 않는다.
class TaskCard extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onOpen;
  final bool done;
  final bool rich;
  final int? rank;
  final bool last;
  const TaskCard({
    super.key,
    required this.it,
    required this.onOpen,
    this.done = false,
    this.rich = false,
    this.rank,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final sea = it.mode == 'sea';
    final paid = it.mode != 'together';

    // 위치 · 거리 · 시간. 예시 데이터는 목록에서부터 예시라고 밝힌다.
    final meta = [
      if (sea) (it.country ?? '해외') else (it.place ?? it.region ?? ''),
      if (!sea) distLabel(it),
      if (!sea) '약 ${it.mins > 0 ? it.mins : 10}분',
      if (it.sample) '예시',
    ].where((s) => s.isNotEmpty).join(' · ');

    final StatusBadge? badge = done
        ? const StatusBadge.green('지원 완료')
        : it.isMine
        ? const StatusBadge.yellow('내가 올림')
        : it.isExpired
        ? const StatusBadge.gray('마감')
        : it.hot
        ? const StatusBadge.red('급해요')
        : null;

    return InkWell(
      onTap: onOpen,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (rank != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 16,
                      child: Text(
                        '$rank',
                        textAlign: TextAlign.center,
                        style: AppType.price.copyWith(fontSize: 14, color: rank! <= 3 ? AppColors.ink : AppColors.faint),
                      ),
                    ),
                  ),
                sea ? _flag(it.cc) : CatEmblem(cat: it.cat),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.taskTitle),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.meta.copyWith(fontWeight: AppType.w500, color: AppColors.sub, height: 1.6),
                        ),
                      ),
                      if (it.deadline != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            [
                              it.isExpired ? '마감됨' : deadlineLabel(it),
                              if (it.deliveryPlace != null) '전달: ${it.deliveryPlace}',
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.caption.copyWith(color: it.isExpired ? AppColors.faint : AppColors.ink2),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (badge != null) Padding(padding: const EdgeInsets.only(bottom: 3), child: badge),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: paid ? nf(it.price) : '무료'),
                          if (paid)
                            const TextSpan(
                              text: '원',
                              style: TextStyle(fontSize: 13, fontWeight: AppType.w600, color: AppColors.ink2),
                            ),
                        ],
                      ),
                      style: AppType.price,
                    ),
                  ],
                ),
              ],
            ),
            if (rich)
              Padding(
                padding: EdgeInsets.only(top: 8, left: rank != null ? 78 : 54),
                child: Row(
                  children: [
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
                              TextSpan(
                                text: ' · 본인인증',
                                style: AppType.caption.copyWith(color: AppColors.green, fontWeight: AppType.w600),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('도움 ${it.helpCnt} · 요청 ${it.reqCnt}', style: AppType.caption.copyWith(color: AppColors.faint)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 해외 부탁은 국가 코드 타일
  static Widget _flag(String? cc) => CountryFlag(cc: cc);
}

/// 해외 부탁의 장소 한 줄. 예시 데이터의 `country`에는 국기와 도시까지 들어 있어서
/// (`🇯일본 도쿄`) 도시를 또 붙이면 '도쿄 도쿄'가 된다. 이미 들어 있으면 붙이지 않는다.
String seaPlace(TaskItem it) {
  final country = it.country ?? countryOf(it.cc).name;
  final city = it.city ?? '';
  return city.isEmpty || country.contains(city) ? country : '$country $city';
}

/// 국가 코드 타일. 나라마다 v33의 포인트 색을 돌려 쓴다.
class CountryFlag extends StatelessWidget {
  final String? cc;
  final double size;
  final double radius;
  const CountryFlag({super.key, required this.cc, this.size = 40, this.radius = 12});

  static const _tones = [
    (AppColors.redSoft, AppColors.red),
    (AppColors.blueSoft, AppColors.blue),
    (AppColors.purpleSoft, AppColors.purple),
    (AppColors.greenSoft, AppColors.green),
    (AppColors.yellowSoft, AppColors.yellowInk),
  ];

  static (Color, Color) toneOf(String? cc) {
    const fixed = {'jp': 0, 'us': 1, 'gb': 2, 'uk': 2, 'vn': 3, 'tw': 4};
    final k = (cc ?? '').toLowerCase();
    return _tones[fixed[k] ?? (k.hashCode.abs() % _tones.length)];
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = toneOf(cc);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
      child: Text(
        (cc ?? '··').toUpperCase(),
        style: TextStyle(fontSize: size * 0.3, fontWeight: AppType.w700, color: fg, letterSpacing: 0.4),
      ),
    );
  }
}
