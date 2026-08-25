import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../data/items.dart';
import '../theme/colors.dart';

class ChatView extends StatelessWidget {
  final Map<int, String> status;
  const ChatView({super.key, required this.status});
  @override
  Widget build(BuildContext context) {
    final rows = items.where((i) => status.containsKey(i.id)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(20, 18, 20, 12), child: Text('채팅', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink))),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 90),
            child: Center(child: Text('아직 이어진 이웃이 없어요.\n신청하면 여기서 매칭 상태를 볼 수 있어요.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.sub, fontSize: 13.5, height: 1.7))),
          ),
        Expanded(
          child: ListView(
            children: rows.map((it) {
              final pending = status[it.id] == 'pending';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
                child: Row(children: [
                  Container(
                    width: 46, height: 46, alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.yellowSoft, shape: BoxShape.circle),
                    child: Text(catOf(it.cat)?.icon ?? '🙌', style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(it.who, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: pending ? AppColors.yellowSoft : AppColors.greenSoft, borderRadius: BorderRadius.circular(6)),
                            child: Text(pending ? '매칭 중' : '매칭 완료', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: pending ? const Color(0xFFB8860B) : const Color(0xFF1B8A5A))),
                          ),
                        ]),
                        const SizedBox(height: 2),
                        Text(pending ? '상대의 수락을 기다리는 중…' : '이제 시간·장소를 정해요', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
                      ],
                    ),
                  ),
                ]),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
