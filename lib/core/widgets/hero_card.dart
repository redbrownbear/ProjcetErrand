import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'app_icon.dart';
import 'bubble_quota.dart';
import 'gyeomi.dart';

/// 탭 맨 위의 겸이 카드.
///
/// 부탁하기 · 돈벌기 · 해외 부탁하기 · 해외 돈벌기가 모두 같은 틀에 문구만 다르다.
/// [blue]면 해외 톤(파란 바탕·파란 버튼)이 된다.
class HeroCard extends StatefulWidget {
  final String sub;
  final String title;
  final String? liveBold;
  final String? liveRest;
  final List<String> floats;
  final String cta;
  final String ctaIcon;
  final VoidCallback onCta;
  final String note;
  final bool blue;
  final bool compact;

  /// 겸이 오른쪽 위 말풍선 (v77 — 이달의 럭키드로우). 이벤트 · 혜택 안내라 [BubbleQuota] 상한 안에서만 보이고,
  /// '이벤트' 표시와 닫기(×)가 붙는다(A24).
  final Widget? bubble;

  const HeroCard({
    super.key,
    required this.sub,
    required this.title,
    this.liveBold,
    this.liveRest,
    required this.floats,
    required this.cta,
    required this.ctaIcon,
    required this.onCta,
    required this.note,
    this.blue = false,
    this.compact = false,
    this.bubble,
  });

  @override
  State<HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<HeroCard> {
  /// 이 카드가 처음 그려질 때 한 번만 정한다(다시 그릴 때마다 상한을 쓰지 않게)
  late bool bubbleOn = widget.bubble != null && BubbleQuota.take();

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final bubble = w.bubble;
    return _HeroBody(
      sub: w.sub,
      title: w.title,
      liveBold: w.liveBold,
      liveRest: w.liveRest,
      floats: w.floats,
      cta: w.cta,
      ctaIcon: w.ctaIcon,
      onCta: w.onCta,
      note: w.note,
      blue: w.blue,
      compact: w.compact,
      bubble: bubbleOn && bubble != null
          ? _PromoBubble(
              onClose: () {
                BubbleQuota.dismiss();
                setState(() => bubbleOn = false);
              },
              child: bubble,
            )
          : null,
    );
  }
}

/// 말풍선에 '이벤트' 표시와 닫기를 붙인다(광고성 안내 구분)
class _PromoBubble extends StatelessWidget {
  final Widget child;
  final VoidCallback onClose;
  const _PromoBubble({required this.child, required this.onClose});

