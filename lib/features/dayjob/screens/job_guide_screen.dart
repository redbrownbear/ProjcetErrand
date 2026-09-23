import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/fact_rows.dart';
import '../../../core/widgets/screen_frame.dart';

/// 단기알바 모집 안내. 시안(`gyumsa-refined`)의 `G4JobGuide`.
///
/// 홈 '겸사겸사 소식'의 단기알바 카드에서 온다. 무엇을 준비해야 하는지
/// 세 단계로 먼저 보여주고 등록 화면으로 넘긴다.
class JobGuideScreen extends StatelessWidget {
  final VoidCallback onStart;
  const JobGuideScreen({super.key, required this.onStart});

  static const _rows = [
    ('회사와 업무', '회사명·주소·업무·지원 자격'),
    ('근무 조건', '날짜·시간·장소·휴게시간·인원'),
    ('급여와 모집', '급여 기준·지급일·마감·담당자'),
  ];

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: '단기알바 모집 안내',
      onBack: () => Navigator.pop(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
        children: [
          Text('새로운 기능', style: AppType.caption.copyWith(fontSize: 11, color: AppColors.greetingPoint)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text('함께 일할 사람을\n찾고 있나요?',
                style: AppType.section.copyWith(fontSize: 26, height: 1.45, color: AppColors.attendTitle)),
          ),
          Text('회사와 업무 → 근무 조건 → 급여와 모집, 세 단계로 작성해요. 작성 중인 내용은 등록할 때 저장됩니다.',
              style: AppType.body.copyWith(fontSize: 13, height: 1.9, color: AppColors.sub)),
          const SizedBox(height: 16),
          const FactRows(_rows),
          const SizedBox(height: 26),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onStart();
            },
            child: const Text('단기알바 모집 작성하기'),
          ),
        ],
      ),
    );
  }
}
