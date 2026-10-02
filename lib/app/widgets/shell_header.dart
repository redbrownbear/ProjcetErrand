import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_icon.dart';

/// 탭 위에 고정된 헤더. 홈은 동네 이름, 다른 탭은 탭 제목을 보여 준다.
/// 오른쪽은 검색(홈만) · 부탁하기 · 알림.
class ShellHeader extends StatelessWidget {
  /// 탭 제목. null이면 홈으로 보고 동네 이름([scope])을 그린다.
  final String? title;
  final String scope;
  final VoidCallback onRegion;
  final VoidCallback onSearch;
  final VoidCallback onPost;
  final VoidCallback onBell;

  /// 알림 아이콘에 빨간 점을 찍을지
  final bool hasNews;

  const ShellHeader({
    super.key,
    required this.title,
    required this.scope,
    required this.onRegion,
    required this.onSearch,
    required this.onPost,
    required this.onBell,
    this.hasNews = false,
  });

  @override
  Widget build(BuildContext context) {
    final home = title == null;
    return Container(
      color: AppColors.page,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
      child: Row(
        children: [
          Expanded(child: home ? _region() : _title()),
          if (home) _HeaderButton(icon: 'search', label: '검색', onTap: onSearch),
          _HeaderButton(icon: 'pencil', label: '부탁하기', onTap: onPost),
          _HeaderButton(icon: 'bell', label: '알림', onTap: onBell, dot: hasNews),
        ],
      ),
    );
  }

  Widget _title() => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: Text(title!, style: AppType.tabTitle),
  );

  Widget _region() {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onRegion,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.place_outlined, size: 19, color: AppColors.ink),
              const SizedBox(width: 4),
              Text(shortRegion(scope), style: AppType.body.copyWith(fontSize: 17, fontWeight: AppType.w700, letterSpacing: -0.3)),
              const SizedBox(width: 2),
              const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.sub),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final String icon, label;
  final VoidCallback onTap;
  final bool dot;
  const _HeaderButton({required this.icon, required this.label, required this.onTap, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(AppIcon.data(icon), size: 22, color: AppColors.ink),
              if (dot)
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.page, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
