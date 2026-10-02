import '../../../core/navigation/screen_route.dart';

/// 홈 광고 배너 한 장.
class HomeAd {
  final String k, tag, t1, t2, cta;

  /// [AppIcon] 이름
  final String icon;
  final ScreenRoute nav;
  const HomeAd({
    required this.k,
    required this.tag,
    required this.t1,
    required this.t2,
    required this.cta,
    required this.icon,
    required this.nav,
  });
}
