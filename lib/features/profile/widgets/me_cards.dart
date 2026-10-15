import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/trust_level.dart';

/// 마이 화면의 흰 카드 틀
class MeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;
  const MeCard({super.key, required this.child, required this.margin, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(22)),
      child: child,
    );
  }
}

/// 프로필 카드 — 닉네임 · 지역/이메일 · 신뢰 레벨 한 줄 · 편집
class ProfileCard extends StatelessWidget {
  final String nickname;

  /// 닉네임 아래 한 줄 (지역 · 이메일)
  final String detail;
  final TrustLevel trust;
  final bool syncing;
  final VoidCallback onEdit;
  final VoidCallback onOpenTrust;

  const ProfileCard({
    super.key,
    required this.nickname,
    required this.detail,
    required this.trust,
    required this.syncing,
    required this.onEdit,
    required this.onOpenTrust,
  });

  @override
  Widget build(BuildContext context) {
    return MeCard(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.person_outline_rounded, size: 28, color: AppColors.sub),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nickname, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.section.copyWith(fontSize: 18)),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.meta.copyWith(fontSize: 12.5, fontWeight: AppType.w600),
                  ),
                ),
                InkWell(
                  onTap: onOpenTrust,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '신뢰 Lv.${trust.level} ${trust.name}'),
                          TextSpan(
                            text: ' · ${trust.score}점',
                            style: const TextStyle(fontWeight: AppType.w700),
                          ),
                        ],
                      ),
                      style: AppType.meta.copyWith(fontWeight: AppType.w600, color: AppColors.green),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (syncing)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.faint)),
            ),
          _EditButton(onTap: onEdit),
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
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
          child: Text(
            '편집',
            style: AppType.meta.copyWith(fontSize: 12.5, fontWeight: AppType.w700, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}

/// 숫자 세 칸 (활동 · 부탁 · 리뷰). 값이 null이면 '—'로 그린다.
class StatsCard extends StatelessWidget {
  final int completed;
  final int requested;
  final double? rating;
  final VoidCallback onOpenActivity;
  final VoidCallback onOpenMine;

  const StatsCard({
    super.key,
    required this.completed,
    required this.requested,
    required this.rating,
    required this.onOpenActivity,
    required this.onOpenMine,
  });

  @override
  Widget build(BuildContext context) {
    return MeCard(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _stat('$completed', '활동', onOpenActivity),
          _stat('$requested', '부탁', onOpenMine),
          _stat(rating == null ? '—' : rating!.toStringAsFixed(1), '리뷰', null, star: rating != null),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, VoidCallback? onTap, {bool star = false}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Text.rich(
              TextSpan(
                children: [
                  if (star)
                    const TextSpan(
                      text: '★',
                      style: TextStyle(color: Color(0xFFFFB800)),
                    ),
                  TextSpan(text: value),
                ],
              ),
              style: const TextStyle(fontSize: 19, fontWeight: AppType.w700, color: AppColors.ink, height: 1.5),
            ),
            Text(label, style: AppType.meta.copyWith(fontWeight: AppType.w700)),
          ],
        ),
      ),
    );
  }
}

/// 내 지갑 카드.
///
/// 겸사페이(원)와 리워드 포인트(P)는 성격이 달라서 더하지 않고 따로 적는다.
class WalletCard extends StatelessWidget {
  final int payBalance;
  final int monthEarned;
  final int points;
  final VoidCallback onOpenPay;
  final VoidCallback onOpenAttendance;

  const WalletCard({
    super.key,
    required this.payBalance,
    required this.monthEarned,
    required this.points,
    required this.onOpenPay,
    required this.onOpenAttendance,
  });

  @override
  Widget build(BuildContext context) {
    return MeCard(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpenPay,
            child: Row(
              children: [
                Expanded(
                  child: Text('내 지갑', style: AppType.body.copyWith(fontWeight: AppType.w700)),
                ),
                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.faint),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('겸사페이 잔액', style: AppType.meta.copyWith(fontSize: 12.5)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: nf(payBalance)),
                  const TextSpan(text: '원', style: TextStyle(fontSize: 19)),
                ],
              ),
              style: const TextStyle(fontSize: 30, fontWeight: AppType.w700, color: AppColors.ink, letterSpacing: -1.35),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                _legend(AppColors.ink, '이번 달 사례비', won(monthEarned)),
                _legend(AppColors.yellow, '포인트', '${nf(points)}P'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _button('출금·충전', onOpenPay, primary: true)),
              const SizedBox(width: 8),
              Expanded(child: _button('내역·출석', onOpenAttendance)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color dot, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dot, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text('$label ', style: AppType.meta.copyWith(fontSize: 12.5)),
        Text(
          value,
          style: AppType.meta.copyWith(fontSize: 12.5, fontWeight: AppType.w700, color: AppColors.ink),
        ),
      ],
    );
  }

  Widget _button(String label, VoidCallback onTap, {bool primary = false}) {
    return Material(
      color: primary ? AppColors.yellow : AppColors.page,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              label,
              style: AppType.button.copyWith(fontWeight: primary ? AppType.w700 : AppType.w600, color: AppColors.ink),
            ),
          ),
        ),
      ),
    );
  }
}

/// 메뉴 묶음 — 흰 카드 안에 작은 제목과 행들
class MenuGroup extends StatelessWidget {
  final String title;
  final List<MenuRow> rows;
  const MenuGroup({super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(title, style: AppType.meta.copyWith(fontSize: 12.5, fontWeight: AppType.w600)),
          ),
          ...rows,
        ],
      ),
    );
  }
}

/// 메뉴 한 줄. [onTap]이 없으면 아직 준비 중인 항목이다.
class MenuRow extends StatelessWidget {
  final String label;
  final String trailing;
  final VoidCallback? onTap;

  /// 로그아웃처럼 빨갛게 그릴 항목
  final bool danger;
  const MenuRow(this.label, {super.key, this.trailing = '', this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 50,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppType.body.copyWith(
                    fontSize: 15,
                    fontWeight: AppType.w500,
                    color: danger ? AppColors.red : AppColors.ink,
                  ),
                ),
              ),
              if (trailing.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(trailing, style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w500)),
                ),
              if (!danger) Icon(Icons.chevron_right_rounded, size: 18, color: onTap == null ? AppColors.line : AppColors.faint),
            ],
          ),
        ),
      ),
    );
  }
}
