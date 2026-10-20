import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/kit.dart';
import '../../errand/models/application.dart';

/// 채팅 탭 (제목은 셸의 상단 헤더가 그린다).
///
/// 대화방은 거래가 시작된(요청자가 지원을 수락한) 부탁마다 하나다. 없으면 빈 화면과 다음 행동을 둔다.
class ChatView extends StatelessWidget {
  final VoidCallback onGoActivity;
  final VoidCallback onBrowse;
  final List<ServerTrade> threads;
  final String? myUid;
  final void Function(ServerTrade) onOpen;
  const ChatView({
    super.key,
    required this.onGoActivity,
    required this.onBrowse,
    this.threads = const [],
    this.myUid,
    this.onOpen = _noop,
  });
  static void _noop(ServerTrade _) {}

  @override
  Widget build(BuildContext context) {
    final uid = myUid;
    if (threads.isNotEmpty && uid != null) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: threads.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 20, endIndent: 20),
        itemBuilder: (_, i) {
          final t = threads[i];
          final unread = t.unreadFor(uid);
          final peer = t.requesterUid == uid ? '수행자' : '요청자';
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            title: Text(t.title.isEmpty ? '부탁' : t.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            subtitle: Text(
              '$peer · ${t.lastMessage ?? '아직 메시지가 없어요'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.sub),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (t.lastMessageAt != null)
                  Text(dateTimeLabel(t.lastMessageAt!), style: const TextStyle(fontSize: 11, color: AppColors.faint)),
                if (unread > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(99)),
                    child: Text('$unread', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
            onTap: () => onOpen(t),
          );
        },
      );
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              '지원한 부탁이 수락되면\n상대방과 대화할 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.sub, height: 1.55),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              child: BigButton(label: '내 주변 부탁 보기', height: 46, onTap: onBrowse),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onGoActivity,
              child: const Text('지원 내역 확인', style: TextStyle(fontSize: 13, color: AppColors.sub)),
            ),
          ],
        ),
      ),
    );
  }
}
