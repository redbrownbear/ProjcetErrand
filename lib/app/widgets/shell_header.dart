import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_icon.dart';

/// 탭 위에 고정된 헤더. 홈 · 마켓은 동네 이름, 다른 탭은 탭 제목을 보여 준다.
/// 오른쪽은 응모권 · 글쓰기 · 알림 (시안 v77).
///
/// 검색 버튼은 없다 — 검색은 홈 바로가기 '전체'에서 한다.
class ShellHeader extends StatelessWidget {
  /// 탭 제목. null이면 홈으로 보고 동네 이름([scope])을 그린다.
  final String? title;
  final String scope;
  final VoidCallback onRegion;
  final VoidCallback onPost;
  final VoidCallback onBell;

  /// 보유 응모권 칩. 누르면 이달의 럭키드로우.
  final int tickets;
  final VoidCallback onTickets;

  /// 알림 아이콘에 빨간 점을 찍을지
  final bool hasNews;

  const ShellHeader({
    super.key,
    required this.title,
    required this.scope,
    required this.onRegion,
    required this.onPost,
    required this.onBell,
    required this.tickets,
    required this.onTickets,
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
          _TicketChip(count: tickets, onTap: onTickets),
          _WriteButton(onTap: onPost),
          _HeaderButton(icon: 'bell', label: '알림', onTap: onBell, dot: hasNews),
        ],
      ),
    );
  }

  Widget _title() => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.tabTitle),
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
              Flexible(
                child: Text(
                  shortRegion(scope),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.body.copyWith(fontSize: 17, fontWeight: AppType.w700, letterSpacing: -0.3),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.sub),
            ],
          ),
        ),
      ),
    );
  }
}

/// 보유 응모권 (v77 `.ld-hbtn`)
class _TicketChip extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _TicketChip({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '응모권 $count장 · 럭키드로우',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 30,
          margin: const EdgeInsets.only(right: 2),
          padding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
          decoration: BoxDecoration(
            color: AppColors.yellowSoft,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.yellowLine),
          ),
          child: Row(
            children: [
              const Icon(Icons.confirmation_number_outlined, size: 16, color: AppColors.yellowDeep),
              const SizedBox(width: 4),
              Text(
                '$count장',
                style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w700, color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// '글쓰기' — 가는 김에 · 제안 · 부탁 · 해외 부탁 · 중고 · 커뮤니티 중에서 고른다
class _WriteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _WriteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        child: Row(
          children: [
            Icon(AppIcon.data('pencil'), size: 17, color: AppColors.ink),
            const SizedBox(width: 3),
            Text('글쓰기', style: AppType.button.copyWith(fontWeight: AppType.w700)),
          ],
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
