import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/services/auth_service.dart';
import '../../benefits/models/coupon.dart';
import '../../benefits/screens/my_coupons_screen.dart';
import '../../partner/screens/brand_hub_screen.dart';
import '../models/trust_level.dart';
import '../models/user_profile.dart';

/// 마이 화면 (시안 v33 `#myRoot`).
///
/// 프로필 카드 → 숫자 세 칸 → 내 지갑 → 메뉴 묶음 순서다.
///
/// 여기 보이는 숫자는 **전부 실제 기록에서 온다.** 프로필은 `users/{uid}` 문서,
/// 활동 숫자는 내 거래·부탁 기록을 센 [ProfileStats]다.
/// 아직 기능이 없는 항목(후기 평점·응답률·정산)은 그럴듯한 숫자를 지어내지 않고
/// '—'와 '준비 중'으로 둔다. 가짜 숫자는 진짜 값이 들어오는 날 사용자가 먼저 눈치챈다.
///
/// 시안의 지갑 카드는 원과 포인트를 더해 '모은 돈'으로 보여 주지만, 앱에서는
/// 겸사페이(원)와 리워드 포인트(P)를 섞지 않는다는 원칙이 있어 따로 적는다.
class MeView extends StatelessWidget {
  /// 서버에서 읽은 내 프로필. 로그인 전이거나 아직 못 읽었으면 null.
  final UserProfile? profile;

  /// 내 기록에서 센 활동 숫자
  final ProfileStats stats;

  /// 신뢰 레벨 (셸이 같은 기록으로 계산한다)
  final TrustLevel trust;

  /// 리워드 포인트(P)와 겸사페이 잔액(원). 서로 다른 값이다.
  final int points;
  final int payBalance;

  final List<Coupon> coupons;
  final void Function(int id) useCoupon;
  final VoidCallback goPointsHub;
  final VoidCallback goPay;

  /// 출석 · 겸사페이 내역
  final VoidCallback goAttendance;

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
    required this.trust,
    required this.points,
    required this.payBalance,
    required this.coupons,
    required this.useCoupon,
    required this.goPointsHub,
    required this.goPay,
    required this.goAttendance,
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
    final region = profile?.region;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (serverIssue != null) _serverBanner(serverIssue!),