  @override
  Widget build(BuildContext context) {
    // 표시 · 닫기는 말풍선 바깥으로 튀어나오면 눌리지 않아서(터치는 부모 영역 안에서만), 자리를 비워 두고 안에 놓는다
    return Stack(
      children: [
        Padding(padding: const EdgeInsets.only(top: 14, right: 6), child: child),
        Positioned(
          right: 0,
          top: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: AppColors.ink2, borderRadius: BorderRadius.circular(6)),
                child: const Text('이벤트', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 2),
              Semantics(
                button: true,
                label: '말풍선 닫기',
                child: GestureDetector(
                  key: const Key('hero-bubble-close'),
                  onTap: onClose,
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle, border: Border.all(color: AppColors.line)),
                    child: const Icon(Icons.close_rounded, size: 12, color: AppColors.sub),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroBody extends StatelessWidget {
  /// 맨 위 작은 문구
  final String sub;

  /// 제목 두 줄. `**`로 감싼 부분이 강조색이 된다. 예: `'무엇이든 부탁해요\n**가까운 이웃**이 도와드려요'`
  final String title;

  /// 제목 아래 한 줄. 굵은 앞부분과 나머지로 나눈다. 비우면 그리지 않는다.
  final String? liveBold;
  final String? liveRest;

  /// 마스코트 주변에 떠 있는 아이콘 네 개
  final List<String> floats;

  final String cta;
  final String ctaIcon;
  final VoidCallback onCta;
  final String note;
  final bool blue;

  /// 돈벌기처럼 마스코트를 조금 작게 그릴 때
  final bool compact;

  /// 겸이 오른쪽 위 말풍선. 있으면 겸이가 왼쪽으로 비켜 선다.
  final Widget? bubble;

  const _HeroBody({
    required this.sub,
    required this.title,
    this.liveBold,
    this.liveRest,
    required this.floats,
    required this.cta,
    required this.ctaIcon,
    required this.onCta,
    required this.note,
    this.blue = false,
    this.compact = false,
    this.bubble,
  });

  @override
  Widget build(BuildContext context) {
    final accent = blue ? AppColors.blue : AppColors.heroAccent;
    final subColor = blue ? AppColors.blue : AppColors.yellowDeep;
    final artH = compact ? 112.0 : 130.0;
    final mascotW = compact ? 124.0 : 148.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.surface),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.72],
          colors: [blue ? const Color(0xFFEEF4FF) : const Color(0xFFFFFBEA), AppColors.card],
        ),
      ),
      child: Column(
        children: [
          Text(
            sub,
            style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w600, color: subColor),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(children: _spans(title, accent)),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: AppType.w700, color: AppColors.ink, letterSpacing: -0.99, height: 1.35),
          ),
          if (liveBold != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: liveBold,
                            style: const TextStyle(fontWeight: AppType.w600, color: AppColors.ink2),
                          ),
                          if (liveRest != null) TextSpan(text: ' $liveRest'),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.meta.copyWith(color: AppColors.sub),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          if (bubble != null)
            SizedBox(
              height: artH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Transform.translate(offset: const Offset(-40, 0), child: _art(artH, mascotW, accent)),
                    ),
                  ),
                  Positioned(right: -4, top: 2, child: bubble!),
                ],
              ),
            )
          else
            _art(artH, mascotW, accent),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: blue ? const Color(0xB33A7BF5) : const Color(0x99C88C00),
                    blurRadius: 18,
                    spreadRadius: -8,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _ctaButton(),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            note,
            textAlign: TextAlign.center,
            style: AppType.meta.copyWith(color: AppColors.sub),
          ),
        ],
      ),
    );
  }

  /// 겸이와 주변에 떠 있는 아이콘
  Widget _art(double artH, double mascotW, Color accent) {
    return SizedBox(
      width: 220,
      height: artH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: (220 - mascotW) / 2,
            top: 0,
            child: Gyeomi(width: mascotW),
          ),
          if (floats.isNotEmpty) _float(floats[0], 6, 30, 32, 16, accent),
          if (floats.length > 1) _float(floats[1], 184, 18, 32, 16, accent),
          if (floats.length > 2) _float(floats[2], 24, artH - 32, 26, 14, blue ? accent : AppColors.red),
          if (floats.length > 3) _float(floats[3], 172, artH - 38, 28, 14, accent),
        ],
      ),
    );
  }

  Widget _ctaButton() {
    return Material(
      color: blue ? AppColors.blue : AppColors.yellow,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onCta,
        borderRadius: BorderRadius.circular(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcon.data(ctaIcon), size: 18, color: blue ? Colors.white : AppColors.ink),
            const SizedBox(width: 5),
            Text(
              cta,
              style: AppType.button.copyWith(fontSize: 16, fontWeight: AppType.w700, color: blue ? Colors.white : AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }

  Widget _float(String icon, double left, double top, double size, double iconSize, Color color) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: blue ? const Color(0x593A7BF5) : const Color(0x59B47800),
              blurRadius: 10,
              spreadRadius: -4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(AppIcon.data(icon), size: iconSize, color: color),
      ),
    );
  }

  /// `**강조**` 표기를 강조색 조각으로 나눈다.
  static List<TextSpan> _spans(String text, Color accent) {
    final parts = text.split('**');
    return [
      for (int i = 0; i < parts.length; i++)
        if (parts[i].isNotEmpty)
          TextSpan(
            text: parts[i],
            style: i.isOdd ? TextStyle(color: accent) : null,
          ),
    ];
  }
}
