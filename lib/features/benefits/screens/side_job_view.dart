import 'package:flutter/material.dart';

import '../../../core/ads/kakao_reward_ad.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../../core/widgets/surface.dart';
import '../../errand/models/task_item.dart';
import '../../errand/navigation/errand_actions.dart';
import '../../gongu/models/gongu.dart';
import '../../gongu/repositories/gongu_repository.dart';
import '../../gongu/screens/gongu_detail_screen.dart';
import '../../gongu/screens/gongu_screen.dart';
import '../../partner/screens/brand_hub_screen.dart';
import '../data/daily_missions.dart';
import '../data/partner_missions.dart';
import '../data/reward_products.dart';
import '../models/coupon.dart';
import '../models/mission_meta.dart';
import '../models/partner_mission.dart';
import '../models/reward_ledger.dart';
import '../models/reward_product.dart';
import '../repositories/mission_progress.dart';
import '../services/mission_engine.dart';
import '../services/reward_ad_flow.dart';
import '../widgets/mission_tile.dart';
import 'benefits_view.dart';
import 'partner_mission_detail_screen.dart';
import 'point_shop_screen.dart';

/// 하단 '미션·공구' 탭 (시안 v33 `#sideRoot`).
///
/// 안쪽 밑줄 탭으로 **미션 | 공동구매**를 나눈다.
/// - 미션: 보유 포인트 카드 → '참여할 미션' 카드(상태 세그먼트 · 검색 · 종류/조건 칩 · 목록) → 매일의 혜택
/// - 공동구매: 2열 상품 카드
///
/// 미션이 20개를 넘으면서 "어떤 미션이 나한테 맞는지" 고르는 일이 어려워졌다.
/// 그래서 검색·상태(전체/참여 중/적립 완료)·종류·조건(3분 이내·구매 없음)을 한 카드 안에 모았다.
class SideJobView extends StatefulWidget {
  /// 처음 열 안쪽 탭 — 0 미션 · 1 공동구매
  final int initialSub;
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
    this.initialSub = 0,
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

