import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/app_icon.dart';

/// 하단 1차 메뉴의 탭 (시안 v77). 해외는 하단 탭이 아니라 홈 맨 위 국내/해외 전환으로 옮겼다.
enum ShellTab {
  home('홈', 'home'),
  side('마켓', 'gift'),
  community('커뮤니티', 'users'),
  chat('채팅', 'chat'),
  me('마이', 'user');

  final String label;
  final String icon;
  const ShellTab(this.label, this.icon);

  /// 상단 헤더에 쓰는 제목. 홈 · 마켓은 제목 대신 동네 이름이 나와서 null이다.
  String? get title => switch (this) {
    ShellTab.home || ShellTab.side => null,
    _ => label,
  };
}

/// 하단 1차 메뉴 — 홈 · 마켓 · 커뮤니티 · 채팅 · 마이
class ShellBottomNav extends StatelessWidget {
  final ShellTab current;
  final ValueChanged<ShellTab> onSelect;
  const ShellBottomNav({super.key, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(4, 8, 4, 8 + MediaQuery.paddingOf(context).bottom),
      child: Row(
        children: [
          for (final tab in ShellTab.values)
            Expanded(
              child: InkWell(
                onTap: () => onSelect(tab),
                borderRadius: BorderRadius.circular(12),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: _item(tab)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _item(ShellTab tab) {
    final color = tab == current ? AppColors.navActive : AppColors.navIdle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcon.data(tab.icon), size: 24, color: color),
        const SizedBox(height: 3),
        Text(
          tab.label,
          style: AppType.caption.copyWith(fontSize: 10, fontWeight: AppType.w700, color: color),
        ),
      ],
    );
  }
}
