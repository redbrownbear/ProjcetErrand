import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/mascot.dart';

/// 화면 아래에 잠깐 뜨는 안내 문구
class ToastBar extends StatelessWidget {
  final String message;
  const ToastBar({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xF2191F28),
          borderRadius: BorderRadius.circular(AppRadius.tile),
          boxShadow: const [BoxShadow(color: Color(0x26191F28), blurRadius: 24, offset: Offset(0, 8))],
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.yellow),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: AppType.meta.copyWith(fontSize: 13, color: Colors.white, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 시작 화면 — 겸이와 한 줄 소개. [visible]이 꺼지면 서서히 사라지고, 누르면 바로 넘어간다.
class SplashOverlay extends StatelessWidget {
  final bool visible;
  final VoidCallback onDismiss;
  const SplashOverlay({super.key, required this.visible, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        child: GestureDetector(onTap: onDismiss, child: const _SplashView()),
      ),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.55, 1],
          colors: [Color(0xFFFFF6D3), Color(0xFFFFFDF5), Colors.white],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Gyeomi(width: 180),
                    const SizedBox(height: 14),
                    Text('겸사겸사', style: AppType.tabTitle.copyWith(fontSize: 30, letterSpacing: -1.5)),
                    const SizedBox(height: 4),
                    Text(
                      '가는 길에, 하나 더',
                      style: AppType.body.copyWith(fontSize: 15, fontWeight: AppType.w700, color: AppColors.heroAccent),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '부탁하고, 도와주고, 함께 버는\n우리 동네 심부름',
                      textAlign: TextAlign.center,
                      style: AppType.body.copyWith(height: 1.6, color: AppColors.sub),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 42,
              child: Text(
                '화면을 누르면 바로 시작해요',
                textAlign: TextAlign.center,
                style: AppType.caption.copyWith(color: AppColors.faint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
