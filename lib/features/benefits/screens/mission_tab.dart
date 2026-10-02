import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../../core/widgets/surface.dart';
import '../data/partner_missions.dart';
import '../models/partner_mission.dart';
import '../repositories/mission_progress.dart';
import '../services/mission_filter.dart';
import '../widgets/mission_tile.dart';
import '../widgets/points_card.dart';
import '../widgets/reward_ad_card.dart';
import 'benefits_view.dart';
import 'partner_mission_detail_screen.dart';
import 'point_shop_screen.dart';
import 'side_job_view.dart';

/// 미션·공구 › 미션.
///
/// 보유 포인트 → 광고 보고 포인트 받기 → '참여할 미션'(상태 · 검색 · 종류/조건 칩 · 목록) → 매일의 혜택
class MissionTab extends StatefulWidget {
  final SideJobView view;
  const MissionTab({super.key, required this.view});

  @override
  State<MissionTab> createState() => _MissionTabState();
}

class _MissionTabState extends State<MissionTab> {
  final _search = TextEditingController();
  MissionFilter _filter = const MissionFilter();
  MissionProgress _progress = MissionProgress.load();

  SideJobView get _view => widget.view;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _setFilter(MissionFilter next) => setState(() => _filter = next);

  bool _isDone(PartnerMission m) => _view.doneMissions.contains(m.id);
  bool _isActive(PartnerMission m) => !_isDone(m) && _progress.stageOf(m.id) != MissionStage.ready;

  void _push(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  /// 상세에서 참여 단계가 바뀔 수 있어서, 돌아오면 진행 상태를 다시 읽는다.
  Future<void> _openMission(PartnerMission m) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartnerMissionDetailScreen(m: m, done: _isDone(m), onComplete: _view.completeMission),
      ),
    );
    if (mounted) setState(() => _progress = MissionProgress.load());
  }

  void _openShop() => _push(
    PointShopScreen(
      points: _view.points,
      redeem: _view.redeem,
      coupons: _view.coupons,
      useCoupon: _view.useCoupon,
      goPointsHub: _view.goPointsHub,
    ),
  );

  /// 출석 밖의 기본 적립(광고·프로필·친구 추천 등)
  void _openDailyBenefits() => _push(
    ScreenFrame(
      title: '매일의 혜택',
      onBack: () => Navigator.pop(context),
      child: BenefitsView(
        points: _view.points,
        coupons: _view.coupons,
        items: _view.items,
        scope: _view.scope,
        actions: _view.actions,
        monthEarn: _view.monthEarn,
        freeLeft: _view.freeLeft,
        doneMissions: _view.doneMissions,
        earn: _view.earn,
        isClaimed: _view.isClaimed,
        redeem: _view.redeem,
        useCoupon: _view.useCoupon,
        completeMission: _view.completeMission,
        goPointsHub: _view.goPointsHub,
        flash: _view.flash,
        showHeader: false,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final list = _filter.apply(partnerMissions, isDone: _isDone, isActive: _isActive);
    return Column(
      children: [
        PointsCard(points: _view.points, onOpenShop: _openShop),
        RewardAdCard(isClaimed: _view.isClaimed, earn: _view.earn, flash: _view.flash),
        SecCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SecHead(title: '참여할 미션', trailing: _sortDropdown()),
              MiniTabs(
                tabs: [
                  ('전체', partnerMissions.length),
                  ('참여 중', partnerMissions.where(_isActive).length),
                  ('적립 완료', partnerMissions.where(_isDone).length),
                ],
                index: _filter.status.index,
                onChanged: (i) => _setFilter(_filter.copyWith(status: MissionStatus.values[i])),
              ),
              _searchField(),
              _chips(),
              if (list.isEmpty) _empty() else _missionList(list),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  '체험용 미션 · 실제 제휴 및 지급 연동 전입니다. 완료한 미션은 아래에 표시돼요.',
                  style: AppType.caption.copyWith(color: AppColors.faint, height: 1.6),
                ),
              ),
            ],
          ),
        ),
        _DailyBenefitsRow(onTap: _openDailyBenefits),
      ],
    );
  }

  Widget _sortDropdown() {
    return DropdownButton<String>(
      value: _filter.sort,
      underline: const SizedBox.shrink(),
      isDense: true,
      icon: const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.sub),
      style: AppType.meta.copyWith(color: AppColors.sub),
      items: [for (final (k, label) in MissionFilter.sorts) DropdownMenuItem(value: k, child: Text(label))],
      onChanged: (v) => _setFilter(_filter.copyWith(sort: v ?? 'basic')),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        controller: _search,
        onChanged: (text) => _setFilter(_filter.copyWith(text: text)),
        style: AppType.body.copyWith(fontSize: 13),
        decoration: const InputDecoration(
          hintText: '어떤 미션을 찾으세요?',
          prefixIcon: Icon(Icons.search_rounded, size: 19, color: AppColors.faint),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _chips() {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final (k, label) in MissionFilter.cats) ...[
            ChipWidget(
              label: label,
              active: _filter.cat == k,
              onTap: () => _setFilter(_filter.copyWith(cat: k)),
            ),
            const SizedBox(width: 7),
          ],
          ChipWidget(
            label: '3분 이내',
            active: _filter.shortOnly,
            onTap: () => _setFilter(_filter.copyWith(shortOnly: !_filter.shortOnly)),
          ),
          const SizedBox(width: 7),
          ChipWidget(
            label: '구매 없음',
            active: _filter.freeOnly,
            onTap: () => _setFilter(_filter.copyWith(freeOnly: !_filter.freeOnly)),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      child: Center(
        child: Text(
          _filter.status == MissionStatus.active ? '참여 중인 미션이 없어요.' : '조건에 맞는 미션이 없어요. 필터를 바꿔 보세요.',
          textAlign: TextAlign.center,
          style: AppType.meta.copyWith(fontSize: 13, height: 1.7),
        ),
      ),
    );
  }

  Widget _missionList(List<PartnerMission> list) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Column(
        children: [
          for (int i = 0; i < list.length; i++)
            MissionTile(
              m: list[i],
              done: _isDone(list[i]),
              active: _isActive(list[i]),
              last: i == list.length - 1,
              onTap: () => _openMission(list[i]),
            ),
        ],
      ),
    );
  }
}

class _DailyBenefitsRow extends StatelessWidget {
  final VoidCallback onTap;
  const _DailyBenefitsRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.surface),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.surface),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const IconTile(icon: 'gift', bg: Color(0xFFFBF5E6), fg: Color(0xFFD99A00)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('매일의 혜택', style: AppType.body.copyWith(fontWeight: AppType.w700)),
                      Text(
                        '광고 보기 · 프로필 완성 · 친구 추천 포인트',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.meta.copyWith(fontWeight: AppType.w600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
