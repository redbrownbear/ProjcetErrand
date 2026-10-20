import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../core/theme/colors.dart';
import '../../errand/models/task_item.dart';
import '../../errand/screens/map/map_canvas.dart';
import '../../errand/screens/map/map_centers.dart';
import '../data/trip_seeds.dart';

/// 가는 김에(시안 v78 '어! 나도!') 화면들이 같이 쓰는 조각 — 시각 표기, 일정 목록, 지도, 일정 한 줄.

/// 받을 수 있는 부탁 종류
const tripKinds = ['사다주기', '물건 전달', '줄서기·예약', '사진·재고 확인'];

/// 부탁 비용 추천 — 물건값 1만 원 미만 1,500원 · 5만 원 미만 3,000원 · 그 이상 5,000원
int recommendedFee(int itemPrice) => itemPrice < 10000 ? 1500 : (itemPrice < 50000 ? 3000 : 5000);

/// 건당 물건값 상한 (서버 LIMITS.maxGoingItemPrice와 같다)
const tripMaxItemPrice = 50000;

/// 주류·담배·의약품은 부탁할 수 없다 (서버 BLOCKED_ITEMS와 같은 목록)
final tripBlocked = RegExp(r'(술|소주|맥주|와인|막걸리|양주|주류|담배|전자담배|처방|마약|수면제|의약품)');

DateTime _day0(DateTime d) => DateTime(d.year, d.month, d.day);

/// '오늘' · '내일' · '모레' · '10/23'
String tripDay(DateTime at, [DateTime? now]) {
  final diff = _day0(at).difference(_day0(now ?? DateTime.now())).inDays;
  return switch (diff) {
    0 => '오늘',
    1 => '내일',
    2 => '모레',
    _ => '${at.month}/${at.day}',
  };
}

/// '오후 8시' · '오전 10시 30분'
String tripTime(DateTime at) {
  final h = at.hour, m = at.minute;
  return '${h < 12 ? '오전' : '오후'} ${h % 12 == 0 ? 12 : h % 12}시${m > 0 ? ' $m분' : ''}';
}

/// 지도 핀 글자 — '8시' · '내일 10시'
String tripShort(DateTime at, [DateTime? now]) {
  final d = tripDay(at, now);
  final h = at.hour % 12 == 0 ? 12 : at.hour % 12;
  return '${d == '오늘' ? '' : '$d '}$h시${at.minute > 0 ? ' ${at.minute}분' : ''}';
}

DateTime tripAt(TaskItem t) => t.goAt ?? t.deadline ?? DateTime.now();

/// 지금 보이는 가는 김에 일정 — 실제(서버·내 글)를 먼저, 예시는 뒤에. 끝난 일정은 뺀다.
/// [mine]이 true면 내 일정만, false면 남의 일정만.
List<TaskItem> tripList(AppNav nav, {bool? mine}) {
  final now = DateTime.now();
  final real = nav.items().where((i) => i.isGoing && !i.isExpiredAt(now) && !i.sample).toList();
  final ids = {for (final i in real) i.id};
  final all = [...real, ...tripSeeds(now).where((s) => !ids.contains(s.id) && !s.isExpiredAt(now))];
  final out = mine == null ? all : all.where((t) => t.isMine == mine).toList();
  out.sort((a, b) => tripAt(a).compareTo(tripAt(b)));
  return out;
}

/// 가는 김에 지도. 지도에 콕 찍은 일정만 핀으로 뜬다(가짜 위치에 찍지 않는다).
class TripMap extends StatelessWidget {
  final List<TaskItem> trips;
  final String scope;
  final double height;
  final void Function(TaskItem) onOpen;

  /// 등록 화면에서 지도를 눌러 위치를 고를 때
  final void Function(double lat, double lng)? onPick;
  final (double, double)? picked;

  const TripMap({
    super.key,
    required this.trips,
    required this.scope,
    required this.onOpen,
    this.height = 190,
    this.onPick,
    this.picked,
  });

