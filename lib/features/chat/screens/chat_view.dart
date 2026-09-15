import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

/// 실시간 채팅은 아직 연결 전이라, 가짜 대화 목록 대신 안내와 지원 내역 연결만 둔다.
class ChatView extends StatelessWidget {
  final VoidCallback onGoActivity;
  const ChatView({super.key, required this.onGoActivity});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(22, 20, 22, 12), child: Text('채팅', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink))),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💬', style: TextStyle(fontSize: 34)),
                  const SizedBox(height: 12),
                  const Text('채팅 연결 준비 중', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('아직 실제 메시지는 주고받을 수 없어요.\n지원한 부탁은 진행 중에서 확인할 수 있어요.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.sub, fontSize: 13.5, height: 1.7)),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton(
                    onPressed: onGoActivity,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.line, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('지원 내역 확인', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
