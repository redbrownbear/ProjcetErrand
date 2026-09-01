import 'package:flutter/material.dart';

import 'screen_route.dart';

class HomeAd {
  final String k, tag, t1, t2, cta, emoji;
  final Color bg;
  final ScreenRoute nav;
  const HomeAd({
    required this.k,
    required this.bg,
    required this.tag,
    required this.t1,
    required this.t2,
    required this.cta,
    required this.emoji,
    required this.nav,
  });
}
