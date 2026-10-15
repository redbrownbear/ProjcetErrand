import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/kit.dart';
import '../../auth/services/auth_service.dart';
import '../../benefits/models/coupon.dart';
import '../../benefits/screens/my_coupons_screen.dart';
import '../../lucky/models/tickets.dart';
import '../../partner/screens/brand_hub_screen.dart';
import '../models/trust_level.dart';
import '../models/user_profile.dart';

/// 마이 (시안 v77 `renderMy`).
///
/// 프로필 → 활동 숫자 → 내 지갑 → 내 응모권 → 메뉴 순서다.
/// 여기 보이는 숫자는 **전부 실제 기록에서 온다.** 아직 기능이 없는 항목(후기 평점)은
/// 그럴듯한 숫자를 지어내지 않고 '—'로 둔다.
class MeView extends StatelessWidget {
  final AppNav nav;

  /// 서버에서 읽은 내 프로필. 로그인 전이거나 아직 못 읽었으면 null.
  final UserProfile? profile;
  final ProfileStats stats;
  final TrustLevel trust;
  final String scope;
  final int points;
  final List<Coupon> coupons;
  final void Function(int id) useCoupon;
  final VoidCallback goPointsHub;
  final bool isLoggedIn;
  final VoidCallback onLogin;
  final VoidCallback onOpenSaved, onOpenApplied, onOpenMine, onOpenActivity;
  final VoidCallback onWithdraw, onHistory;

  /// 닉네임 변경. 계정 표시 이름과 프로필 문서를 같이 맞춘다.
  final Future<void> Function(String) onRename;

  /// 서버에 붙지 못한 사유. null이면 정상 연결.
  final String? serverIssue;
  final bool syncing;

  const MeView({
    super.key,
    required this.nav,
    required this.profile,
    required this.stats,
    required this.trust,
    required this.scope,
    required this.points,
    required this.coupons,
    required this.useCoupon,
    required this.goPointsHub,
    required this.isLoggedIn,
    required this.onLogin,
    required this.onOpenSaved,
    required this.onOpenApplied,
    required this.onOpenMine,
    required this.onOpenActivity,
    required this.onWithdraw,
    required this.onHistory,
    required this.onRename,
    this.serverIssue,
    this.syncing = false,
  });

