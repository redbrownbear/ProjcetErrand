import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../errand/models/task_item.dart';
import '../../errand/models/trade.dart';

/// 하단 "진행 중" 탭. 지원한 부탁의 단계와 다음 할 일을 보여준다.
///
/// 요청자 수락·완료 확인은 아직 상대방이 연결되지 않아 체험 버튼으로 둔다.
/// 실제 상대방 응답·메시지·결제·정산은 발생하지 않는다.
class ActivityView extends StatefulWidget {
  final List<TaskItem> items;
  final Map<int, Trade> trades;
  final void Function(int id, String action) updateTrade;
  final void Function(TaskItem) openDetail;
  const ActivityView({super.key, required this.items, required this.trades, required this.updateTrade, required this.openDetail});
  @override
  State<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView> {
  String filter = 'active'; // active | finished | all
  int? cancelId;

  // 단계별 [액션, 버튼 문구, 안내]
  static const _next = {
    'pending': ['accept', '요청자 수락 체험', '요청자가 내용을 확인하고 수락하면 매칭돼요.'],
    'matched': ['start', '부탁 시작하기', '장소·구매비·완료 조건을 확인한 뒤 시작하세요.'],
    'working': ['finish', '완료 확인 요청', '전달을 마친 뒤 요청자의 확인을 기다려요.'],
    'confirmation': ['confirm', '요청자 완료 확인 체험', '요청자가 완료를 확인하면 부탁이 끝나요.'],
  };
  static const _steps = ['pending', 'matched', 'working', 'confirmation', 'completed'];
  static const _stepLabels = ['지원', '매칭', '진행', '확인', '완료'];

  @override
  Widget build(BuildContext context) {
    final entries = widget.items.where((i) => widget.trades.containsKey(i.id)).toList()
      ..sort((a, b) => widget.trades[b.id]!.updatedAt.compareTo(widget.trades[a.id]!.updatedAt));
    final visible = entries.where((i) {
      final t = widget.trades[i.id]!;
      return filter == 'all' || (filter == 'finished' ? t.isFinished : t.isActive);
    }).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 26),
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 20, 16, 6), child: Text('진행 중', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink))),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(12)),
          child: const Text('거래 흐름 체험 · 실제 상대방 연결이나 결제는 이루어지지 않아요. 내역은 이 기기에 저장돼요.', style: TextStyle(fontSize: 12.5, color: AppColors.yellowDeep, height: 1.5, fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Row(children: [
            for (final f in const [['active', '진행 중'], ['finished', '완료·취소'], ['all', '전체']])
              Padding(padding: const EdgeInsets.only(right: 6), child: ChipWidget(label: f[1], active: filter == f[0], onTap: () => setState(() => filter = f[0]))),
          ]),
        ),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 50),
            child: Column(children: [
              Text('📋', style: TextStyle(fontSize: 30)),
              SizedBox(height: 10),
              Text('해당하는 부탁이 없어요', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
              SizedBox(height: 4),
              Text('관심 있는 부탁에 지원하면 이곳에서 다음 단계를 확인할 수 있어요.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.sub, height: 1.6)),
            ]),
          ),
        for (final it in visible) _card(it, widget.trades[it.id]!),
      ],
    );
  }

  Widget _card(TaskItem it, Trade trade) {
    final next = _next[trade.status];
    final current = _steps.indexOf(trade.status);
    final statusColor = switch (trade.status) {
      'completed' => AppColors.green,
      'cancelled' => AppColors.sub,
      _ => AppColors.yellowDeep,
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: trade.status == 'completed' ? AppColors.greenSoft : trade.status == 'cancelled' ? AppColors.page : AppColors.yellowSoft, borderRadius: BorderRadius.circular(99)),
            child: Text(trade.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: statusColor)),
          ),
          InkWell(
            onTap: () => widget.openDetail(it),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Expanded(child: Text(it.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink))),
                const Text('›', style: TextStyle(fontSize: 20, color: AppColors.faint)),
              ]),
            ),
          ),
          Text('${it.place ?? '장소 확인 필요'} · ${it.mode == 'together' ? '무료' : '사례비 ${won(it.price)}'}', style: const TextStyle(fontSize: 13, color: AppColors.sub)),
          const SizedBox(height: 14),
          if (trade.status != 'cancelled')
            Row(children: [
              for (int i = 0; i < _steps.length; i++)
                Expanded(
                  child: Column(children: [
                    Container(
                      width: 26, height: 26, alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i < current ? AppColors.ink : i == current ? AppColors.yellow : AppColors.page,
                        shape: BoxShape.circle,
                      ),
                      child: Text(i < current ? '✓' : '${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: i < current ? Colors.white : AppColors.ink)),
                    ),
                    const SizedBox(height: 4),
                    Text(_stepLabels[i], style: TextStyle(fontSize: 11.5, color: i == current ? AppColors.ink : AppColors.sub, fontWeight: i == current ? FontWeight.w800 : FontWeight.w500)),
                  ]),
                ),
            ]),
          const SizedBox(height: 12),
          Text(
            next != null ? next[2] : (trade.status == 'completed' ? '부탁 완료를 체험했어요. 실제 정산 금액은 발생하지 않아요.' : '지원이 취소됐어요. 상세에서 다시 지원할 수 있어요.'),
            style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.5),
          ),
          if (next != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.updateTrade(it.id, next[0]),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(next[1], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                ),
              ),
            ),
          if (trade.status == 'confirmation')
            _link('보완 요청 체험 · 진행 중으로 돌아가기', () => widget.updateTrade(it.id, 'revise')),
          if (trade.canCancel)
            cancelId == it.id
                ? Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('이 부탁의 지원을 취소할까요?', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _outlined('유지하기', () => setState(() => cancelId = null))),
                        const SizedBox(width: 8),
                        Expanded(child: _outlined('지원 취소 확정', () {
                          widget.updateTrade(it.id, 'cancel');
                          setState(() => cancelId = null);
                        }, danger: true)),
                      ]),
                    ]),
                  )
                : _link('지원 취소', () => setState(() => cancelId = it.id)),
        ],
      ),
    );
  }

  Widget _link(String label, VoidCallback onTap) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(foregroundColor: AppColors.sub, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0), minimumSize: const Size(0, 44)),
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
        ),
      );

  Widget _outlined(String label, VoidCallback onTap, {bool danger = false}) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: danger ? AppColors.red : AppColors.ink,
          side: const BorderSide(color: AppColors.line, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
      );
}
