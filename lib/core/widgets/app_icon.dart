import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// 기획 시안 v9의 선형 아이콘 세트(`motion.jsx`의 `<Icon name="…"/>`)를 Flutter로 옮긴 것.
///
/// 시안은 stroke 1.8의 얇은 선 아이콘을 쓴다. Flutter에는 같은 그림이 없으므로
/// 결이 가장 가까운 Material outlined/rounded 아이콘으로 1:1 대응시켰다.
/// 화면 코드에서는 `Icons.*`를 직접 쓰지 말고 이 표의 이름을 쓴다 — 나중에
/// 전용 아이콘 폰트로 갈아끼울 때 이 파일만 고치면 되게 하기 위함이다.
class AppIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  const AppIcon(this.name, {super.key, this.size = 22, this.color});

  static const _map = <String, IconData>{
    'home': Icons.home_outlined,
    'handshake': Icons.handshake_outlined,
    'globe': Icons.public_rounded,
    'clipboard': Icons.assignment_outlined,
    'gift': Icons.card_giftcard_rounded,
    'users': Icons.groups_outlined,
    'cart': Icons.shopping_cart_outlined,
    'bag': Icons.shopping_bag_outlined,
    'box': Icons.inventory_2_outlined,
    'walk': Icons.directions_walk_rounded,
    'plus': Icons.add_rounded,
    'chevron': Icons.chevron_right_rounded,
    'chevronDown': Icons.expand_more_rounded,
    'chevronUp': Icons.expand_less_rounded,
    'arrowRight': Icons.arrow_forward_rounded,
    'arrowLeft': Icons.arrow_back_rounded,
    'pin': Icons.place_outlined,
    'search': Icons.search_rounded,
    'map': Icons.map_outlined,
    'bell': Icons.notifications_none_rounded,
    'bookmark': Icons.bookmark_border_rounded,
    'bookmarkFilled': Icons.bookmark_rounded,
    'ticket': Icons.confirmation_number_outlined,
    'shield': Icons.shield_outlined,
    'user': Icons.person_outline_rounded,
    'settings': Icons.settings_outlined,
    'calendar': Icons.calendar_today_outlined,
    'check': Icons.check_rounded,
    'close': Icons.close_rounded,
    'chat': Icons.chat_bubble_outline_rounded,
    'coffee': Icons.local_cafe_outlined,
    'sparkles': Icons.auto_awesome_outlined,
    'clock': Icons.schedule_rounded,
    'info': Icons.info_outline_rounded,
    'fire': Icons.local_fire_department_outlined,
    'camera': Icons.photo_camera_outlined,
    'truck': Icons.local_shipping_outlined,
    'broom': Icons.cleaning_services_outlined,
    'pet': Icons.pets_outlined,
    'queue': Icons.people_alt_outlined,
    'menu': Icons.menu_rounded,
    'star': Icons.star_rounded,
    'filter': Icons.tune_rounded,
    'logout': Icons.logout_rounded,
  };

  /// 부탁 종류(`CATS`의 키) → 아이콘. 데이터의 이모지는 그대로 두고, 화면에서만 선형으로 그린다.
  static const _cats = <String, String>{
    'line': 'queue',
    'buy': 'bag',
    'pickup': 'box',
    'photo': 'camera',
    'ticket': 'ticket',
    'move': 'truck',
    'clean': 'broom',
    'pet': 'pet',
    'proxy': 'cart',
    'etc': 'sparkles',
  };

  static IconData data(String name) => _map[name] ?? Icons.circle_outlined;
  static IconData cat(String key) => data(_cats[key] ?? 'sparkles');

  @override
  Widget build(BuildContext context) => Icon(data(name), size: size, color: color ?? AppColors.ink);
}

/// 부탁 종류 아이콘 타일. 목록·그리드 어디서나 같은 색 규칙을 쓴다.
class CatEmblem extends StatelessWidget {
  final String cat;
  final double size;
  final double radius;
  final double iconSize;
  const CatEmblem({super.key, required this.cat, this.size = 49, this.radius = 15, this.iconSize = 23});

  @override
  Widget build(BuildContext context) {
    final tone = AppColors.taskIcon[cat] ?? AppColors.taskIconFallback;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(radius)),
      child: Icon(AppIcon.cat(cat), size: iconSize, color: tone.fg),
    );
  }
}
