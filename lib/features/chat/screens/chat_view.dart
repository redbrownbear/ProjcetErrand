import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';

/// 채팅 (시안 v77 `#t-chat .empty`).
///
/// 실시간 채팅은 아직 연결 전이라, 가짜 대화 목록 대신 빈 화면과 다음 행동만 둔다.
/// 탭 제목은 셸 머리줄이 그린다.
class ChatView extends StatelessWidget {
  final VoidCallback onGoActivity;
  final VoidCallback onBrowse;
  const ChatView({super.key, required this.onGoActivity, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.chat_bubble_outline_rounded, size: 32, color: AppColors.faint),
          ),
          const SizedBox(height: 18),
          const Text('아직 대화가 없어요', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            '부탁에 지원하거나 가격을 제안하면\n요청자와 대화가 시작돼요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.sub, height: 1.55),
          ),
          const SizedBox(height: 20),
          SizedBox(width: 180, child: BigButton(label: '내 주변 부탁 보기', height: 46, onTap: onBrowse)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onGoActivity,
            child: const Text('지원 내역 확인', style: TextStyle(fontSize: 13, color: AppColors.sub)),
          ),
        ]),
      ),
    );
  }
}