  /// 안쪽 탭 — 0 미션 · 1 공동구매
  late int sub = widget.initialSub;

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
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        UnderlineTabs(
          tabs: const [('미션', null), ('공동구매', null)],
          index: sub,
          onChanged: (i) => setState(() => sub = i),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          fontSize: 15.5,
          gap: 24,
        ),
        ...(sub == 0 ? _missionSections() : _gonguSections()),
        _inquiry(),
      ],
    );
  }

  // ── 미션 ────────────────────────────────────────────────────────────────

  List<Widget> _missionSections() {
    final list = _list;
    return [
      _pointsCard(),
      _rewardAdCard(),
      SecCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SecHead(
            title: '참여할 미션',
            trailing: DropdownButton<String>(
              value: sort,
              underline: const SizedBox.shrink(),
              isDense: true,
              icon: const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.sub),
              style: AppType.meta.copyWith(color: AppColors.sub),
              items: [for (final (k, label) in _sorts) DropdownMenuItem(value: k, child: Text(label))],
              onChanged: (v) => setState(() => sort = v ?? 'basic'),
            ),
          ),
          MiniTabs(
            tabs: [('전체', partnerMissions.length), ('참여 중', activeCount), ('적립 완료', doneCount)],
            index: status.index,
            onChanged: (i) => setState(() => status = _Status.values[i]),
          ),
          _search(),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final (k, label) in _cats) ...[
                  ChipWidget(label: label, active: cat == k, onTap: () => setState(() => cat = k)),
                  const SizedBox(width: 7),
                ],
                ChipWidget(label: '3분 이내', active: shortOnly, onTap: () => setState(() => shortOnly = !shortOnly)),
                const SizedBox(width: 7),
                ChipWidget(label: '구매 없음', active: freeOnly, onTap: () => setState(() => freeOnly = !freeOnly)),
              ],
            ),
          ),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
              child: Center(
                child: Text(status == _Status.active ? '참여 중인 미션이 없어요.' : '조건에 맞는 미션이 없어요. 필터를 바꿔 보세요.',
                    textAlign: TextAlign.center, style: AppType.meta.copyWith(fontSize: 13, height: 1.7)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Column(children: [
                for (int i = 0; i < list.length; i++)
                  MissionTile(
                    m: list[i],
                    done: _isDone(list[i]),
                    active: _isActive(list[i]),
                    last: i == list.length - 1,
                    onTap: () => _openMission(list[i]),
                  ),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text('체험용 미션 · 실제 제휴 및 지급 연동 전입니다. 완료한 미션은 아래에 표시돼요.',
                style: AppType.caption.copyWith(color: AppColors.faint, height: 1.6)),
          ),
        ]),
      ),
      _dailyBenefits(),
    ];
  }

  /// 보유 포인트 (.pts2) — 다음 교환 상품까지 남은 포인트를 막대로 보여 준다.
  Widget _pointsCard() {
    final goal = nextRewardGoal(widget.points);
    final progress = goal == null ? 1.0 : widget.points / (widget.points + goal.remain);
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('보유 포인트', style: AppType.meta.copyWith(fontWeight: AppType.w500)),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: nf(widget.points)),
                  const TextSpan(text: 'P', style: TextStyle(fontSize: 13, color: AppColors.yellowInk)),
                ]),
                style: const TextStyle(fontSize: 18, fontWeight: AppType.w700, color: AppColors.ink, letterSpacing: -0.72),
              ),
            ]),
          ),
          Material(
            color: AppColors.page,
            borderRadius: BorderRadius.circular(9),
            child: InkWell(
              onTap: _openShop,
              borderRadius: BorderRadius.circular(9),
              child: Container(
                height: 30,
                padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('포인트샵', style: AppType.meta.copyWith(fontSize: 12.5, fontWeight: AppType.w600, color: AppColors.ink2)),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.ink2),
                ]),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1).toDouble(),
            minHeight: 3,
            backgroundColor: AppColors.soft2,
            valueColor: const AlwaysStoppedAnimation(AppColors.yellow),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          goal == null ? '포인트샵의 모든 상품으로 바꿀 수 있어요' : '${nf(goal.remain)}P 더 모으면 ${goal.name}(으)로 바꿀 수 있어요',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppType.caption.copyWith(fontSize: 11.5),
        ),
      ]),
    );
  }

  /// 광고 보고 포인트 받기 — 카카오 애드핏 리워드 동영상만 쓴다.
  ///
  /// 적립 규칙(하루 횟수·포인트)은 데일리 미션의 'ad'와 같은 원장 키를 쓰므로,
  /// 여기서 보든 '매일 미션' 화면에서 보든 하루 한도가 함께 줄어든다.
  Widget _rewardAdCard() {
    final s = MissionEngine(widget.isClaimed).stateOf(dailyMissions.firstWhere((m) => m.id == 'ad'));
    final ready = !s.locked && KakaoRewardAd.configured;
    final (label, active) = s.done
        ? ('오늘 완료', false)
        : ready
            ? ('+${nf(s.m.points)}P 받기', true)
            : ('준비 중', false);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const IconTile(icon: 'play', bg: AppColors.yellowSoft, fg: AppColors.yellowInk),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('광고 보고 포인트 받기', style: AppType.body.copyWith(fontWeight: AppType.w700)),
            const SizedBox(height: 2),
            Text(
              ready || s.done ? '카카오 광고 영상 · 오늘 ${s.claimed}/${s.m.cap}번' : '카카오 광고 연결을 준비 중이에요',
              style: AppType.meta.copyWith(fontWeight: AppType.w500),
            ),
          ]),
        ),
        Material(
          color: active ? AppColors.yellow : AppColors.page,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () async {
              await RewardAdFlow(earn: widget.earn, flash: widget.flash).run(context, s);
              if (mounted) setState(() {});
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              child: Text(label,
                  style: AppType.meta.copyWith(
                    fontSize: 13,
                    fontWeight: AppType.w700,
                    color: active ? AppColors.ink : AppColors.sub,
                  )),
            ),
          ),
        ),
      ]),
    );
  }

  void _openShop() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PointShopScreen(
          points: widget.points, redeem: widget.redeem, coupons: widget.coupons,
          useCoupon: widget.useCoupon, goPointsHub: widget.goPointsHub,
        )),
      );

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        controller: search,
        onChanged: (_) => setState(() {}),
        style: AppType.body.copyWith(fontSize: 13),
        decoration: const InputDecoration(
          hintText: '어떤 미션을 찾으세요?',
          prefixIcon: Icon(Icons.search_rounded, size: 19, color: AppColors.faint),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  /// 출석 밖의 기본 적립(광고·프로필·친구 추천 등). 미션 탭 아래 한 줄로 남긴다. (.bridge)
  Widget _dailyBenefits() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.surface),
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
          borderRadius: BorderRadius.circular(AppRadius.surface),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              const IconTile(icon: 'gift', bg: Color(0xFFFBF5E6), fg: Color(0xFFD99A00)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('매일의 혜택', style: AppType.body.copyWith(fontWeight: AppType.w700)),
                  Text('광고 보기 · 프로필 완성 · 친구 추천 포인트',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.meta.copyWith(fontWeight: AppType.w600)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
            ]),
          ),
        ),
      ),
    );
  }

  // ── 공동구매 ────────────────────────────────────────────────────────────

  List<Widget> _gonguSections() {
    final items = LocalGonguRepository().fetchItems();
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 14, 4),
        child: Row(children: [
          Expanded(child: Text('모집 인원이 늘수록 보상이 커져요', style: AppType.meta.copyWith(fontWeight: AppType.w500))),
          TextLink(label: '이용 안내', onTap: _openGonguGuide),
        ]),
      ),
      SecCard(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 16, mainAxisExtent: 262,
          ),
          itemBuilder: (_, i) => _GonguCard(
            g: items[i],
            tone: _gpTones[i % _gpTones.length],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GonguDetailScreen(g: items[i], earn: widget.earn, isClaimed: widget.isClaimed)),
            ),
          ),
        ),
      ),
    ];
  }

  /// 공동구매 카드 바탕색 (시안 `GP[].bg/fg`)
  static const _gpTones = [
    (Color(0xFFEAF4F4), Color(0xFF1D7E7E)),
    (Color(0xFFFFF1DC), Color(0xFFB26A00)),
    (Color(0xFFF1EEFF), Color(0xFF5B4BE0)),
    (Color(0xFFFFF0E3), Color(0xFFDA7419)),
  ];

  /// 공동구매 안내 — 기존 공동구매 화면(설명 + 목록)으로 간다.
  void _openGonguGuide() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GonguScreen(earn: widget.earn, isClaimed: widget.isClaimed)),
      );

  /// 브랜드·가게 제휴 문의 (.inq)
  Widget _inquiry() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: InkWell(
        onTap: _openBrandHub,
        child: SizedBox(
          height: 52,
          child: Row(children: [
            Expanded(child: Text('브랜드·가게 제휴 문의', style: AppType.meta.copyWith(fontWeight: AppType.w700))),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.sub),
          ]),
        ),
      ),
    );
  }
}