        // ── 프로필 (.prof) ─────────────────────────────────────────────
        _card(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.person_outline_rounded, size: 28, color: AppColors.sub),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.section.copyWith(fontSize: 18)),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    [?region, if (email.isNotEmpty) email].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.meta.copyWith(fontSize: 12.5, fontWeight: AppType.w600),
                  ),
                ),
                InkWell(
                  onTap: () => _openTrust(context),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: '신뢰 Lv.${trust.level} ${trust.name}'),
                        TextSpan(text: ' · ${trust.score}점', style: const TextStyle(fontWeight: AppType.w700)),
                      ]),
                      style: AppType.meta.copyWith(fontWeight: AppType.w600, color: AppColors.green),
                    ),
                  ),
                ),
              ]),
            ),
            if (syncing)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.faint)),
              ),
            _softButton('편집', () => _editNickname(context, nickname)),
          ]),
        ),

        // ── 숫자 세 칸 (.stats) ────────────────────────────────────────
        _card(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(children: [
            _stat('${stats.completed}', '활동', onOpenActivity),
            _stat('${stats.requested}', '부탁', onOpenMine),
            _stat(stats.rating == null ? '—' : stats.rating!.toStringAsFixed(1), '리뷰', null, star: stats.rating != null),
          ]),
        ),

        // ── 내 지갑 (.mw) ──────────────────────────────────────────────
        _card(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(
              onTap: goPay,
              child: Row(children: [
                Expanded(child: Text('내 지갑', style: AppType.body.copyWith(fontWeight: AppType.w700))),
                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.faint),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('겸사페이 잔액', style: AppType.meta.copyWith(fontSize: 12.5)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: nf(payBalance)),
                  const TextSpan(text: '원', style: TextStyle(fontSize: 19)),
                ]),
                style: const TextStyle(fontSize: 30, fontWeight: AppType.w700, color: AppColors.ink, letterSpacing: -1.35),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(spacing: 14, runSpacing: 4, children: [
                _split(AppColors.ink, '이번 달 사례비', won(stats.monthEarnedCash)),
                _split(AppColors.yellow, '포인트', '${nf(points)}P'),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: _bigButton('출금·충전', goPay, primary: true),
              ),
              const SizedBox(width: 8),
              Expanded(child: _bigButton('내역·출석', goAttendance)),
            ]),
          ]),
        ),

        if (freeLeft > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(AppRadius.card)),
            child: Row(children: [
              const Icon(Icons.auto_awesome_outlined, size: 18, color: AppColors.yellowInk),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '수수료 무료 $freeLeft회 남음', style: const TextStyle(fontWeight: AppType.w700, color: AppColors.ink)),
                    const TextSpan(text: '  첫 3거래 0% · 이후 2%'),
                  ]),
                  style: AppType.meta.copyWith(fontSize: 12.5, color: AppColors.yellowInk),
                ),
              ),
            ]),
          ),

        // ── 메뉴 묶음 (.mg) ────────────────────────────────────────────
        const SizedBox(height: 18),
        _group('나의 활동', [
          _row('진행 중인 부탁', '${stats.active}건', onOpenActivity),
          _row('지원한 부탁', '${stats.applied}건', onOpenApplied),
          _row('내가 올린 부탁', '${stats.requested}건', onOpenMine),
          _row('관심 저장', '${stats.saved}건', onOpenSaved),
          _row('내 후기', '준비 중', null),
        ]),
        _group('돈 · 혜택', [
          _row('겸사페이 · 정산 내역', '', goPay),
          _row('내 쿠폰', '$liveCoupons장', () => _openCoupons(context)),
          _row('매일의 혜택', '', goPointsHub),
        ]),
        _group('계정', [
          _row('신뢰 레벨', 'Lv.${trust.level}', () => _openTrust(context)),
          _row('본인인증', (profile?.verified ?? false) ? '완료' : '미완료', null),
          _row('설정', '준비 중', null),
          _row('로그아웃', '', () => AuthService().signOut(), danger: true),
        ]),

        Center(
          child: TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandHubScreen())),
            child: Text('사장님이신가요? 가게·브랜드 제휴 문의 ›',
                style: AppType.meta.copyWith(fontSize: 12.5, fontWeight: AppType.w600, color: AppColors.faint)),
          ),
        ),
      ],
    );
  }

  // ── 조각 ───────────────────────────────────────────────────────────────

  Widget _loggedOut(BuildContext context) {
    return ListView(
      children: [
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
            child: Text('미션·공구 둘러보기 ›', style: AppType.meta.copyWith(fontWeight: AppType.w600)),
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child, required EdgeInsets margin, required EdgeInsets padding}) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(22)),
      child: child,
    );
  }

  /// 서버에 못 붙은 이유를 숨기지 않고 보여준다. 이 상태에서는 저장한 내용이
  /// 이 기기에만 남으므로, 사용자가 알고 있어야 한다.
  Widget _serverBanner(String issue) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
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

  /// 신뢰 레벨 안내. 계산 근거를 [TrustLevel.rule]로 그대로 보여준다 —
  /// 왜 올랐는지 모르는 숫자는 신뢰를 만드는 게 아니라 의심을 만든다.
  void _openTrust(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.surface))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: trust.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.emblem),
                ),
                child: Text('Lv.${trust.level}', style: AppType.price.copyWith(fontSize: 14, color: trust.color)),
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
                  minHeight: 6,
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
              padding: const EdgeInsets.only(top: 12),
              child: Text(TrustLevel.rule, style: AppType.caption.copyWith(height: 1.6)),
            ),
          ]),
        ),
      ),
    );
  }

  /// 닉네임 변경 시트. 목록·상세에 이 이름으로 보이므로 화면 어디서든 같은 곳을 고친다.
  Future<void> _editNickname(BuildContext context, String current) async {
    final next = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.surface))),
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

  /// 회색 작은 버튼 (.pe — 편집)
  Widget _softButton(String label, VoidCallback onTap) {
    return Material(
      color: AppColors.page,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Text(label, style: AppType.meta.copyWith(fontSize: 12.5, fontWeight: AppType.w700, color: AppColors.ink)),
        ),
      ),
    );
  }

  /// 지갑 버튼 (.mw-a — 노란 주 버튼 / 회색 보조 버튼)
  Widget _bigButton(String label, VoidCallback onTap, {bool primary = false}) {
    return Material(
      color: primary ? AppColors.yellow : AppColors.page,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(label,
                style: AppType.button.copyWith(fontWeight: primary ? AppType.w700 : AppType.w600, color: AppColors.ink)),
          ),
        ),
      ),
    );
  }

  /// 지갑의 작은 범례 (.mw-split)
  Widget _split(Color dot, String label, String value) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 5),
      Text('$label ', style: AppType.meta.copyWith(fontSize: 12.5)),
      Text(value, style: AppType.meta.copyWith(fontSize: 12.5, fontWeight: AppType.w700, color: AppColors.ink)),
    ]);
  }

  Widget _stat(String v, String l, VoidCallback? onTap, {bool star = false}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(children: [
          Text.rich(
            TextSpan(children: [
              if (star) const TextSpan(text: '★', style: TextStyle(color: Color(0xFFFFB800))),
              TextSpan(text: v),
            ]),
            style: const TextStyle(fontSize: 19, fontWeight: AppType.w700, color: AppColors.ink, height: 1.5),
          ),
          Text(l, style: AppType.meta.copyWith(fontWeight: AppType.w700)),
        ]),
      ),
    );
  }

  /// 메뉴 묶음 (.mg — 흰 카드 안 작은 제목 + 50px 행)
  Widget _group(String title, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Text(title, style: AppType.meta.copyWith(fontSize: 12.5, fontWeight: AppType.w600)),
        ),
        ...rows,
      ]),
    );
  }

  Widget _row(String label, String trailing, VoidCallback? onTap, {bool danger = false}) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 50,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
          child: Row(children: [
            Expanded(
              child: Text(label,
                  style: AppType.body.copyWith(fontSize: 15, fontWeight: AppType.w500, color: danger ? AppColors.red : AppColors.ink)),
            ),
            if (trailing.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(trailing, style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w500)),
              ),
            if (!danger) Icon(Icons.chevron_right_rounded, size: 18, color: onTap == null ? AppColors.line : AppColors.faint),
          ]),
        ),
      ),
    );
  }
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
