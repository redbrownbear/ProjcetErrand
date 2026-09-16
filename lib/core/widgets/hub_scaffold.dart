import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'app_icon.dart';
import 'screen_frame.dart';

/// 서비스 허브 화면의 공통 뼈대.
///
/// 홈이 모든 컨텐츠를 한 화면에 쌓던 구조를 걷어내면서, 서비스별 컨텐츠는
/// 각자의 허브 화면(동네 부탁 / 해외 부탁 / 단기알바)으로 한 뎁스 내려갔다.
/// 허브마다 헤더·여백·섹션 간격이 제각각이 되지 않도록 이 뼈대를 쓴다.
///
/// ```dart
/// HubScaffold(
///   title: '동네 부탁',
///   subtitle: '가까운 곳에서 하나 더',
///   children: [
///     HubSection(title: '무엇을 부탁하나요', child: ...),
///     HubSection(title: '지금, 내 주변', onAction: goList, child: ...),
///   ],
/// )
/// ```
class HubScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? accent;

  /// 헤더 오른쪽에 붙일 액션 (검색·지도 등)
  final Widget? right;

  /// 섹션 목록. [HubSection]을 쓰면 간격이 자동으로 맞는다.
  final List<Widget> children;

  /// 화면 맨 아래에 고정되는 버튼 영역 (없으면 생략)
  final Widget? bottom;

  const HubScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.accent,
    this.right,
    required this.children,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: title,
      subtitle: subtitle,
      accent: accent,
      right: right,
      onBack: () => Navigator.of(context).pop(),
      child: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 4, bottom: 28),
            children: children,
          ),
        ),
        if (bottom != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: bottom,
          ),
      ]),
    );
  }
}

/// 허브 안의 한 덩어리. 제목 + (부제) + (전체보기) + 본문.
class HubSection extends StatelessWidget {
  final String title;
  final String? sub;

  /// 지정하면 오른쪽에 '전체보기 ›'가 붙는다.
  final VoidCallback? onAction;
  final String actionLabel;
  final Widget child;

  /// 본문 좌우 여백. 가로 스크롤 목록처럼 끝까지 붙여야 하면 false.
  final bool padded;

  const HubSection({
    super.key,
    required this.title,
    this.sub,
    this.onAction,
    this.actionLabel = '전체보기',
    required this.child,
    this.padded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppType.section.copyWith(fontSize: 16)),
                  if (sub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(sub!, style: AppType.meta),
                    ),
                ],
              ),
            ),
            if (onAction != null)
              InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  child: Text('$actionLabel ›', style: AppType.meta),
                ),
              ),
          ]),
        ),
        padded ? Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child) : child,
      ],
    );
  }
}

/// 아직 컨텐츠가 정해지지 않은 자리. 구조를 먼저 잡고 내용을 나중에 채울 때 쓴다.
/// 실제 컨텐츠가 들어오면 이 위젯은 지운다.
class HubPlaceholder extends StatelessWidget {
  final String label;
  const HubPlaceholder({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label — 컨텐츠 준비 중',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12.5, color: AppColors.faint, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 허브에서 다음 뎁스로 내려가는 한 줄 진입점. [icon]은 [AppIcon]의 이름.
class HubRow extends StatelessWidget {
  final String icon;
  final String title;
  final String? sub;
  final String? trailing;
  final VoidCallback onTap;
  const HubRow({super.key, required this.icon, required this.title, this.sub, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(13)),
        child: Row(children: [
          Icon(AppIcon.data(icon), size: 19, color: AppColors.sub),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                if (sub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(sub!, style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(trailing!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.sub)),
            ),
          const Text('›', style: TextStyle(fontSize: 18, color: AppColors.faint)),
        ]),
      ),
    );
  }
}
