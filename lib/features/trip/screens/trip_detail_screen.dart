import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../core/backend/server_api.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../../../core/widgets/surface.dart';
import '../../errand/data/countries.dart';
import '../models/trip_post.dart';
import '../repositories/trip_repository.dart';

/// '가는 김에' 글 하나. 다른 이웃은 댓글로 "이것 좀 부탁해요" · "제가 도와드릴게요"를 남기고,
/// 글쓴이에게 알림이 간다. 댓글은 공개라 연락처·계좌·링크는 서버가 가린다.
class TripDetailScreen extends StatefulWidget {
  final AppNav nav;
  final int id;
  const TripDetailScreen({super.key, required this.nav, required this.id});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final repo = const TripRepository();
  final ctrl = TextEditingController();
  Stream<List<TripComment>>? comments;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    final t = widget.nav.store.tripById(widget.id);
    if (t != null && t.server) comments = repo.watchComments(t.id);
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _send(TripPost t) async {
    final text = ctrl.text.trim();
    if (text.isEmpty || sending) return;
    Future<void> go() async {
      setState(() => sending = true);
      try {
        final masked = await repo.comment(t.id, text);
        ctrl.clear();
        if (mounted) FocusScope.of(context).unfocus();
        if (masked) widget.nav.flash('연락처·계좌·링크는 가려서 올렸어요');
      } on ServerException catch (e) {
        widget.nav.flash(e.message);
      } finally {
        if (mounted) setState(() => sending = false);
      }
    }

    final gate = widget.nav.store.gate;
    if (gate == null) {
      await go();
    } else {
      await gate(() => go());
    }
  }

  Future<void> _delete(TripPost t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이 글을 지울까요?'),
        content: const Text('달린 댓글도 더 이상 보이지 않아요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('지우기')),
        ],
      ),
    );
    if (ok != true) return;
    await widget.nav.store.deleteTrip(t);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.nav.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final t = store.tripById(widget.id);
        if (t == null) {
          return const PageFrame(
            title: '가는 김에',
            child: Center(child: Text('지워졌거나 찾을 수 없는 글이에요', style: TextStyle(color: AppColors.sub))),
          );
        }
        final mine = store.isMyTrip(t);
        final hint = mine
            ? '댓글에 답해 보세요'
            : (t.going ? '예) 곤약젤리 2봉 부탁드려도 될까요?' : '예) 저 그 근처 가요. 도와드릴게요!');

        return PageFrame(
          title: '가는 김에',
          background: AppColors.card,
          actions: [
            if (mine)
              IconButton(
                onPressed: () => _delete(t),
                icon: const Icon(Icons.delete_outline_rounded, size: 22, color: AppColors.sub),
                tooltip: '글 지우기',
              ),
          ],
          bottom: t.server
              ? Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        maxLength: 300,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(t),
                        decoration: InputDecoration(hintText: hint, counterText: ''),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 72,
                      child: BigButton(label: sending ? '…' : '등록', height: 48, onTap: sending ? null : () => _send(t)),
                    ),
                  ],
                )
              : null,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Row(
                children: [
                  StatusBadge(
                    t.going ? '가요' : '찾아요',
                    bg: t.going ? AppColors.blueSoft : AppColors.yellowSoft,
                    fg: t.going ? AppColors.blue : AppColors.yellowDeep,
                  ),
                  if (t.cc != null) ...[
                    const SizedBox(width: 6),
                    StatusBadge(countryOf(t.cc!).name, bg: AppColors.page, fg: AppColors.ink2),
                  ],
                  if (!t.server && !t.mine) ...[
                    const SizedBox(width: 6),
                    const StatusBadge('예시', bg: AppColors.page, fg: AppColors.sub),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(t.title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, height: 1.4, letterSpacing: -0.6)),
              if (t.when.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(t.when, style: const TextStyle(fontSize: 13.5, color: AppColors.sub)),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Avatar(t.author, size: 28),
                  const SizedBox(width: 8),
                  Text(mine ? '${t.author} (나)' : t.author, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Text(
                    [if (t.area.isNotEmpty) t.area, t.agoAt(DateTime.now())].join(' · '),
                    style: const TextStyle(fontSize: 12.5, color: AppColors.sub),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(t.quote, style: const TextStyle(fontSize: 15.5, height: 1.7, color: AppColors.ink2)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(14)),
                child: Text(
                  !t.server
                      ? (t.mine
                            ? '서버에 연결되지 않은 상태에서 올린 글이라 이 기기에서만 보여요.'
                            : '체험용 예시 글이라 댓글을 달 수 없어요.')
                      : mine
                      ? '이웃이 댓글을 남기면 알림으로 알려 드려요. 연락처는 댓글에 쓰면 가려져요.'
                      : (t.going
                            ? '필요한 게 있으면 댓글로 부탁해 보세요. 글쓴이에게 알림이 가요.'
                            : '도와줄 수 있으면 댓글로 알려 주세요. 글쓴이에게 알림이 가요.'),
                  style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.ink2),
                ),
              ),
              if (t.going && !mine) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextLink(label: '값을 정해 정식으로 부탁 올리기 ›', onTap: widget.nav.openAskForm),
                ),
              ],
              const SizedBox(height: 20),
              if (comments != null)
                StreamBuilder<List<TripComment>>(
                  stream: comments,
                  builder: (context, snap) {
                    final list = snap.data ?? const <TripComment>[];
                    final me = store.uid?.call();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('댓글 ${list.length}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        if (list.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('첫 댓글을 남겨 주세요', style: TextStyle(color: AppColors.faint)),
                          ),
                        for (final c in list) _CommentRow(c: c, mine: c.uid == me, writer: c.uid == t.ownerUid),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CommentRow extends StatelessWidget {
  final TripComment c;
  final bool mine;
  final bool writer;
  const _CommentRow({required this.c, required this.mine, required this.writer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(c.author, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(c.author, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    if (writer) ...[
                      const SizedBox(width: 4),
                      const Text('글쓴이', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.blue)),
                    ],
                    if (mine && !writer) ...[
                      const SizedBox(width: 4),
                      const Text('나', style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(c.text, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.ink2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