  @override
  Widget build(BuildContext context) {
    final withPin = trips.where((t) => t.lat != null && t.lng != null).toList();
    final pins = [
      for (final t in withPin)
        MapPin(
          item: t,
          lat: t.lat!,
          lng: t.lng!,
          label: '${tripShort(tripAt(t))} · ${t.place ?? t.title}',
          color: t.isMine ? AppColors.ink : AppColors.yellow,
        ),
      if (picked case final p?)
        MapPin(
          item: TaskItem(id: -1 - (p.$1 * 1e4).round().abs() - (p.$2 * 1e4).round().abs(), mode: 'going', title: '여기', who: '', desc: '', distM: null),
          lat: p.$1,
          lng: p.$2,
          label: '여기 가요',
          color: AppColors.ink,
        ),
    ];
    // 핀이 있으면 첫 핀(가장 가까운 시각) 근처, 없으면 내 동네 중심
    final first = picked ?? (withPin.isEmpty ? null : (withPin.first.lat!, withPin.first.lng!));
    final (lat, lng) = first ?? centerOf(scope);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: MapCanvas(
                pins: pins,
                selectedId: null,
                centerLat: lat,
                centerLng: lng,
                zoom: first == null ? zoomOf(scope) : 13,
                onPinTap: (it) {
                  if (it.id >= 0) onOpen(it);
                },
                onMapTap: onPick,
              ),
            ),
            if (onPick == null)
              Positioned(
                left: 10,
                bottom: 9,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        withPin.isEmpty ? '지도에 찍은 일정이 아직 없어요' : '이웃이 가는 곳 ${withPin.length}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.ink2),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 일정 한 줄 — 왼쪽 시각 칸, 가운데 장소·한마디·누가·남은 자리, 오른쪽 '어! 나도!'
class TripRow extends StatelessWidget {
  final TaskItem t;
  final VoidCallback onTap;

  /// 내 일정이면 답을 기다리는 부탁 수
  final int pending;
  const TripRow({super.key, required this.t, required this.onTap, this.pending = 0});

  @override
  Widget build(BuildContext context) {
    final at = tripAt(t);
    final mine = t.isMine;
    final left = t.seatsLeft;
    final open = t.takesAsks;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: mine ? AppColors.yellowSoft : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: mine ? const Color(0xFFF3E2A3) : AppColors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Text(tripDay(at), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.sub)),
                      const SizedBox(height: 1),
                      Text(
                        tripTime(at),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.25),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.place ?? t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                      ),
                      if (t.desc.isNotEmpty)
                        Text(
                          '“${t.desc}”',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.ink2),
                        ),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.sub),
                          children: [
                            TextSpan(text: mine ? '내 일정' : [t.who, if (t.sample && t.ago != null) t.ago!, if (t.sample) '예시'].join(' · ')),
                            const TextSpan(text: ' · '),
                            TextSpan(
                              text: t.closed ? '접수 마감' : (left > 0 ? '$left자리 남음' : '마감'),
                              style: TextStyle(color: (left == 1 && !t.closed) ? AppColors.red : AppColors.sub, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: mine || open ? AppColors.yellow : AppColors.page,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Text(
                    mine ? '요청 $pending건' : (open ? '어! 나도!' : '마감'),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: mine || open ? AppColors.ink : AppColors.faint),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 내 일정 카드 — '내 일정 · 오늘 오후 8시 · 죽전역 이마트 / 새 부탁 2건 확인해 주세요 · 1/3명 수락'
class MyTripCard extends StatelessWidget {
  final TaskItem t;
  final int pending;
  final VoidCallback onTap;
  const MyTripCard({super.key, required this.t, required this.pending, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final at = tripAt(t);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.yellow, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(6)),
                      child: const Text('내 일정', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.yellowInk)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${tripDay(at)} ${tripTime(at)} · ${t.place ?? t.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.sub),
                    children: [
                      pending > 0
                          ? TextSpan(
                              text: '새 부탁 $pending건',
                              style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w800),
                            )
                          : const TextSpan(text: '부탁이 오면 알려드려요'),
                      if (pending > 0) const TextSpan(text: ' 확인해 주세요'),
                      TextSpan(text: ' · ${t.acceptedCount}/${t.capacity}명 수락${t.closed ? ' · 접수 마감' : ''}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 상태 꼬리표 — 답을 기다려요 · 수락했어요 · 구매했어요 · 전달 완료 · 취소·거절됐어요
class TripTag extends StatelessWidget {
  final String label;
  final int stage; // -1 취소 · 0 대기 · 1 수락 · 2 구매 · 3 완료
  const TripTag(this.label, this.stage, {super.key});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (stage) {
      0 => (AppColors.yellowSoft, AppColors.yellowInk),
      1 || 2 => (AppColors.blueSoft, AppColors.blue),
      3 => (AppColors.greenSoft, AppColors.green),
      _ => (AppColors.redSoft, AppColors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
      child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

/// 부탁 → 수락 → 구매 → 전달 진행 막대
class TripStageBar extends StatelessWidget {
  final int stage;
  const TripStageBar(this.stage, {super.key});

  @override
  Widget build(BuildContext context) {
    const labels = ['부탁', '수락', '구매', '전달'];
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        children: [
          for (var k = 0; k < labels.length; k++) ...[
            if (k > 0) const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(color: k <= stage ? AppColors.ink : AppColors.line, borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(height: 5),
                  Text(labels[k], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.sub)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
