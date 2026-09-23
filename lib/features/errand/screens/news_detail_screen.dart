import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/screen_frame.dart';
import '../models/home_news.dart';

/// '겸사겸사 소식' 상세. 시안(`gyumsa-refined`)의 `G4NewsDetail`.
///
/// 달라진 점을 세 항목으로 나눠 읽고, 마지막에 해당 화면으로 바로 간다.
class NewsDetailScreen extends StatelessWidget {
  final HomeNews news;

  /// 아래 버튼 — 해외 사다주기 둘러보기 · 단기알바 모집 안내
  final String actionLabel;
  final VoidCallback onAction;

  const NewsDetailScreen({super.key, required this.news, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: '겸사겸사 소식',
      onBack: () => Navigator.pop(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
        children: [
          Text('서비스 업데이트', style: AppType.caption.copyWith(fontSize: 11, color: AppColors.greetingPoint)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(news.title,
                style: AppType.section.copyWith(fontSize: 26, height: 1.45, color: AppColors.attendTitle)),
          ),
          if (news.lead != null)
            Text(news.lead!, style: AppType.body.copyWith(fontSize: 13, height: 1.9, color: AppColors.sub)),
          for (final s in news.sections)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.title, style: AppType.sectionSmall.copyWith(fontSize: 16, color: AppColors.green)),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(s.body, style: AppType.body.copyWith(fontSize: 13, height: 1.9, color: AppColors.sub)),
                ),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('현재는 기능 체험 시안이며 실제 거래·채용 접수는 연동 전입니다.',
                style: AppType.caption.copyWith(fontSize: 10, height: 1.7, color: AppColors.faint)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onAction();
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
