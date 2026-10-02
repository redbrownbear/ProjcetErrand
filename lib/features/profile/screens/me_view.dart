import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/services/auth_service.dart';
import '../../benefits/models/coupon.dart';
import '../../benefits/screens/my_coupons_screen.dart';
import '../../partner/screens/brand_hub_screen.dart';
import '../models/trust_level.dart';
import '../models/user_profile.dart';
import '../widgets/me_cards.dart';
import '../widgets/nickname_sheet.dart';
import '../widgets/trust_sheet.dart';

/// 마이 화면. 프로필 카드 → 숫자 세 칸 → 내 지갑 → 메뉴 묶음 순서다.
///
/// 여기 보이는 숫자는 **전부 실제 기록에서 온다.** 프로필은 `users/{uid}` 문서,
/// 활동 숫자는 내 거래·부탁 기록을 센 [ProfileStats]다.
/// 아직 기능이 없는 항목(후기 평점·정산)은 그럴듯한 숫자를 지어내지 않고 '—'와 '준비 중'으로 둔다.
class MeView extends StatelessWidget {
  /// 서버에서 읽은 내 프로필. 로그인 전이거나 아직 못 읽었으면 null.
  final UserProfile? profile;
  final ProfileStats stats;
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
    if (!isLoggedIn) return _loggedOut();

    final liveCoupons = coupons.where((c) => !c.used).length;
    final nickname = profile?.nickname ?? UserProfile.defaultNickname;
    final email = profile?.email ?? '';

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (serverIssue != null) _ServerBanner(issue: serverIssue!),
        ProfileCard(
          nickname: nickname,
          detail: [?profile?.region, if (email.isNotEmpty) email].join(' · '),
          trust: trust,
          syncing: syncing,
          onEdit: () => _editNickname(context, nickname),
          onOpenTrust: () => showTrustSheet(context, trust),
        ),
        StatsCard(
          completed: stats.completed,
          requested: stats.requested,
          rating: stats.rating,
          onOpenActivity: onOpenActivity,
          onOpenMine: onOpenMine,
        ),
        WalletCard(
          payBalance: payBalance,
          monthEarned: stats.monthEarnedCash,
          points: points,
          onOpenPay: goPay,
          onOpenAttendance: goAttendance,
        ),
        if (freeLeft > 0) _FreeFeeBanner(left: freeLeft),
        const SizedBox(height: 18),
        MenuGroup(
          title: '나의 활동',
          rows: [
            MenuRow('진행 중인 부탁', trailing: '${stats.active}건', onTap: onOpenActivity),
            MenuRow('지원한 부탁', trailing: '${stats.applied}건', onTap: onOpenApplied),
            MenuRow('내가 올린 부탁', trailing: '${stats.requested}건', onTap: onOpenMine),
            MenuRow('관심 저장', trailing: '${stats.saved}건', onTap: onOpenSaved),
            const MenuRow('내 후기', trailing: '준비 중'),
          ],
        ),
        MenuGroup(
          title: '돈 · 혜택',
          rows: [
            MenuRow('겸사페이 · 정산 내역', onTap: goPay),
            MenuRow('내 쿠폰', trailing: '$liveCoupons장', onTap: () => _openCoupons(context)),
            MenuRow('매일의 혜택', onTap: goPointsHub),
          ],
        ),
        MenuGroup(
          title: '계정',
          rows: [
            MenuRow('신뢰 레벨', trailing: 'Lv.${trust.level}', onTap: () => showTrustSheet(context, trust)),
            MenuRow('본인인증', trailing: (profile?.verified ?? false) ? '완료' : '미완료'),
            const MenuRow('설정', trailing: '준비 중'),
            MenuRow('로그아웃', onTap: () => AuthService().signOut(), danger: true),
          ],
        ),
        Center(
          child: TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandHubScreen())),
            child: Text(
              '사장님이신가요? 가게·브랜드 제휴 문의 ›',
              style: AppType.meta.copyWith(fontSize: 12.5, fontWeight: AppType.w600, color: AppColors.faint),
            ),
          ),
        ),
      ],
    );
  }

  Widget _loggedOut() {
    return ListView(
      children: [
        if (serverIssue != null) _ServerBanner(issue: serverIssue!),
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

  /// 닉네임은 목록·상세에 그대로 보이는 이름이다.
  Future<void> _editNickname(BuildContext context, String current) async {
    final next = await showNicknameSheet(context, current);
    if (next != null && next != current) await onRename(next);
  }

  void _openCoupons(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MyCouponsScreen(coupons: coupons, useCoupon: useCoupon, goPointsHub: goPointsHub),
    ),
  );
}

/// 서버에 못 붙은 이유를 숨기지 않고 보여 준다.
/// 이 상태에서는 저장한 내용이 이 기기에만 남으므로 사용자가 알고 있어야 한다.
class _ServerBanner extends StatelessWidget {
  final String issue;
  const _ServerBanner({required this.issue});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(AppRadius.tile)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '서버에 연결되지 않았어요',
                  style: AppType.meta.copyWith(fontWeight: AppType.w600, color: AppColors.red),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '지금 저장하는 내용은 이 기기에만 남아요.\n$issue',
                    style: AppType.caption.copyWith(color: AppColors.red, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 신규 첫 3거래 수수료 무료 안내
class _FreeFeeBanner extends StatelessWidget {
  final int left;
  const _FreeFeeBanner({required this.left});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_outlined, size: 18, color: AppColors.yellowInk),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '수수료 무료 $left회 남음',
                    style: const TextStyle(fontWeight: AppType.w700, color: AppColors.ink),
                  ),
                  const TextSpan(text: '  첫 3거래 0% · 이후 2%'),
                ],
              ),
              style: AppType.meta.copyWith(fontSize: 12.5, color: AppColors.yellowInk),
            ),
          ),
        ],
      ),
    );
  }
}
