import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/services/auth_service.dart';
import '../../benefits/models/coupon.dart';
import '../../benefits/screens/my_coupons_screen.dart';
import '../models/trust_level.dart';
import '../models/user_profile.dart';

/// 내 정보 화면.
///
/// 여기 보이는 숫자는 **전부 실제 기록에서 온다.** 프로필은 `users/{uid}` 문서,
/// 활동 숫자는 내 거래·부탁 기록을 센 [ProfileStats]다.
/// 아직 기능이 없는 항목(후기 평점·응답률·정산)은 그럴듯한 숫자를 지어내지 않고
/// '—'와 '준비 중'으로 둔다. 가짜 숫자는 진짜 값이 들어오는 날 사용자가 먼저 눈치챈다.
class MeView extends StatelessWidget {
  /// 서버에서 읽은 내 프로필. 로그인 전이거나 아직 못 읽었으면 null.
  final UserProfile? profile;

  /// 내 기록에서 센 활동 숫자
  final ProfileStats stats;

  final List<Coupon> coupons;
  final void Function(int id) useCoupon;
  final VoidCallback goPointsHub;

  /// 수수료 무료 남은 횟수
  final int freeLeft;

  final bool isLoggedIn;
  final VoidCallback onLogin;
  final VoidCallback onOpenSaved, onOpenApplied, onOpenMine, onOpenActivity;

  /// 닉네임 변경. 계정 표시 이름과 프로필 문서를 같이 맞춘다.
  final Future<void> Function(String) onRename;

  /// 서버에 붙지 못한 사유. null이면 정상 연결.
  final String? serverIssue;

  /// 서버 자료를 읽어오는 중
  final bool syncing;

