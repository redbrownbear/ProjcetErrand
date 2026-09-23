import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/screen_frame.dart';

/// '부탁하기'를 누르면 처음 나오는 갈래. 시안(`gyumsa-refined`)의 `GyCreate`.
///
/// 예전에는 곧바로 부탁 등록 폼이 열렸다. 그런데 단기알바는 근로 조건을
/// 적어야 하는 **채용**이라 일상 부탁과 같은 폼으로 받으면 안 된다.
/// 그래서 등록 앞에 갈래를 두고, 해외 사다주기도 여기서 나눈다.
class CreateChoiceScreen extends StatelessWidget {
  final VoidCallback onLocal;
  final VoidCallback onOverseas;
  final VoidCallback onJob;

  const CreateChoiceScreen({
    super.key,
    required this.onLocal,
    required this.onOverseas,
    required this.onJob,
  });

  @override
  Widget build(BuildContext context) {
    final choices = <({String icon, String title, String desc, VoidCallback onTap, Color bg})>[
      (icon: 'handshake', title: '일상 부탁', desc: '픽업·장보기·이동 도움을 가까운 이웃에게', onTap: onLocal, bg: AppColors.card),
      (icon: 'globe', title: '해외 사다주기', desc: '여행 가는 이웃에게, 예산 안에서 안전하게', onTap: onOverseas, bg: const Color(0xFFEAF4FB)),
      (icon: 'clipboard', title: '단기알바 모집', desc: '회사·업무·근무시간·급여를 자세히 안내해요', onTap: onJob, bg: const Color(0xFFF4EEFB)),
    ];

    return ScreenFrame(
      title: '부탁하기',
      onBack: () => Navigator.pop(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Text('필요한 도움에 맞게', style: AppType.caption.copyWith(fontSize: 11, color: AppColors.greetingPoint)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text('어떤 일을 맡기고 싶으세요?',
                style: AppType.section.copyWith(fontSize: 24, height: 1.4, color: AppColors.attendTitle)),
          ),
          Text('일상 속 부탁과 근무 조건이 있는 채용을 나누어 등록해요.', style: AppType.meta.copyWith(height: 1.8)),
          const SizedBox(height: 8),
          for (final c in choices)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  c.onTap();
                },
                borderRadius: BorderRadius.circular(AppRadius.surface),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(AppRadius.surface)),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.card.withValues(alpha: 0.63),
                        borderRadius: BorderRadius.circular(AppRadius.emblem),
                      ),
                      child: AppIcon(c.icon, size: 22, color: AppColors.goalMintInk),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.title, style: AppType.sectionSmall.copyWith(fontSize: 16)),
                        Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Text(c.desc, style: AppType.caption.copyWith(fontSize: 11, height: 1.7)),
                        ),
                      ]),
                    ),
                    const AppIcon('chevron', size: 18, color: AppColors.faint),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
