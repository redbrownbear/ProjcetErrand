import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/navigation/screen_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_icon.dart';
import '../models/home_ad.dart';

/// 홈 광고 배너 (시안 v33 `.bn`).
///
/// 옅은 살구색 띠에 흰 아이콘 타일 + 세 줄 문구, 오른쪽 아래에 '1 / 3' 쪽수.
/// 몇 초마다 다음 장으로 넘어가고, 손으로 넘길 수도 있다.
class AdBanner extends StatefulWidget {
  final List<HomeAd> ads;
  final void Function(ScreenRoute) onTap;
  const AdBanner({super.key, required this.ads, required this.onTap});
  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  final controller = PageController();
  int idx = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 4200), (_) {
      if (!mounted || !controller.hasClients || widget.ads.length < 2) return;
      controller.animateToPage(
        (idx + 1) % widget.ads.length,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ads.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      height: 89,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: widget.ads.length,
            onPageChanged: (i) => setState(() => idx = i),
            itemBuilder: (context, i) {
              final a = widget.ads[i];
              return InkWell(
                onTap: () => widget.onTap(a.nav),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1, -0.6),
                      end: Alignment(1, 0.6),
                      colors: [Color(0xFFFFF6EC), Color(0xFFFDF1E6)],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(13)),
                        child: Icon(AppIcon.data(a.icon), size: 22, color: AppColors.orange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  a.tag,
                                  style: AppType.caption.copyWith(
                                    fontSize: 11.5,
                                    fontWeight: AppType.w600,
                                    color: AppColors.newsPeachInk,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0x0F000000),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('광고', style: AppType.caption.copyWith(fontSize: 9.5, fontWeight: AppType.w600)),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                '${a.t1} ${a.t2}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.body.copyWith(fontSize: 14.5, fontWeight: AppType.w700),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                a.cta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.caption.copyWith(fontSize: 11.5, fontWeight: AppType.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(color: const Color(0x59191F28), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${idx + 1} / ${widget.ads.length}',
                  style: AppType.caption.copyWith(fontSize: 10.5, fontWeight: AppType.w600, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
