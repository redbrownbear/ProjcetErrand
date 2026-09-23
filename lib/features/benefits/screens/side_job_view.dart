import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../errand/models/task_item.dart';
import '../../errand/navigation/errand_actions.dart';
import '../../gongu/screens/gongu_screen.dart';
import '../../partner/screens/brand_hub_screen.dart';
import '../data/partner_missions.dart';
import '../models/coupon.dart';
import '../models/mission_meta.dart';
import '../models/partner_mission.dart';
import '../models/reward_ledger.dart';
import '../models/reward_product.dart';
import '../repositories/mission_progress.dart';
import '../widgets/mission_tile.dart';
import 'benefits_view.dart';
import 'partner_mission_detail_screen.dart';
import 'point_shop_screen.dart';

/// 부업 탭. 시안(`gyumsa-refined`)의 `sidejobs-v8` 화면을 옮겼다.
///
/// 미션이 20개를 넘으면서 "어떤 미션이 나한테 맞는지" 고르는 일이 어려워졌다.
/// 그래서 검색·상태(전체/참여 중/적립 완료)·종류·조건(3분 이내·구매 없음)을
/// 한 줄씩 얹고, 3분 안에 끝나는 미션 두 개를 맨 위에 따로 뽑아 둔다.
class SideJobView extends StatefulWidget {
  final int points;
  final List<Coupon> coupons;
  final List<TaskItem> items;
  final String scope;
  final ErrandActions actions;
  final int monthEarn;
  final int freeLeft;
  final List<String> doneMissions;
  final EarnFn earn;
  final IsClaimedFn isClaimed;
  final void Function(RewardProduct) redeem;
  final void Function(int id) useCoupon;
  final void Function(PartnerMission) completeMission;
  final VoidCallback goPointsHub;
  final void Function(String) flash;

  const SideJobView({
    super.key,
    required this.points,
    required this.coupons,
    required this.items,
    required this.scope,
    required this.actions,
    required this.monthEarn,
    required this.freeLeft,
    required this.doneMissions,
    required this.earn,
    required this.isClaimed,
    required this.redeem,
    required this.useCoupon,
    required this.completeMission,
    required this.goPointsHub,
    required this.flash,
  });

  @override
  State<SideJobView> createState() => _SideJobViewState();
}

/// 미션 목록 상태 탭
enum _Status { all, active, done }

class _SideJobViewState extends State<SideJobView> {
  /// 시안의 종류 칩. 앱에는 연구·상담 미션이 더 있어서 한 칸을 더 뒀다.
  static const _cats = [
    ('all', '전체'),
    ('survey', '설문조사'),
    ('signup', '가입'),
    ('visit', '방문'),
    ('shopping', '쇼핑'),
    ('experience', '앱·체험'),
    ('blog', '블로그·SNS'),
    ('research', '연구·상담'),
  ];

  static const _sorts = [('basic', '기본순'), ('point', '포인트 높은순'), ('time', '소요시간 짧은순')];

  final search = TextEditingController();
  String cat = 'all';
  String sort = 'basic';
  _Status status = _Status.all;
  bool shortOnly = false; // 3분 이내
  bool freeOnly = false; // 구매 없음

  MissionProgress progress = MissionProgress.load();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  bool _isDone(PartnerMission m) => widget.doneMissions.contains(m.id);
  bool _isActive(PartnerMission m) => !_isDone(m) && progress.stageOf(m.id) != MissionStage.ready;

  int get activeCount => partnerMissions.where(_isActive).length;
  int get doneCount => partnerMissions.where(_isDone).length;

  List<PartnerMission> get _list {
    final q = search.text.trim();
    var list = partnerMissions.where((m) {
      if (cat != 'all') {
        final matched = cat == 'research' ? (m.cat == 'research' || m.cat == 'consult') : m.cat == cat;
        if (!matched) return false;
      }
      if (shortOnly && m.minutes > 3) return false;
      if (freeOnly && !m.isFree) return false;
      if (status == _Status.active && !_isActive(m)) return false;
      if (status == _Status.done && !_isDone(m)) return false;
      if (q.isNotEmpty && !'${m.title} ${m.brand} ${m.desc}'.contains(q)) return false;
      return true;
    }).toList();

    list.sort((a, b) {
      // 적립을 끝낸 미션은 언제나 아래로 내린다.
      final ad = _isDone(a) ? 1 : 0;
      final bd = _isDone(b) ? 1 : 0;
      if (ad != bd) return ad - bd;
      return switch (sort) {
        'point' => b.points - a.points,
        'time' => a.minutes - b.minutes,
        _ => 0,
      };
    });
    return list;
  }

