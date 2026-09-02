import '../../features/gongu/models/gongu.dart';
import '../../features/benefits/models/partner_mission.dart';

/// 홈 셸의 전체화면 스택에 쌓이는 라우트 설정.
/// name: list | overseas | country | search | map | community | walk | shop | coupons | mission | earn | gongu | gongudetail
class ScreenRoute {
  final String name;
  // list 화면 설정
  final String? title;
  final String? subtitle;
  final String? base; // ask | earn | sea
  final String? cat; // 카테고리 필터 (community에서는 initCat으로도 쓰임)
  final bool sortable;
  final bool catChips;
  final bool mapBtn;
  final bool onlyHot;
  final int? maxMins;
  final String? defaultSort;
  // country 화면
  final String? cc;
  // mission 화면
  final PartnerMission? mission;
  // gongudetail 화면
  final Gongu? gongu;

  const ScreenRoute({
    required this.name,
    this.title,
    this.subtitle,
    this.base,
    this.cat,
    this.sortable = false,
    this.catChips = false,
    this.mapBtn = false,
    this.onlyHot = false,
    this.maxMins,
    this.defaultSort,
    this.cc,
    this.mission,
    this.gongu,
  });
}