/// 공동구매 카드 (.gp — 위 그림 칸, 아래 할인율·가격·모집 막대)
class _GonguCard extends StatelessWidget {
  final Gongu g;
  final (Color, Color) tone;
  final VoidCallback onTap;
  const _GonguCard({required this.g, required this.tone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final off = g.list <= 0 ? 0 : ((1 - g.price / g.list) * 100).round();
    final ratio = g.target <= 0 ? 0.0 : (g.joined / g.target).clamp(0, 1).toDouble();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(color: tone.$1, borderRadius: BorderRadius.circular(16)),
            child: Stack(children: [
              Center(child: Text(g.icon, style: const TextStyle(fontSize: 42))),
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(5)),
                  child: Text(g.brand, style: AppType.caption.copyWith(fontSize: 10, fontWeight: AppType.w600, color: AppColors.ink2)),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Text(g.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.body.copyWith(fontSize: 13, fontWeight: AppType.w600)),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(children: [
            if (off > 0) TextSpan(text: '$off% ', style: const TextStyle(color: AppColors.red)),
            TextSpan(text: nf(g.price)),
            TextSpan(
              text: ' ${nf(g.list)}',
              style: const TextStyle(fontSize: 11, fontWeight: AppType.w400, color: AppColors.faint, decoration: TextDecoration.lineThrough),
            ),
          ]),
          style: const TextStyle(fontSize: 15, fontWeight: AppType.w700, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 3,
            backgroundColor: AppColors.soft2,
            valueColor: const AlwaysStoppedAnimation(AppColors.ink),
          ),
        ),
        const SizedBox(height: 5),
        Text('${g.joined}/${g.target}명 모집', style: AppType.caption.copyWith(fontSize: 11)),
      ]),
    );
  }
}
