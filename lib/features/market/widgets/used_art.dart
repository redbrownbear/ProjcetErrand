import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

/// 중고 물건 사진 자리. 실제 사진 업로드가 붙기 전까지 물건 종류별 그림 타일을 쓴다.
class UsedArt extends StatelessWidget {
  final String art;
  final double size;
  final double radius;
  const UsedArt(this.art, {super.key, this.size = 98, this.radius = 14});

  static const _arts = <String, (IconData, Color, Color)>{
    'bike': (Icons.pedal_bike_rounded, Color(0xFFF1E6D8), Color(0xFFE0453A)),
    'washer': (Icons.kitchen_rounded, Color(0xFFE9ECF0), Color(0xFF8A96A6)),
    'lamp': (Icons.light_rounded, Color(0xFFE3E9F0), Color(0xFFE8B931)),
    'chair': (Icons.chair_alt_rounded, Color(0xFFEFE4D8), Color(0xFFA0703F)),
    'shoes': (Icons.ice_skating_outlined, Color(0xFFE6F0E8), Color(0xFF3E8E62)),
    'clothes': (Icons.checkroom_rounded, Color(0xFFF6E8EC), Color(0xFFD06A86)),
    'book': (Icons.menu_book_rounded, Color(0xFFEAEFFA), Color(0xFF4C6CC4)),
    'etc': (Icons.inventory_2_outlined, Color(0xFFF2F4F6), AppColors.sub),
  };

  static const keys = ['etc', 'clothes', 'book', 'shoes', 'chair', 'lamp', 'bike', 'washer'];
  static const labels = ['기타', '옷', '책', '신발', '가구', '조명', '자전거', '가전'];

  @override
  Widget build(BuildContext context) {
    final a = _arts[art] ?? _arts['etc']!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: a.$2, borderRadius: BorderRadius.circular(radius)),
      child: Icon(a.$1, size: size * 0.55, color: a.$3),
    );
  }
}
