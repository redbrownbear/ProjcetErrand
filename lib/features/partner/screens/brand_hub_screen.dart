import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/screen_frame.dart';
import '../models/partner_proposal.dart';
import 'partner_proposal_screen.dart';

/// 브랜드 협업 안내. 시안(`gyumsa-refined`)의 `G4BrandHub`.
///
/// 홈 '겸사겸사 소식'의 광고 카드와 부업 탭 아래 파트너 배너가 여기로 온다.
/// 제안할 수 있는 협업 종류와 진행 절차를 먼저 읽고 제안서로 넘어간다.
class BrandHubScreen extends StatelessWidget {
  const BrandHubScreen({super.key});

  static const _types = [
    (icon: 'gift', title: '체험·리뷰 캠페인', body: '제품 체험, 블로그·SNS 콘텐츠, 매장 방문'),
    (icon: 'clipboard', title: '설문·리서치', body: '소비자 설문, 인터뷰, 서비스 사용성 테스트'),
    (icon: 'cart', title: '공동구매·브랜드 광고', body: '상품 입점, 공동구매 운영, 브랜드 소식 노출'),
  ];

  static const _steps = [
    (title: '제안 작성', body: '목표와 희망 조건을 남겨 주세요.'),
    (title: '내용 검토', body: '브랜드와 맞는 협업 방식을 살펴봐요.'),
    (title: '조건 협의', body: '일정·보상·운영 범위를 함께 정해요.'),
  ];

  static const _typeTints = [
    (bg: Color(0xFFEDF1DF), fg: Color(0xFF93A576)),
    (bg: Color(0xFFE8F0F7), fg: Color(0xFF91ADBC)),
    (bg: Color(0xFFF7EDDD), fg: Color(0xFFBBA16E)),
  ];

  void _openProposal(BuildContext context, String kind) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PartnerProposalScreen(kind: kind)),
      );

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: '브랜드 협업',
      onBack: () => Navigator.pop(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('겸사겸사 파트너', style: AppType.caption.copyWith(fontSize: 11, color: AppColors.greetingPoint)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text('우리 브랜드에 맞는\n협업을 찾아보세요.',
                    style: AppType.section.copyWith(fontSize: 26, height: 1.45, color: AppColors.attendTitle)),
              ),
              Text('고객의 경험이 필요한 순간,\n겸사겸사와 함께할 방법을 안내해 드려요.',
                  style: AppType.body.copyWith(fontSize: 13, height: 1.9, color: AppColors.sub)),
            ]),
          ),
          _heading('이런 협업을 제안할 수 있어요'),
          for (int i = 0; i < _types.length; i++) _typeRow(i),
          _heading('진행 전에 함께 정리할 내용'),
          Text('캠페인 목표와 대상, 참여 조건과 보상, 일정과 예산을 먼저 확인해요. 검수 기준과 결과 확인 방식도 협의한 뒤 진행합니다.',
              style: AppType.body.copyWith(fontSize: 13, height: 1.9, color: AppColors.sub)),
          const SizedBox(height: 12),
          for (int i = 0; i < _steps.length; i++) _stepRow(i),
          _next(context),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text('현재는 제안서 작성·저장 기능을 체험할 수 있습니다. 실제 담당자 접수는 연동 전입니다.',
                style: AppType.caption.copyWith(fontSize: 10, height: 1.7, color: AppColors.faint)),
          ),
        ],
      ),
    );
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 26, 0, 16),
        child: Text(text, style: AppType.sectionSmall.copyWith(fontSize: 17, height: 1.5, color: AppColors.green)),
      );

  Widget _typeRow(int i) {
    final t = _types[i];
    final tint = _typeTints[i];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 19),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(children: [
        Container(
          width: 47,
          height: 47,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: tint.bg, borderRadius: BorderRadius.circular(16)),
          child: AppIcon(t.icon, size: 23, color: tint.fg),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.title, style: AppType.sectionSmall.copyWith(fontSize: 14, color: AppColors.green)),
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(t.body, style: AppType.caption.copyWith(fontSize: 11, height: 1.7)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _stepRow(int i) {
    final s = _steps[i];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Color(0xFFEDF1E5), shape: BoxShape.circle),
          child: Text('${i + 1}'.padLeft(2, '0'),
              style: AppType.caption.copyWith(fontSize: 11, color: AppColors.goalMintInk)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.title, style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w600, color: AppColors.green)),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(s.body, style: AppType.caption.copyWith(fontSize: 11, height: 1.8)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _next(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('아직 구체적인 계획이 없어도 괜찮아요.', style: AppType.sectionSmall.copyWith(fontSize: 15)),
        Padding(
          padding: const EdgeInsets.only(top: 11),
          child: Text('브랜드 소개와 협업 목표부터 알려 주세요. 예산과 일정은 선택 항목이에요.',
              style: AppType.caption.copyWith(fontSize: 11, height: 1.8)),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => _openProposal(context, PartnerProposal.kindBrand),
          child: const Text('브랜드 협업 제안하기'),
        ),
        TextButton(
          onPressed: () => _openProposal(context, PartnerProposal.kindGroup),
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(40)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('공동구매 상품 입점·문의',
                style: AppType.caption.copyWith(fontSize: 11, color: AppColors.goalMintSub)),
            const SizedBox(width: 8),
            const AppIcon('chevron', size: 14, color: AppColors.goalMintSub),
          ]),
        ),
      ]),
    );
  }
}
