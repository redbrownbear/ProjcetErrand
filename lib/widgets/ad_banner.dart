import 'package:flutter/material.dart';

import '../models/home_ad.dart';
import '../models/screen_route.dart';
import '../theme/colors.dart';

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

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(children: [
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: controller,
            itemCount: widget.ads.length,
            onPageChanged: (i) => setState(() => idx = i),
            itemBuilder: (context, i) {
              final a = widget.ads[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: () => widget.onTap(a.nav),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
                    decoration: BoxDecoration(color: a.bg, borderRadius: BorderRadius.circular(18)),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .22), borderRadius: BorderRadius.circular(7)),
                              child: Text(a.tag, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text('${a.t1}\n${a.t2}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, height: 1.32)),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 11),
                              child: Text('${a.cta} ›', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                      Text(a.emoji, style: const TextStyle(fontSize: 50)),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < widget.ads.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: i == idx ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(color: i == idx ? AppColors.ink : AppColors.line, borderRadius: BorderRadius.circular(99)),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}