  @override
  Widget build(BuildContext context) {
    final nickname = profile?.nickname ?? UserProfile.defaultNickname;
    final liveCoupons = coupons.where((c) => !c.used).length;
    final total = stats.earnedCash + points;
    return ListenableBuilder(
      listenable: nav.store,
      builder: (context, _) {
        final w = nav.store.wallet;
        final draw = LuckyDraw(DateTime.now());
        return ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            if (serverIssue != null) _serverNotice(serverIssue!),
            // 프로필
            Sec(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.person_outline_rounded, size: 30, color: AppColors.sub),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isLoggedIn ? nickname : '로그인이 필요해요', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: 3),
                    Text('$scope · 가는 길에 작은 도움을 드려요', maxLines: 2, style: const TextStyle(fontSize: 13, color: AppColors.sub, height: 1.4)),
                    const SizedBox(height: 4),
                    Text(
                      syncing ? '내 기록을 불러오는 중…' : '신뢰 Lv.${trust.level} ${trust.name} · ${trust.score}점',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.green),
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isLoggedIn ? () => _editNickname(context, nickname) : onLogin,
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(10)),
                    child: Text(isLoggedIn ? '편집' : '로그인', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
            // 활동 숫자
            Sec(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(children: [
                _stat('${stats.completed + stats.active}', '활동'),
                _stat('${stats.requested}', '부탁'),
                _stat('—', '리뷰', star: true),
              ]),
            ),
            // 내 지갑
            Sec(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  const Expanded(child: Text('내 지갑', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                  GestureDetector(onTap: onHistory, child: const Icon(Icons.chevron_right_rounded, color: AppColors.faint)),
                ]),
                const SizedBox(height: 12),
                const Text('지금까지 모은 돈', style: TextStyle(fontSize: 13, color: AppColors.sub)),
                const SizedBox(height: 4),
                Text.rich(TextSpan(children: [
                  TextSpan(text: nf(total), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
                  const TextSpan(text: '원', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ])),
                const SizedBox(height: 8),
                Row(children: [
                  _dot(AppColors.inkSoft),
                  const Text(' 원 ', style: TextStyle(fontSize: 13, color: AppColors.sub)),
                  Text(won(stats.earnedCash), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 14),
                  _dot(AppColors.yellow),
                  const Text(' 포인트 ', style: TextStyle(fontSize: 13, color: AppColors.sub)),
                  Text('${nf(points)}P', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: BigButton(label: '출금하기', height: 52, onTap: onWithdraw)),
                  const SizedBox(width: 8),
                  Expanded(child: BigButton(label: '내역·출석', height: 52, bg: AppColors.page, fg: AppColors.inkSoft, onTap: onHistory)),
                ]),
              ]),
            ),
            // 내 응모권
            Sec(
              padding: EdgeInsets.zero,
              child: Tap(
                onTap: () => nav.openLucky(context),
                radius: 18,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.confirmation_number_outlined, color: AppColors.yellowInk, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('내 응모권 ${w.have}장', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('${draw.month}월 럭키드로우 · 이번 달 응모 ${w.entered}장', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
                      ]),
                    ),
                    Text('D-${draw.dday}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sub)),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                  ]),
                ),
              ),
            ),
            _menu('나의 활동', [
              ('지원한 부탁', '${stats.applied}건', onOpenApplied),
              ('내가 올린 부탁', '${stats.requested}건', onOpenMine),
              ('진행 중·완료 부탁', '${stats.active}건 진행 중', onOpenActivity),
              ('관심 저장', '${stats.saved}건', onOpenSaved),
              ('이웃에게 직접 부탁', '', nav.openAskForm),
              ('내 제안 · 구매 요청', '${nav.store.myProposals.length + nav.store.joined.length}건', () => nav.openProposalList(context, abroad: false)),
              ('단기알바 지원 내역', '', () => nav.flash('단기알바 지원 내역은 구인업체 연동 후 보여요')),
              ('공동구매 참여 내역', '', () => nav.flash('공동구매 참여 내역은 판매자 연동 후 보여요')),
            ]),
            _menu('돈 · 혜택', [
              ('안전결제 · 정산 내역', '', onHistory),
              ('출금 계좌 관리', '', onWithdraw),
              ('내 쿠폰', '$liveCoupons장', () => _openCoupons(context)),
              ('포인트샵', '${nf(points)}P', goPointsHub),
            ]),
            _menu('안내', [
              ('공지·업데이트', '', () => nav.flash('새 공지가 없어요')),
              ('사장님이신가요? 가게·브랜드 제휴 문의', '', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandHubScreen()))),
              if (isLoggedIn) ('로그아웃', '', () => AuthService().signOut()),
            ]),
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: Text('겸사겸사 · 체험 버전', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.faint)),
            ),
          ],
        );
      },
    );
  }

  Widget _dot(Color c) => Container(width: 8, height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)));

  Widget _stat(String v, String l, {bool star = false}) => Expanded(
        child: Column(children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (star) const Icon(Icons.star_rounded, size: 20, color: AppColors.yellow),
            Text(v, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 2),
          Text(l, style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
        ]),
      );

  Widget _menu(String title, List<(String, String, VoidCallback)> rows) => Sec(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(title, style: const TextStyle(fontSize: 13, color: AppColors.sub)),
          ),
          for (final (label, trailing, onTap) in rows)
            Tap(
              onTap: onTap,
              radius: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(children: [
                  Expanded(
                    child: Text(label, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500, color: label == '로그아웃' ? AppColors.red : AppColors.ink)),
                  ),
                  if (trailing.isNotEmpty) Text(trailing, style: const TextStyle(fontSize: 13, color: AppColors.sub)),
                  const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.faint),
                ]),
              ),
            ),
        ]),
      );

  Widget _serverNotice(String issue) => Container(
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('서버에 연결되지 않았어요', style: AppType.meta.copyWith(fontWeight: AppType.w600, color: AppColors.red)),
          const SizedBox(height: 4),
          Text('지금 저장하는 내용은 이 기기에만 남아요.\n$issue', style: AppType.caption.copyWith(height: 1.5)),
        ]),
      );

  /// 닉네임 변경 시트. 목록·상세에 이 이름으로 보이므로 화면 어디서든 같은 곳을 고친다.
  Future<void> _editNickname(BuildContext context, String current) async {
    final next = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _NicknameSheet(current: current),
    );
    if (next != null && next != current) await onRename(next);
  }

  void _openCoupons(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MyCouponsScreen(coupons: coupons, useCoupon: useCoupon, goPointsHub: goPointsHub),
        ),
      );
}

/// 닉네임 입력 시트. 2~12자만 받는다.
class _NicknameSheet extends StatefulWidget {
  final String current;
  const _NicknameSheet({required this.current});
  @override
  State<_NicknameSheet> createState() => _NicknameSheetState();
}

class _NicknameSheetState extends State<_NicknameSheet> {
  late final TextEditingController ctrl = TextEditingController(text: widget.current);
  String? error;

  static const _min = 2;
  static const _max = 12;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final value = ctrl.text.trim();
    if (value.length < _min || value.length > _max) {
      setState(() => error = '$_min~$_max자로 입력해 주세요');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 키보드가 올라와도 입력창이 가리지 않게 한다
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('닉네임', style: AppType.pageTitle.copyWith(fontSize: 16)),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('부탁 목록과 상세에 이 이름으로 보여요', style: AppType.meta),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextField(
                controller: ctrl,
                autofocus: true,
                maxLength: _max,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (error != null) setState(() => error = null);
                },
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(hintText: '예: 서초동 이웃', errorText: error, counterText: ''),
                style: AppType.body.copyWith(fontSize: 16, fontWeight: AppType.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: _save, child: const Text('저장'))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
