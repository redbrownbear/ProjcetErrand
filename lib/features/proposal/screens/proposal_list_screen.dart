import 'package:flutter/material.dart';

import '../../../app/neighbor_store.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../../errand/data/countries.dart';
import '../models/proposal.dart';
import '../widgets/live_board.dart';

/// LIVE 보드의 '전체' — 모든 제안 목록
class ProposalListScreen extends StatefulWidget {
  final NeighborStore store;
  final bool abroad;
  final void Function(Proposal) onOpen;
  final VoidCallback onPropose;
  const ProposalListScreen({super.key, required this.store, required this.abroad, required this.onOpen, required this.onPropose});

  @override
  State<ProposalListScreen> createState() => _ProposalListScreenState();
}

class _ProposalListScreenState extends State<ProposalListScreen> {
  int filter = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final all = widget.store.board(abroad: widget.abroad);
        final places = <String>{
          for (final p in all)
            if (widget.abroad) countryOf(p.cc).name else p.from,
        }.toList();
        final labels = ['전체', '모집 중', '오늘·내일', ...places];
        final list = all.where((p) {
          final me = widget.store.joined.contains(p.id);
          return switch (filter) {
            0 => true,
            1 => p.openFor(me),
            2 => isNearDay(p.day),
            _ => (widget.abroad ? countryOf(p.cc).name : p.from) == labels[filter],
          };
        }).toList();
        final mineJoined = all.where((p) => widget.store.joined.contains(p.id)).length;

        return PageFrame(
          title: widget.abroad ? '가는 김에 사다 드려요' : '이동하는 길에, 필요한 분?',
          bottom: BigButton(
            label: widget.abroad ? '내가 가는 길에 제안하기' : '내가 이동하는 길에 제안하기',
            icon: 'plus',
            bg: AppColors.ink,
            fg: Colors.white,
            onTap: widget.onPropose,
          ),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              ChipRow(labels: labels, index: filter, onChanged: (i) => setState(() => filter = i)),
              if (mineJoined > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Text(
                    '내가 구매 요청한 제안 $mineJoined건',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.yellowDeep),
                  ),
                ),
              Container(
                margin: const EdgeInsets.fromLTRB(10, 12, 10, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.liveBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.liveLine),
                ),
                child: list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(
                          child: Text('조건에 맞는 제안이 없어요', style: TextStyle(color: AppColors.sub)),
                        ),
                      )
                    : Column(
                        children: [
                          for (final (i, p) in list.indexed) ...[
                            if (i > 0) const SizedBox(height: 6),
                            ProposalRow(p: p, meJoined: widget.store.joined.contains(p.id), onTap: () => widget.onOpen(p)),
                          ],
                        ],
                      ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Text(
                  '물건값은 영수증 기준으로 정산돼요. 제안자가 실제보다 높게 적은 금액은 환불돼요.',
                  style: TextStyle(fontSize: 12, color: AppColors.sub, height: 1.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
