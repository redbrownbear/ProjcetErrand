import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_header.dart';

/// 실시간 채팅은 아직 연결 전이라, 가짜 대화 목록 대신 안내와 지원 내역 연결만 둔다.
/// (기획 시안 v9의 `Chats` — 탭 제목 + `EmptyState`)
class ChatView extends StatelessWidget {
  final VoidCallback onGoActivity;
  const ChatView({super.key, required this.onGoActivity});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 8),
          child: Text('채팅', style: AppType.tabTitle),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: EmptyState(
              icon: 'chat',
              title: '채팅 연결 준비 중',
              msg: '아직 실제 메시지는 주고받을 수 없어요.\n지원한 부탁은 진행 중에서 확인할 수 있어요.',
              action: '지원 내역 확인',
              onAction: onGoActivity,
            ),
          ),
        ),
      ],
    );
  }
}
