import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'app_icon.dart';

/// 전체화면 하위 화면 공통 프레임 (뒤로가기 헤더 + 스크롤 바디).
///
/// 기획 시안 v9의 `PageHeader`(`design.css .page-header`) 규격:
/// 흰 바탕 · 아래 1px 경계 · 44px 아이콘 버튼 · 가운데 정렬 제목 · 제목 아래 부제.
class ScreenFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Color? accent;
  final Widget? right;
  final Widget child;
  const ScreenFrame({
    super.key,
    required this.title,
    this.subtitle,
    required this.onBack,
    this.accent,
    this.right,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      // targetSdk 36부터 안드로이드가 화면을 가장자리까지 쓰게 강제한다(edge-to-edge).
      // 그래서 이 뼈대를 쓰는 화면은 전부 상태바·제스처바 밑으로 파고든다.
      // 헤더가 상태바에 가리고, 화면 맨 아래 고정 버튼이 제스처바에 깔린다.
      //
      // 여기 한 곳에서 막으면 [ScreenFrame]을 쓰는 20개 화면이 같이 해결된다.
      // 아래쪽까지 감싸는 이유는, 상세 화면들이 이 안에서 `Positioned(bottom: 0)`으로
      // 참여 버튼을 깔기 때문이다 — 그 0이 제스처바 위가 되어야 누를 수 있다.
      child: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(9, 6, 9, 8),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(bottom: BorderSide(color: Color(0xFFF2F3F5))),
            ),
            child: Column(children: [
              SizedBox(
                height: 44,
                child: Row(children: [
                  IconBtn(icon: 'arrowLeft', label: '뒤로 가기', onTap: onBack),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.pageTitle.copyWith(fontSize: 16, color: accent ?? AppColors.ink),
                    ),
                  ),
                  // 오른쪽 액션이 없어도 제목이 가운데에 오도록 같은 폭을 비워둔다.
                  SizedBox(width: 44, child: Center(child: right)),
                ]),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 1, 20, 4),
                  child: Text(subtitle!, textAlign: TextAlign.center, style: AppType.meta.copyWith(height: 1.5)),
                ),
            ]),
          ),
          Expanded(child: child),
        ]),
      ),
    );
  }
}

/// 44x44 아이콘 버튼 (.icon-button). 헤더 액션은 전부 이걸 쓴다.
class IconBtn extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final double size;
  const IconBtn({super.key, required this.icon, required this.label, required this.onTap, this.color, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(AppIcon.data(icon), size: size, color: color ?? AppColors.ink),
        ),
      ),
    );
  }
}