  /// 맨 위 두 칸. 참여 중인 미션이 있으면 그걸 먼저 보여주고(이어서 참여해요),
  /// 없으면 3분 안에 끝나고 돈이 들지 않는 미션을 뽑는다(가볍게 시작해요).
  List<PartnerMission> get _starters {
    final active = partnerMissions.where(_isActive).take(2).toList();
    if (active.isNotEmpty) return active;
    return partnerMissions
        .where((m) =>
            m.minutes <= 3 &&
            m.isFree &&
            !_isDone(m) &&
            // 가입처럼 조건이 붙는 미션 말고, 정말 가볍게 해볼 수 있는 것만 뽑는다.
            const ['survey', 'experience'].contains(m.cat))
        .take(2)
        .toList();
  }

  Future<void> _openMission(PartnerMission m) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PartnerMissionDetailScreen(
        m: m, done: _isDone(m), onComplete: widget.completeMission,
      )),
    );
    if (mounted) setState(() => progress = MissionProgress.load());
  }

  void _openBrandHub() => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandHubScreen()));

  @override
  Widget build(BuildContext context) {
    final list = _list;
    return ListView(
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        _header(),
        _earningPair(),
        _starterSection(),
        _listHead(),
        _search(),
        _statusTabs(),
        _catChips(),
        _filterChips(),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 4),
          child: Text('${list.length}개 미션 · 완료한 미션은 아래에 표시돼요', style: AppType.caption),
        ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 32),
            child: Text('조건에 맞는 미션이 없어요. 필터를 바꿔 보세요.',
                textAlign: TextAlign.center, style: AppType.meta.copyWith(height: 1.7)),
          ),
        for (final m in list)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MissionTile(
              m: m,
              done: _isDone(m),
              active: _isActive(m),
              onTap: () => _openMission(m),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 4),
          child: Text('체험용 미션 · 실제 제휴 및 지급 연동 전입니다.', style: AppType.caption.copyWith(height: 1.7)),
        ),
        _dailyBenefits(),
        _partnerFooter(),
      ],
    );
  }

  /// 제목 + 브랜드 협업 바로가기 (.sidejobs-v8 > header)
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 20, 15),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('오늘은 뭘 해볼까요?', style: AppType.tabTitle.copyWith(fontSize: 23)),
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text('짧은 시간에도 차곡차곡 모아요', style: AppType.meta.copyWith(fontSize: 12)),
            ),
          ]),
        ),
        TextButton(
          onPressed: _openBrandHub,
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: const Size(0, 30)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('브랜드 협업', style: AppType.caption.copyWith(fontSize: 10, color: AppColors.goalMintSub)),
            const SizedBox(width: 3),
            const AppIcon('chevron', size: 14, color: AppColors.goalMintSub),
          ]),
        ),
      ]),
    );
  }

  /// 내 포인트 · 공동구매 두 칸 (.earning-pair-v8)
  Widget _earningPair() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      // ListView 안이라 높이가 무한대다. 두 칸의 키를 맞추려면 높이를 정해 줘야 한다.
      child: SizedBox(
        height: 150,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: _pairCard(
            bg: const Color(0xFFFFF0BA),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PointShopScreen(
                points: widget.points, redeem: widget.redeem, coupons: widget.coupons,
                useCoupon: widget.useCoupon, goPointsHub: widget.goPointsHub,
              )),
            ),
            children: [
              Text('내 포인트', style: AppType.caption.copyWith(fontSize: 11, color: const Color(0xFF9F8950))),
              const Spacer(),
              Text('${nf(widget.points)}P',
                  style: AppType.section.copyWith(fontSize: 27, color: const Color(0xFF4C4934))),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('포인트 사용', style: AppType.caption.copyWith(fontSize: 11, color: const Color(0xFF9F8950))),
              ),
            ],
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: _pairCard(
            bg: const Color(0xFFE8F2ED),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GonguScreen(earn: widget.earn, isClaimed: widget.isClaimed)),
            ),
            children: [
              Text('공동구매', style: AppType.caption.copyWith(fontSize: 11, color: const Color(0xFF819787))),
              const Spacer(),
              Text('인플루언서가 아니어도\n공구로 수익을',
                  style: AppType.body.copyWith(fontSize: 13, height: 1.5, fontWeight: AppType.w600, color: const Color(0xFF477660))),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('함께 살 사람 모으기', style: AppType.caption.copyWith(fontSize: 11, color: const Color(0xFF819787))),
              ),
            ],
          ),
        ),
        ]),
      ),
    );
  }

  Widget _pairCard({required Color bg, required VoidCallback onTap, required List<Widget> children}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.surface),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.surface)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }

  /// 3분 안에 끝나는 미션 두 개 (.g4-starter)
  Widget _starterSection() {
    final starters = _starters;
    if (starters.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(activeCount > 0 ? '이어서 참여해요' : '가볍게 시작해요',
              style: AppType.sectionSmall.copyWith(fontSize: 15, color: const Color(0xFF476352))),
          Text(activeCount > 0 ? '$activeCount개 참여 중' : '3분 이내 · 구매 없음',
              style: AppType.caption.copyWith(fontSize: 10, color: const Color(0xFF93A28D))),
        ]),
        const SizedBox(height: 11),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (int i = 0; i < starters.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _starterCard(starters[i], i)),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _starterCard(PartnerMission m, int i) {
    final tint = i == 0 ? const Color(0xFFF3F0DF) : const Color(0xFFEAF1FB);
    final fg = i == 0 ? const Color(0xFFAB9A60) : const Color(0xFF81A4BC);
    return InkWell(
      onTap: () => _openMission(m),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 31,
              height: 31,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(11)),
              child: AppIcon(m.isVisit ? 'pin' : 'sparkles', size: 17, color: fg),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                switch (progress.stageOf(m.id)) {
                  MissionStage.review => '검수 대기',
                  MissionStage.active => '참여 중',
                  MissionStage.ready => m.time,
                },
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.caption.copyWith(fontSize: 10, color: const Color(0xFF9AA68E)),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(m.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppType.body.copyWith(fontSize: 12, height: 1.5, fontWeight: AppType.w600, color: const Color(0xFF4B614E))),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('+${nf(m.points)}P',
                  style: AppType.body.copyWith(fontSize: 13, fontWeight: AppType.w700, color: const Color(0xFFC99B3A))),
              const AppIcon('chevron', size: 16, color: Color(0xFFB4C3A9)),
            ]),
          ),
        ]),
      ),
    );
  }

  /// 미션 제목 + 정렬
  Widget _listHead() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 20, 0),
      child: Row(children: [
        Expanded(child: Text('미션', style: AppType.section)),
        DropdownButton<String>(
          value: sort,
          underline: const SizedBox.shrink(),
          isDense: true,
          style: AppType.meta.copyWith(fontSize: 12, color: AppColors.inkSoft),
          items: [for (final (k, label) in _sorts) DropdownMenuItem(value: k, child: Text(label))],
          onChanged: (v) => setState(() => sort = v ?? 'basic'),
        ),
      ]),
    );
  }

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: TextField(
        controller: search,
        onChanged: (_) => setState(() {}),
        style: AppType.body.copyWith(fontSize: 13),
        decoration: InputDecoration(
          hintText: '어떤 부업을 찾으세요?',
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          prefixIcon: const Icon(Icons.search_rounded, size: 19, color: AppColors.faint),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.green)),
        ),
      ),
    );
  }

  /// 전체 · 참여 중 · 적립 완료 (.g2-status-tabs)
  Widget _statusTabs() {
    final counts = {
      _Status.all: partnerMissions.length,
      _Status.active: activeCount,
      _Status.done: doneCount,
    };
    const labels = {_Status.all: '전체', _Status.active: '참여 중', _Status.done: '적립 완료'};

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: const Color(0xFFEEF2EB), borderRadius: BorderRadius.circular(17)),
      child: Row(children: [
        for (final s in _Status.values)
          Expanded(
            child: InkWell(
              onTap: () => setState(() => status = s),
              borderRadius: BorderRadius.circular(13),
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: status == s ? AppColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                  Flexible(
                    child: Text(labels[s]!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.body.copyWith(
                          fontSize: 12.5,
                          fontWeight: AppType.w600,
                          color: status == s ? AppColors.green : const Color(0xFF8A8C83),
                        )),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: status == s ? const Color(0xFFEDF1E1) : const Color(0xFFE7EEE4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${counts[s]}',
                        style: AppType.caption.copyWith(
                          fontSize: 10,
                          color: status == s ? const Color(0xFF5C713F) : const Color(0xFF87A077),
                        )),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  /// 종류 칩 (.mission-categories-v8)
  Widget _catChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Wrap(spacing: 7, runSpacing: 7, children: [
        for (final (k, label) in _cats)
          _chip(
            label: label,
            selected: cat == k,
            onTap: () => setState(() => cat = k),
            selectedBg: AppColors.green,
            selectedInk: Colors.white,
          ),
      ]),
    );
  }

  /// 조건 칩 (.gy-filters)
  Widget _filterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(children: [
        _chip(
          label: '3분 이내',
          selected: shortOnly,
          onTap: () => setState(() => shortOnly = !shortOnly),
          selectedBg: const Color(0xFFEDF2E5),
          selectedInk: const Color(0xFF405529),
        ),
        const SizedBox(width: 7),
        _chip(
          label: '구매 없음',
          selected: freeOnly,
          onTap: () => setState(() => freeOnly = !freeOnly),
          selectedBg: const Color(0xFFEDF2E5),
          selectedInk: const Color(0xFF405529),
        ),
      ]),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color selectedBg,
    required Color selectedInk,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? selectedBg : AppColors.card,
          border: Border.all(color: selected ? selectedBg : AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label,
            style: AppType.caption.copyWith(
              fontSize: 12,
              fontWeight: selected ? AppType.w600 : AppType.w400,
              color: selected ? selectedInk : const Color(0xFF879187),
            )),
      ),
    );
  }

  /// 출석 밖의 기본 적립(광고·프로필·친구 추천 등)은 시안에 없지만 앱에는 있다.
  /// 부업 탭을 미션 중심으로 비우는 대신, 한 줄로 남겨 들어갈 수 있게 한다.
  Widget _dailyBenefits() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ScreenFrame(
            title: '매일의 혜택',
            onBack: () => Navigator.pop(context),
            child: BenefitsView(
              points: widget.points, coupons: widget.coupons, items: widget.items,
              scope: widget.scope, actions: widget.actions, monthEarn: widget.monthEarn,
              freeLeft: widget.freeLeft, doneMissions: widget.doneMissions,
              earn: widget.earn, isClaimed: widget.isClaimed, redeem: widget.redeem, useCoupon: widget.useCoupon,
              completeMission: widget.completeMission, goPointsHub: widget.goPointsHub, flash: widget.flash,
              showHeader: false,
            ),
          )),
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)),
              child: const AppIcon('gift', size: 21, color: AppColors.goalMintInk),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('매일의 혜택', style: AppType.body.copyWith(fontSize: 13, fontWeight: AppType.w600)),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('광고 보기 · 프로필 완성 · 친구 추천처럼 오늘 받을 수 있는 포인트',
                      style: AppType.caption.copyWith(fontSize: 10, height: 1.6)),
                ),
              ]),
            ),
            const AppIcon('chevron', size: 17, color: AppColors.faint),
          ]),
        ),
      ),
    );
  }

  /// 겸사겸사 파트너 (.g4-partner-footer)
  Widget _partnerFooter() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 27, 20, 10),
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(color: const Color(0xFF304F45), borderRadius: BorderRadius.circular(AppRadius.surface)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(AppRadius.tile),
            ),
            child: const AppIcon('handshake', size: 22, color: Color(0xFFD0DCC6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('겸사겸사 파트너', style: AppType.caption.copyWith(fontSize: 10, color: const Color(0xFFA9C1B4))),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text('겸사겸사와 브랜드 협업',
                    style: AppType.sectionSmall.copyWith(fontSize: 16, height: 1.4, color: const Color(0xFFF4F6F0))),
              ),
            ]),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 17),
          child: Text('브랜드를 경험하는 미션부터 공동구매까지.\n목표에 맞는 협업을 함께 준비해요.',
              style: AppType.meta.copyWith(fontSize: 12, height: 1.85, color: const Color(0xFFB9CEBF))),
        ),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final t in ['체험·리뷰', '설문·리서치', '공동구매·광고'])
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF597266)),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(t, style: AppType.caption.copyWith(fontSize: 10, color: const Color(0xFFBBD1BE))),
            ),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 21),
          child: InkWell(
            onTap: _openBrandHub,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: const Color(0xFFE9E9CD), borderRadius: BorderRadius.circular(13)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('협업 방식 알아보기',
                    style: AppType.button.copyWith(fontSize: 12, fontWeight: AppType.w700, color: const Color(0xFF385443))),
                const AppIcon('arrowRight', size: 17, color: Color(0xFF385443)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
