import 'package:flutter/material.dart';

import '../../../core/widgets/section_header.dart';

/// 실시간 채팅은 아직 연결 전이라, 가짜 대화 목록 대신 안내와 지원 내역 연결만 둔다.
/// (시안 v33 `#t-chat .empty` — 제목은 셸의 상단 헤더가 그린다)
class ChatView extends StatelessWidget {
  final VoidCallback onGoActivity;
  const ChatView({super.key, required this.onGoActivity});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: EmptyState(
        icon: 'chat',
        title: '채팅 연결 준비 중',
        msg: '실제 메시지 전송은 연동 전입니다.\n지원한 부탁의 진행 상황을 먼저 확인하세요.',
        action: '지원 내역 확인',
        onAction: onGoActivity,
      ),
    );
  }
}
