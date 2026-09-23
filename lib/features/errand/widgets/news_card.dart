import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_icon.dart';
import '../data/home_news.dart';
import '../models/home_news.dart';

/// 홈 '겸사겸사 소식' 카드. 시안(`gyumsa-refined`)의 `.g4-news`.
///
/// 세 장을 한 자리에서 점·화살표로 넘겨 본다. 자동으로 넘어가지 않는 건
/// 시안과 같다 — 읽는 중에 바뀌지 않게 하려는 의도다.
class NewsCard extends StatefulWidget {
  /// 카드를 눌렀을 때. 광고 카드는 브랜드 협업 안내로 간다.
  final void Function(HomeNews) onOpen;
  const NewsCard({super.key, required this.onOpen});

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  int index = 0;

  void _move(int step) => setState(() => index = (index + step + homeNews.length) % homeNews.length);

  @override
  Widget build(BuildContext context) {
    final news = homeNews[index];
    final (bg, ink) = switch (news.tone) {
      NewsTone.blue => (AppColors.newsBlueBg, AppColors.newsBlueInk),
      NewsTone.peach => (AppColors.newsPeachBg, AppColors.newsPeachInk),
      NewsTone.mint => (AppColors.newsMintBg, AppColors.newsMintInk),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('겸사겸사 소식',
                style: AppType.caption.copyWith(fontSize: 10, fontWeight: AppType.w600, letterSpacing: 0, color: ink)),
          ),
          _tag(news, ink),
        ]),
        InkWell(
          onTap: () => widget.onOpen(news),
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(news.title.replaceAll('\n', ' '),
                      style: AppType.section.copyWith(fontSize: 17, height: 1.5, color: ink)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 5, 0, 9),
                    child: Text(news.body.replaceAll('\n', ' '),
                        style: AppType.caption.copyWith(fontSize: 10, height: 1.6, color: ink.withValues(alpha: 0.75))),
                  ),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(news.action,
                        style: AppType.caption.copyWith(fontSize: 10, fontWeight: AppType.w600, color: ink)),
                    const SizedBox(width: 6),
                    AppIcon('arrowRight', size: 14, color: ink),
                  ]),
                ]),
              ),
              const SizedBox(width: 10),
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppRadius.emblem),
                ),
                child: AppIcon(news.icon, size: 22, color: ink),
              ),
            ]),
          ),
        ),
        Row(children: [
          Expanded(child: _dots(ink)),
          Text('${index + 1} / ${homeNews.length}',
              style: AppType.caption.copyWith(fontSize: 10, letterSpacing: 1, color: ink.withValues(alpha: 0.6))),
          const SizedBox(width: 6),
          _arrow('arrowLeft', '이전 소식', ink, () => _move(-1)),
          _arrow('arrowRight', '다음 소식', ink, () => _move(1)),
        ]),
      ]),
    );
  }

  /// 꼬리표. 광고 지면은 테두리를 둘러 다른 소식과 구분한다.
  Widget _tag(HomeNews news, Color ink) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: news.isAd ? Colors.transparent : AppColors.card.withValues(alpha: 0.58),
        border: news.isAd ? Border.all(color: AppColors.adLabelLine) : null,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        news.tag,
        style: AppType.caption.copyWith(
          fontSize: 9,
          fontWeight: news.isAd ? AppType.w700 : AppType.w400,
          color: news.isAd ? AppColors.adLabel : ink,
        ),
      ),
    );
  }

  Widget _dots(Color ink) {
    return Row(children: [
      for (int i = 0; i < homeNews.length; i++)
        Semantics(
          button: true,
          label: '${i + 1}번째 소식: ${homeNews[i].tag}',
          selected: i == index,
          child: InkWell(
            onTap: () => setState(() => index = i),
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: i == index ? 15 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: i == index ? 0.75 : 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _arrow(String icon, String label, Color ink, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AppIcon(icon, size: 14, color: ink),
        ),
      ),
    );
  }
}
