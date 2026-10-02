import 'package:flutter/material.dart';

import '../../../../core/navigation/screen_route.dart';
import '../../../benefits/screens/daily_mission_screen.dart';
import '../../../benefits/screens/earn_hub_screen.dart';
import '../../../benefits/screens/point_shop_screen.dart';
import '../../../benefits/screens/walk_screen.dart';
import '../../../benefits/services/mission_engine.dart';
import '../../../benefits/services/mission_runner.dart';
import '../../../community/screens/community_screen.dart';
import '../../../dayjob/models/day_job.dart';
import '../../../dayjob/screens/day_job_screen.dart';
import '../../../deals/screens/save_hub_screen.dart';
import '../../models/task_item.dart';
import '../list_screen.dart';
import '../local_errand_hub_screen.dart';
import '../map_screen.dart';
import 'home_content.dart';

/// 홈에서 다른 화면으로 넘어가는 길을 한곳에 모은 것.
///
/// 홈의 조각 위젯들은 이 객체만 받으면 어디로든 보낼 수 있다. 화면을 여는 데 필요한
/// 값(부탁 목록·포인트·적립 함수 등)은 전부 [HomeContent]가 들고 있다.
class HomeNav {
  final BuildContext context;
  final HomeContent home;
  const HomeNav(this.context, this.home);

  void _push(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  void openTask(TaskItem it) => home.actions.open(context, it);

  void list(ScreenRoute config) => _push(ListScreen(config: config, items: home.items, scope: home.scope, actions: home.actions));

  void community() => _push(CommunityScreen(items: home.items, scope: home.scope, actions: home.actions));

  void dayJobs() => _push(DayJobScreen(onApply: applyDayJob, onPost: home.openJobPost));

  void openDayJobDetail(DayJob j) => openDayJob(context, j, applyDayJob);

  void applyDayJob(DayJob j) => home.flash('${j.org}에 지원 의사를 전달했어요 · 근로계약은 구인업체와 진행돼요');

  /// 종류·조건별 모아보기가 있는 동네 부탁 허브
  void localHub() => _push(LocalErrandHubScreen(items: home.items, scope: home.scope, actions: home.actions));

  void fullMap(List<TaskItem> list) => _push(MapScreen(items: list, scope: home.scope, actions: home.actions));

  void walk() => _push(
    WalkScreen(
      items: home.items,
      scope: home.scope,
      steps: home.steps,
      points: home.points,
      coupons: home.coupons,
      actions: home.actions,
      earn: home.earn,
      isClaimed: home.isClaimed,
      redeem: home.redeem,
      useCoupon: home.useCoupon,
      goPointsHub: home.goPointsHub,
    ),
  );

  void shop() => _push(
    PointShopScreen(
      points: home.points,
      redeem: home.redeem,
      coupons: home.coupons,
      useCoupon: home.useCoupon,
      goPointsHub: home.goPointsHub,
    ),
  );

  /// 제휴 미션 '오늘 벌기' 허브
  void earnHub() => _push(
    EarnHubScreen(
      doneMissions: home.doneMissions,
      completeMission: home.completeMission,
      onOpenErrand: () => list(
        const ScreenRoute(
          name: 'list',
          title: '심부름으로 벌기',
          subtitle: '지역 픽업 · 개인/기업 심부름',
          base: 'earn',
          sortable: true,
          catChips: true,
          mapBtn: true,
        ),
      ),
      onApplyDayJob: applyDayJob,
    ),
  );

  /// 제휴 가게·회원 전용가 허브
  void saveHub() => _push(
    SaveHubScreen(
      earn: home.earn,
      isClaimed: home.isClaimed,
      onUse: (d) => home.flash('${d.brand} 회원 전용가를 준비 중이에요 · 제휴 확정 후 열려요'),
    ),
  );

  void dailyMissions() => _push(
    DailyMissionScreen(
      runner: MissionRunner(
        earn: home.earn,
        flash: home.flash,
        scope: home.scope,
        goWalk: walk,
        goProfile: home.goProfile,
        goPost: home.goPost,
        goList: localHub,
      ),
      engine: MissionEngine(home.isClaimed),
      goEarnHub: earnHub,
    ),
  );

  /// 광고 배너가 가리키는 곳으로
  void openAd(ScreenRoute route) {
    switch (route.name) {
      case 'shop':
        shop();
      case 'overseas':
        home.goOverseasTab();
      case 'walk':
        walk();
      default:
        list(route);
    }
  }
}
