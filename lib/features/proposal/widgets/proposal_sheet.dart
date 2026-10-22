import 'package:flutter/material.dart';

import '../../../app/neighbor_store.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/kit.dart';
import '../../../core/widgets/surface.dart';
import '../../community/models/com_post.dart';
import '../../errand/data/countries.dart';
import '../models/proposal.dart';
import '../repositories/proposal_repository.dart';
import 'live_board.dart';
import 'proposal_ask_sheet.dart';

/// 제안 상세 시트 (시안 v43~v44).
///
/// 물건·날짜·인원·결제 → 함께 요청한 이웃 → 그 지역 이웃 이야기 → '저 구매할래요!'.
/// 요청을 보낸 뒤에는 '후기 남기기'가 제목·지역이 채워진 채 열린다.
class ProposalSheet extends StatelessWidget {
  final NeighborStore store;
  final Proposal p;
  final void Function(ComPost) onOpenPost;
  final VoidCallback onMoreStories;
  final void Function(Proposal) onReview;
  final VoidCallback onOtherAsk;

  /// 따로 한 부탁이 수락되면 그 거래의 채팅방 (A29)
  final void Function(String tradeId)? onOpenChat;
  const ProposalSheet({
    super.key,
    required this.store,
    required this.p,
    required this.onOpenPost,
    required this.onMoreStories,
    required this.onReview,
    required this.onOtherAsk,
    this.onOpenChat,
  });

