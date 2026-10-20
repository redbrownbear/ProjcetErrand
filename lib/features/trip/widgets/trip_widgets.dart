import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../../../core/widgets/surface.dart';
import '../screens/trip_screens.dart';
import '../screens/trip_tab.dart';
import 'trip_parts.dart';

/// 홈 · 해외 탭이 같이 쓰는 v77 조각 — 여행 도구 칸과 '가는 김에' 글 목록.

/// '여행 어디 갈까?' · '세계 제안 지도' 회색 도구 칸 (.pp-tools)
class TripTools extends StatelessWidget {
  final AppNav nav;
  final bool abroad;
  const TripTools({super.key, required this.nav, this.abroad = false});

  @override
  Widget build(BuildContext context) {
    final dart = ToolTile(
      lead: const _Target(),
      title: '여행 어디 갈까?',
      sub: abroad ? '다트를 던져 정해요' : '다트를 던져 정해요 · 명소·맛집·숙소까지',
      compact: abroad,
      onTap: () => nav.openDart(context, abroad: abroad),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: abroad
          ? Row(
              children: [
                Expanded(
                  child: ToolTile(
                    lead: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.public_rounded, size: 20, color: AppColors.blue),
                    ),
                    title: '세계 제안 지도',
                    sub: '나라별 제안, 요청 한눈에',
                    compact: true,
                    onTap: () => nav.openWorld(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: dart),
              ],
            )
          : dart,
    );
  }
}

class _Target extends StatelessWidget {
  const _Target();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.red, width: 5),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// 홈의 '가는 김에' 칸 (시안 v78) — 누가 가면, 나도 하나! 눌러서 어! 나도.
/// 지도 · 나 여기 가요 · 내 일정 · 가장 가까운 이웃 일정 한 줄 · 전체보기(가는 김에 탭) · 내 활동.
class TripSection extends StatelessWidget {
  final AppNav nav;
  final VoidCallback onAll;
  const TripSection({super.key, required this.nav, required this.onAll});

  @override
  Widget build(BuildContext context) {
    final listen = nav.session;
    Widget body(BuildContext context) {
      final mine = tripList(nav, mine: true);
      final others = tripList(nav, mine: false);
      final badge = nav.session?.tripBadge ?? 0;
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 14, 12, 6),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
        decoration: BoxDecoration(
          color: AppColors.yellowSoft,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF3E2A3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('가는 김에', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                        SizedBox(height: 2),
                        Text('누가 가면, 나도 하나! 눌러서 어! 나도', style: TextStyle(fontSize: 12.5, color: AppColors.sub, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  TripRegisterButton(onTap: () => openTripRegister(context, nav)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TripMap(
                trips: [...mine, ...others],
                scope: nav.session?.scope ?? '전국',
                height: 160,
                onOpen: (t) => openTrip(context, nav, t),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  for (final t in mine)
                    MyTripCard(t: t, pending: nav.session?.receivedFor(t.id).length ?? 0, onTap: () => openTrip(context, nav, t)),
                  if (others.isEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                      child: const Text('지금 올라온 일정이 없어요. 가시는 곳을 먼저 알려 보세요.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.sub, fontSize: 13.5)),
                    )
                  else
                    TripRow(t: others.first, onTap: () => openTrip(context, nav, others.first)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  TextLink(label: '전체보기 ›', onTap: onAll),
                  const Spacer(),
                  TripActivityLink(count: badge, onTap: () => openTripActivity(context, nav)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return listen == null ? Builder(builder: body) : ListenableBuilder(listenable: listen, builder: (c, _) => body(c));
  }
}