  const MeView({
    super.key,
    required this.profile,
    required this.stats,
    required this.coupons,
    required this.useCoupon,
    required this.goPointsHub,
    required this.freeLeft,
    required this.isLoggedIn,
    required this.onLogin,
    required this.onOpenSaved,
    required this.onOpenApplied,
    required this.onOpenMine,
    required this.onOpenActivity,
    required this.onRename,
    this.serverIssue,
    this.syncing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) return _loggedOut(context);

    final liveCoupons = coupons.where((c) => !c.used).length;
    final nickname = profile?.nickname ?? UserProfile.defaultNickname;
    final email = profile?.email ?? '';

    return ListView(
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          child: Text('내 정보', style: AppType.tabTitle),
        ),

        // ── 프로필 ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: Row(children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.page, shape: BoxShape.circle),
              child: const Icon(Icons.person_outline_rounded, size: 30, color: Color(0xFF6F7781)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.section.copyWith(fontSize: 17, fontWeight: AppType.w600)),
                    ),
                    InkWell(
                      onTap: () => _editNickname(context, nickname),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(6, 4, 4, 4),
                        child: Icon(Icons.edit_outlined, size: 16, color: AppColors.faint),
                      ),
                    ),
                  ]),
                  if (email.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(email, style: AppType.meta),
                    ),
                  if (profile?.region != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('활동 지역 ${profile!.region}', style: AppType.caption),
                    ),
                ],
              ),
            ),
            if (syncing)
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.faint)),
          ]),
        ),

        if (serverIssue != null) _serverBanner(serverIssue!),

        _trustCard(),

        // ── 지갑 (.profile-wallet) ─────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            _wallet('내 포인트', nf(profile?.points ?? 0), 'P', goPointsHub),
            Container(width: 1, height: 44, color: const Color(0xFFE5E9EE)),
            _wallet('내 쿠폰', '$liveCoupons', '장', () => _openCoupons(context)),
          ]),
        ),

        if (freeLeft > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(22, 12, 22, 0),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(AppRadius.tile)),
            child: Row(children: [
              const Icon(Icons.auto_awesome_outlined, size: 18, color: AppColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('수수료 무료 $freeLeft회 남음',
                      style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w600, color: Colors.white)),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('신규 첫 3거래 수수료 0% · 4번째부터 기본 2%',
                        style: AppType.caption.copyWith(color: AppColors.onDarkSub)),
                  ),
                ]),
              ),
            ]),
          ),

        // ── 활동 요약 ──────────────────────────────────────────────────
        const SectionHeader(title: '나의 활동'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(children: [
            Expanded(child: _tile('도와준 횟수', '${stats.helped}', '회', AppColors.greenSoft, AppColors.green, 'handshake')),
            const SizedBox(width: 10),
            Expanded(child: _tile('부탁한 횟수', '${stats.requested}', '회', AppColors.yellowSoft, AppColors.yellowDeep, 'clipboard')),
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(children: [
            _stat('${stats.completed}회', '거래 완료'),
            _statDivider(),
            _stat(stats.responseRate == null ? '—' : '${stats.responseRate}%', '응답률'),
            _statDivider(),
            _stat(stats.rating == null ? '—' : '★ ${stats.rating!.toStringAsFixed(1)}', '후기 평점'),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
          child: Text('응답률과 후기 평점은 후기 기능이 열린 뒤에 쌓여요', style: AppType.caption),
        ),

        // ── 수익 ──────────────────────────────────────────────────────
        const SectionHeader(title: '수익'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(AppRadius.tile)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('이번 달 받은 사례비', style: AppType.caption.copyWith(color: AppColors.onDarkSub)),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(won(stats.monthEarnedCash),
                        style: AppType.price.copyWith(fontSize: 18, color: AppColors.gold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('누적 ${won(stats.earnedCash)}', style: AppType.caption.copyWith(color: AppColors.onDarkFaint)),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('보유 포인트', style: AppType.caption),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${nf(profile?.points ?? 0)}P', style: AppType.price.copyWith(fontSize: 18)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('1P = 1원 기준', style: AppType.caption),
                  ),
                ]),
              ),
            ),
          ]),
        ),

        // ── 활동 기록 ──────────────────────────────────────────────────
        const SectionHeader(title: '활동 기록'),
        _row('clipboard', '진행 중인 부탁', '${stats.active}건', onOpenActivity),
        _row('handshake', '내가 지원한 부탁', '${stats.applied}건', onOpenApplied),
        _row('bag', '내가 올린 부탁', '${stats.requested}건', onOpenMine),
        _row('bookmark', '관심 저장', '${stats.saved}건', onOpenSaved),
        _row('gift', '매일의 혜택', '', goPointsHub),
        _row('ticket', '내 쿠폰', '$liveCoupons장', () => _openCoupons(context)),
        _row('star', '내 후기', '준비 중', null),
        _row('sparkles', '수익·정산 내역', '준비 중', null),

        // ── 계정 ──────────────────────────────────────────────────────
        const SectionHeader(title: '계정'),
        _row('shield', '본인인증', (profile?.verified ?? false) ? '완료' : '미완료', null),
        _row('globe', '해외 대행 활동', '가능', null),
        _row('settings', '설정', '준비 중', null),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
          child: InkWell(
            onTap: () => AuthService().signOut(),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(children: [
                const Icon(Icons.logout_rounded, size: 19, color: AppColors.red),
                const SizedBox(width: 12),
                Text('로그아웃', style: AppType.body.copyWith(fontWeight: AppType.w600, color: AppColors.red)),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  // ── 조각 ───────────────────────────────────────────────────────────────

  Widget _loggedOut(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 8),
          child: Text('내 정보', style: AppType.tabTitle),
        ),
        if (serverIssue != null) _serverBanner(serverIssue!),
        EmptyState(
          icon: 'user',
          title: '로그인이 필요해요',
          msg: '내 정보와 활동 기록은 로그인한 계정에 저장돼요.\n이 기기에 남겨둔 기록은 로그인할 때 함께 옮겨집니다.',
          action: '로그인',
          onAction: onLogin,
        ),
        Center(
          child: TextButton(
            onPressed: goPointsHub,
            child: Text('매일의 혜택 둘러보기 ›', style: AppType.meta.copyWith(fontWeight: AppType.w600)),
          ),
        ),
      ],
    );
  }

  /// 서버에 못 붙은 이유를 숨기지 않고 보여준다. 이 상태에서는 저장한 내용이
  /// 이 기기에만 남으므로, 사용자가 알고 있어야 한다.
  Widget _serverBanner(String issue) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(AppRadius.tile)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.red),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('서버에 연결되지 않았어요', style: AppType.meta.copyWith(fontWeight: AppType.w600, color: AppColors.red)),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('지금 저장하는 내용은 이 기기에만 남아요.\n$issue',
                  style: AppType.caption.copyWith(color: AppColors.red, height: 1.6)),
            ),
          ]),
        ),
      ]),
    );
  }

  /// 신뢰 레벨. 계산 근거를 [TrustLevel.rule]로 그대로 보여준다 —
  /// 왜 올랐는지 모르는 숫자는 신뢰를 만드는 게 아니라 의심을 만든다.
  Widget _trustCard() {
    final trust = TrustLevel.from(
      completed: stats.completed,
      helped: stats.helped,
      cancelled: stats.cancelled,
      verified: profile?.verified ?? false,
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 14),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: trust.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.emblem),
            ),
            child: Text('Lv.${trust.level}',
                style: AppType.price.copyWith(fontSize: 14, color: trust.color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('신뢰 레벨', style: AppType.caption),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(trust.name, style: AppType.section.copyWith(fontSize: 17, color: trust.color)),
              ),
            ]),
          ),
          Text('${trust.score}점', style: AppType.price.copyWith(fontSize: 15)),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: trust.progress,
              minHeight: 7,
              backgroundColor: AppColors.page,
              valueColor: AlwaysStoppedAnimation(trust.color),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            Expanded(
              child: Text(
                trust.isFresh ? '첫 거래를 마치면 레벨이 올라가요' : trust.nextHint,
                style: AppType.caption.copyWith(fontWeight: AppType.w600, color: trust.color),
              ),
            ),
            if (!trust.isMax)
              Text('Lv.${trust.level + 1} ${TrustLevel.tiers.firstWhere((t) => t.$2 == trust.level + 1).$3}',
                  style: AppType.caption),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(TrustLevel.rule, style: AppType.caption.copyWith(height: 1.6)),
        ),
      ]),
    );
  }

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

  Widget _wallet(String label, String value, String unit, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Column(children: [
            Text(label, style: AppType.meta),
            const SizedBox(height: 9),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: value),
                TextSpan(text: unit, style: AppType.price.copyWith(fontSize: 14, fontWeight: AppType.w400)),
              ]),
              style: AppType.price.copyWith(fontSize: 25),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _tile(String label, String value, String unit, Color bg, Color fg, String icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(AppIcon.data(icon), size: 20, color: fg),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(label, style: AppType.caption.copyWith(fontSize: 12, fontWeight: AppType.w600, color: fg)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: value),
              TextSpan(text: unit, style: AppType.price.copyWith(fontSize: 14, color: fg, fontWeight: AppType.w400)),
            ]),
            style: AppType.price.copyWith(fontSize: 24, color: fg),
          ),
        ),
      ]),
    );
  }

  Widget _row(String icon, String label, String trailing, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(children: [
          Icon(AppIcon.data(icon), size: 20, color: const Color(0xFF717983)),
          const SizedBox(width: 13),
          Expanded(child: Text(label, style: AppType.body.copyWith(color: const Color(0xFF677488)))),
          if (trailing.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(trailing, style: AppType.meta.copyWith(fontWeight: AppType.w500, color: const Color(0xFF6D7684))),
            ),
          Icon(Icons.chevron_right_rounded, size: 17, color: onTap == null ? AppColors.line : AppColors.faint),
        ]),
      ),
    );
  }

  Widget _stat(String v, String l) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(children: [
          Text(v, style: AppType.price.copyWith(fontSize: 16.5)),
          const SizedBox(height: 4),
          Text(l, style: AppType.caption),
        ]),
      ),
    );
  }

  Widget _statDivider() => Container(width: 1, height: 40, color: AppColors.line);
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