  static Future<void> show(
    BuildContext context, {
    required NeighborStore store,
    required Proposal p,
    required void Function(ComPost) onOpenPost,
    required VoidCallback onMoreStories,
    required void Function(Proposal) onReview,
    required VoidCallback onOtherAsk,
    void Function(String tradeId)? onOpenChat,
  }) => showSheet(
    context,
    (_) => ProposalSheet(
      store: store,
      p: p,
      onOpenPost: onOpenPost,
      onMoreStories: onMoreStories,
      onReview: onReview,
      onOtherAsk: onOtherAsk,
      onOpenChat: onOpenChat,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final me = store.joined.contains(p.id);
        final count = p.countWith(me);
        final closed = !p.openFor(me) && !me;
        // 서버 제안의 주인은 신청을 받는 대신 진행 · 취소를 정한다(A15)
        final owner = p.mine && p.onServer;
        final canAsk = store.live && p.onServer && !p.mine;
        final stories = store.related(p).take(2).toList();
        final storyTitle = p.abroad ? '${countryOf(p.cc).name} 이웃 이야기' : '${p.from} · ${p.to} 이웃 이야기';

        return SheetFrame(
          bottom: owner
              ? _OwnerBar(store: store, p: p)
              : Row(
            children: [
              Expanded(
                flex: 2,
                child: me
                    ? BigButton(
                        label: '후기 남기기',
                        bg: AppColors.page,
                        fg: AppColors.ink2,
                        height: 54,
                        onTap: () {
                          Navigator.pop(context);
                          onReview(p);
                        },
                      )
                    : BigButton(
                        label: '다른 부탁',
                        bg: AppColors.page,
                        fg: AppColors.ink2,
                        height: 54,
                        onTap: () {
                          // 서버 제안이면 제안자에게 따로 부탁, 아니면 일반 부탁 쓰기
                          if (canAsk) {
                            _ask(context);
                            return;
                          }
                          Navigator.pop(context);
                          onOtherAsk();
                        },
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: BigButton(
                  label: me
                      ? (p.proceeding ? '진행이 정해졌어요' : '구매 요청 취소')
                      : (p.proceeding ? '모집이 끝났어요' : (closed ? '마감됐어요' : (p.mine ? '내가 올린 제안' : '저 구매할래요!'))),
                  bg: me ? AppColors.card : AppColors.ink,
                  fg: me ? AppColors.ink : Colors.white,
                  height: 54,
                  onTap: (closed && !me) || p.mine || (me && p.proceeding) ? null : () => store.toggleJoin(p),
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: p.abroad ? AppColors.blueSoft : const Color(0xFFFFF1C2),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      p.abroad ? '${(p.cc ?? '').toUpperCase()} ${p.from}' : '${p.from} → ${p.to}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.abroad ? AppColors.blue : AppColors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _openStore(context),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                      decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(7)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.mine ? '내 스토어' : p.who,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.ink),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      [p.area, p.ago].where((s) => s.isNotEmpty).join(' · '),
                      style: const TextStyle(fontSize: 12, color: AppColors.sub),
                    ),
                  ),
                ],
              ),
              if (p.departVerified)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: const [
                      StatusBadge('출국 확인', bg: AppColors.greenSoft, fg: AppColors.greenDeep),
                      SizedBox(width: 6),
                      Text('항공권·탑승권을 확인했어요', style: TextStyle(fontSize: 12, color: AppColors.sub)),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                p.headline,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  height: 1.4,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: nf(p.total),
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1),
                    ),
                    const TextSpan(
                      text: '원 · 1명당',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                style: const TextStyle(color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              const _CheckLine('영수증 기준 가격이에요 · 실제보다 높게 적은 부분은 제안자가 돌려주기로 했어요', color: AppColors.sub),
              const SizedBox(height: 12),
              _row('1명당', p.fee > 0 ? '물건값 ${won(p.price)} + 심부름료 ${won(p.fee)}' : '물건값 ${won(p.price)} · 심부름료 없음'),
              _row('사 오는 물건', [p.item, ?p.spec].join(' · ')),
              _row(p.abroad ? '출국하는 날' : '이동하는 날', '${p.day.month}/${p.day.day}'),
              _row('모집 인원', p.unlimited ? '$count명 · 제한 없음' : '$count/${p.max}명 · ${p.left(me)}자리 남음'),
              _row('전달', p.deliveryLabel),
              _row('결제', '만나서 직접 주고받아요 · 앱 안의 결제는 없어요'),
              if (p.proceeding) _row('진행', '제안자가 사 오기로 했어요 · 새 신청은 받지 않아요'),
              if (p.note.isNotEmpty) _row('한마디', p.note),
              const SizedBox(height: 14),
              const Text(
                '함께 요청한 이웃',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sub),
              ),
              const SizedBox(height: 8),
              if (owner && store.proposalRepo != null)
                _JoinerNames(store: store, p: p)
              else if (count == 0)
                const Text('아직 요청한 이웃이 없어요', style: TextStyle(fontSize: 13, color: AppColors.faint))
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // 프로필 공개 이웃은 노랑, 비공개는 회색 (시안 v44-2)
                    for (var i = 0; i < count; i++)
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: me && i == count - 1 ? AppColors.yellow : (i.isEven ? const Color(0xFFFFE89A) : AppColors.soft2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          me && i == count - 1 ? '나' : '',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
              if (owner && store.proposalRepo != null) _AskList(store: store, p: p, onOpenChat: onOpenChat),
              if (canAsk) _MyAsk(store: store, p: p, joined: me, onAsk: () => _ask(context), onOpenChat: onOpenChat),
              const SizedBox(height: 18),
              Text(
                storyTitle,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sub),
              ),
              const SizedBox(height: 6),
              if (stories.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('아직 이 지역 이야기가 없어요', style: TextStyle(fontSize: 13, color: AppColors.faint)),
                ),
              for (final s in stories)
                Tap(
                  onTap: () => onOpenPost(s),
                  radius: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.line)),
                    ),
                    child: Row(
                      children: [
                        StatusBadge(s.kind, bg: AppColors.page, fg: AppColors.ink2),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextLink(label: '이야기 더 보기', onTap: onMoreStories),
              ),
              const SizedBox(height: 10),
              const _CheckLine('만나서 영수증을 보여 주고 금액을 주고받아요 · 정원이 차면 새 신청은 마감돼요', color: AppColors.green, bold: true),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String k, String v) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.line)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(k, style: const TextStyle(fontSize: 14, color: AppColors.sub)),
        ),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
        ),
      ],
    ),
  );

  Future<void> _ask(BuildContext context) async {
    final input = await openProposalAskSheet(context, p);
    if (input == null) return;
    await store.askProposer(p, item: input.item, est: input.est, note: input.note);
  }

  /// 제안자 스토어 — 이 이웃이 올린 다른 제안
  void _openStore(BuildContext context) {
    final mine = store.proposals.where((x) => x.who == p.who).toList();
    showSheet(
      context,
      (ctx) => SheetFrame(
        title: p.mine ? '내 스토어' : '${p.who} 스토어',
        sub: '이 이웃이 올린 제안이에요',
        child: Column(
          children: [
            for (final x in mine) ...[
              ProposalRow(
                p: x,
                meJoined: store.joined.contains(x.id),
                bg: AppColors.page,
                onTap: () {
                  Navigator.pop(ctx);
                  if (x.id != p.id) {
                    show(
                      context,
                      store: store,
                      p: x,
                      onOpenPost: onOpenPost,
                      onMoreStories: onMoreStories,
                      onReview: onReview,
                      onOtherAsk: onOtherAsk,
                      onOpenChat: onOpenChat,
                    );
                  }
                },
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

/// 내 서버 제안의 아래 버튼 — 지금 인원으로 진행 · 제안 취소
class _OwnerBar extends StatelessWidget {
  final NeighborStore store;
  final Proposal p;
  const _OwnerBar({required this.store, required this.p});

  Future<void> _cancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('제안을 취소할까요?'),
        content: const Text('신청한 이웃의 구매 요청도 모두 취소되고 알림이 가요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('아니요')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('제안 취소'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await store.decideProposal(p, 'cancel');
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = p.countWith(false);
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: BigButton(
            key: const Key('proposal-cancel'),
            label: '제안 취소',
            bg: AppColors.page,
            fg: AppColors.red,
            height: 54,
            onTap: () => _cancel(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: BigButton(
            key: const Key('proposal-proceed'),
            label: p.proceeding ? '진행하기로 했어요' : (n == 0 ? '아직 신청이 없어요' : '$n명으로 진행하기'),
            bg: AppColors.ink,
            fg: Colors.white,
            height: 54,
            onTap: p.proceeding || n == 0 ? null : () => store.decideProposal(p, 'proceed'),
          ),
        ),
      ],
    );
  }
}

/// 내 제안에 신청한 이웃 이름 (제안자만 볼 수 있다)
class _JoinerNames extends StatefulWidget {
  final NeighborStore store;
  final Proposal p;
  const _JoinerNames({required this.store, required this.p});

  @override
  State<_JoinerNames> createState() => _JoinerNamesState();
}

class _JoinerNamesState extends State<_JoinerNames> {
  late final Stream<List<ProposalJoiner>> joiners = widget.store.proposalRepo!.watchJoiners(widget.p.id);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProposalJoiner>>(
      stream: joiners,
      builder: (context, snap) {
        final list = snap.data ?? const <ProposalJoiner>[];
        if (list.isEmpty) return const Text('아직 요청한 이웃이 없어요', style: TextStyle(fontSize: 13, color: AppColors.faint));
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final j in list) StatusBadge(j.name, bg: AppColors.yellowSoft, fg: AppColors.ink)],
        );
      },
    );
  }
}

class _CheckLine extends StatelessWidget {
  final String text;
  final Color color;
  final bool bold;
  const _CheckLine(this.text, {required this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.check_rounded, size: 15, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.5, color: color, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, height: 1.5),
          ),
        ),
      ],
    );
  }
}

