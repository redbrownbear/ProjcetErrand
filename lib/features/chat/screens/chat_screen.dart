import 'package:flutter/material.dart';

import '../../../core/backend/server_api.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';

/// 거래 한 건의 1:1 채팅 (결정 5: 최소 채팅 — 텍스트만, 거래 당사자 두 사람만).
///
/// 보낸 글은 서버가 전화번호·계좌번호·외부 링크를 가린 뒤 저장한다. 가려졌으면 안내한다.
class ChatScreen extends StatefulWidget {
  final String tradeId;
  final String title;
  final String myUid;

  /// 상대를 부르는 말 ('요청자' · '수행자')
  final String peerLabel;
  final bool closed;
  const ChatScreen({super.key, required this.tradeId, required this.title, required this.myUid, required this.peerLabel, this.closed = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatRepository repo = ChatRepository(widget.tradeId);
  late final Stream<List<ChatMessage>> messages = repo.watch();
  final input = TextEditingController();
  bool sending = false;
  String? notice;

  @override
  void initState() {
    super.initState();
    repo.markRead();
  }

  @override
  void dispose() {
    repo.markRead();
    input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = input.text.trim();
    if (text.isEmpty || sending) return;
    setState(() {
      sending = true;
      notice = null;
    });
    try {
      final masked = await repo.send(text);
      input.clear();
      if (masked) notice = '연락처·계좌·링크는 가려져서 전달돼요. 약속은 앱 안에서 정해 주세요.';
    } on ServerException catch (e) {
      notice = e.message;
    }
    if (mounted) setState(() => sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.ink,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.peerLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(widget.title, style: const TextStyle(fontSize: 12, color: AppColors.sub), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.yellowSoft,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: const Text(
              '연락처·계좌·외부 링크는 자동으로 가려져요. 앱 밖 거래는 신고·분쟁 처리를 받을 수 없어요.',
              style: TextStyle(fontSize: 12, color: AppColors.yellowDeep, height: 1.5, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: messages,
              builder: (context, snap) {
                final list = snap.data ?? const <ChatMessage>[];
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      snap.connectionState == ConnectionState.waiting ? '불러오는 중이에요' : '첫 메시지를 보내 보세요\n만날 장소·시간을 앱 안에서 정하면 기록이 남아요',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13.5, color: AppColors.sub, height: 1.6),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _bubble(list[list.length - 1 - i]),
                );
              },
            ),
          ),
          if (notice != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(notice!, style: const TextStyle(fontSize: 12, color: AppColors.red)),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: widget.closed
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text('취소된 거래라 메시지를 보낼 수 없어요', style: TextStyle(fontSize: 13, color: AppColors.sub)),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('chat-input'),
                            controller: input,
                            minLines: 1,
                            maxLines: 4,
                            maxLength: 1000,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: const InputDecoration(
                              hintText: '메시지 입력',
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.card,
                              isDense: true,
                              border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(20))),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: '보내기',
                          onPressed: sending ? null : _send,
                          icon: Icon(Icons.send_rounded, color: sending ? AppColors.faint : AppColors.ink),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage m) {
    final mine = m.senderUid == widget.myUid;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.74),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: mine ? AppColors.yellow : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: mine ? null : Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(m.text, style: const TextStyle(fontSize: 14.5, color: AppColors.ink, height: 1.45)),
            const SizedBox(height: 3),
            Text(
              dateTimeLabel(m.createdAt) + (m.masked ? ' · 일부 가림' : ''),
              style: const TextStyle(fontSize: 10.5, color: AppColors.sub),
            ),
          ],
        ),
      ),
    );
  }
}