/// 이 제안의 제안자에게 내가 따로 한 부탁 (A29). 신청한 이웃은 아래 버튼이 '후기 남기기'라 여기서 부탁한다
class _MyAsk extends StatefulWidget {
  final NeighborStore store;
  final Proposal p;
  final bool joined;
  final VoidCallback onAsk;
  final void Function(String tradeId)? onOpenChat;
  const _MyAsk({required this.store, required this.p, required this.joined, required this.onAsk, this.onOpenChat});

  @override
  State<_MyAsk> createState() => _MyAskState();
}

class _MyAskState extends State<_MyAsk> {
  late final Stream<ProposalAsk?> mine = widget.store.proposalRepo!.watchMyAsk(widget.p.id);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProposalAsk?>(
      stream: mine,
      builder: (context, snap) {
        final a = snap.data;
        if (a == null) {
          if (!widget.joined) return const SizedBox.shrink();
          return Align(
            alignment: Alignment.centerLeft,
            child: TextLink(label: '제안자에게 다른 것도 부탁하기', onTap: widget.onAsk),
          );
        }
        final (label, bg, fg) = switch (a.status) {
          'accepted' => ('맡아 줬어요', AppColors.greenSoft, AppColors.greenDeep),
          'rejected' => ('어렵대요', AppColors.page, AppColors.sub),
          _ => ('답을 기다려요', AppColors.yellowSoft, AppColors.ink),
        };
        final chat = a.accepted && a.tradeId != null && widget.onOpenChat != null;
        return Container(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('내가 따로 한 부탁', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sub)),
                  const Spacer(),
                  StatusBadge(label, bg: bg, fg: fg),
                ],
              ),
              const SizedBox(height: 6),
              Text(_askLine(a), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
              if (chat || a.status == 'rejected' || a.pending)
                Align(
                  alignment: Alignment.centerRight,
                  child: chat
                      ? TextLink(
                          label: '채팅하기',
                          onTap: () {
                            Navigator.pop(context);
                            widget.onOpenChat!(a.tradeId!);
                          },
                        )
                      : TextLink(label: a.pending ? '내용 고치기' : '다시 부탁하기', onTap: widget.onAsk),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 내 제안에 따로 온 부탁 — 수락하면 거래가 생기고 채팅이 열린다 (제안자만, A29)
class _AskList extends StatefulWidget {
  final NeighborStore store;
  final Proposal p;
  final void Function(String tradeId)? onOpenChat;
  const _AskList({required this.store, required this.p, this.onOpenChat});

  @override
  State<_AskList> createState() => _AskListState();
}

class _AskListState extends State<_AskList> {
  late final Stream<List<ProposalAsk>> asks = widget.store.proposalRepo!.watchAsks(widget.p.id);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProposalAsk>>(
      stream: asks,
      builder: (context, snap) {
        final list = snap.data ?? const <ProposalAsk>[];
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 18),
            const Text('따로 온 부탁', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sub)),
            for (final a in list)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${a.name} · ${_askLine(a)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          if (a.note.isNotEmpty)
                            Text(a.note, style: const TextStyle(fontSize: 12.5, color: AppColors.sub, height: 1.4)),
                        ],
                      ),
                    ),
                    if (a.pending) ...[
                      TextButton(
                        key: Key('ask-reject-${a.uid}'),
                        onPressed: () => widget.store.answerAsk(widget.p, a.uid, false),
                        child: const Text('어려워요', style: TextStyle(color: AppColors.sub)),
                      ),
                      TextButton(
                        key: Key('ask-accept-${a.uid}'),
                        onPressed: () => widget.store.answerAsk(widget.p, a.uid, true),
                        child: const Text('맡을게요', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                      ),
                    ] else if (a.tradeId != null && widget.onOpenChat != null)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onOpenChat!(a.tradeId!);
                        },
                        child: const Text('채팅하기', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

String _askLine(ProposalAsk a) => a.est == null ? a.item : '${a.item} · 예상 ${won(a.est!)}';
