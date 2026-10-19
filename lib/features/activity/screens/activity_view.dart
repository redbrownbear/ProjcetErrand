import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../errand/models/application.dart';
import '../../errand/models/task_item.dart';
import '../../errand/models/trade.dart';

/// "진행 중인 부탁". 내 부탁에 들어온 지원(요청자)과, 지원·거래의 단계와 다음 할 일을 보여준다.
///
/// 단계마다 누를 수 있는 사람이 정해져 있다 — 수행자: 시작·완료 요청 / 요청자: 수락·완료 확인·보완 요청.
/// 실제 판단은 서버 함수가 한다(functions/src/domain/tradeMachine.ts). 결제·정산은 아직 없다.
class ActivityView extends StatefulWidget {
  final List<TaskItem> items;
  final Map<int, Trade> trades;
  final void Function(int id, String action) updateTrade;
  final void Function(TaskItem) openDetail;

  /// 내 부탁에 들어와 답을 기다리는 지원
  final List<Application> received;
  final void Function(Application) onAccept;
  final void Function(Application) onReject;

  /// 전체화면으로 띄울 때는 바깥 [ScreenFrame]이 제목을 그리므로 false를 준다.
  final bool showHeader;
  const ActivityView({
    super.key,
    required this.items,
    required this.trades,
    required this.updateTrade,
    required this.openDetail,
    this.received = const [],
    this.onAccept = _noop,
    this.onReject = _noop,
    this.showHeader = true,
  });
  static void _noop(Application _) {}
  @override
  State<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView> {
  String filter = 'active'; // active | finished | all
  int? cancelId;

  // 단계별 [액션(없으면 ''), 버튼 문구, 안내] — 수행자(내가 지원한 부탁)
  static const _helperNext = {
    'pending': ['', '', '요청자가 지원을 확인하고 수락하면 매칭돼요.'],
    'matched': ['start', '부탁 시작하기', '장소·구매비·완료 조건을 확인한 뒤 시작하세요.'],
    'working': ['finish', '완료 확인 요청', '전달을 마쳤으면 요청자에게 완료 확인을 요청하세요.'],
    'confirmation': ['', '', '요청자가 완료를 확인하면 부탁이 끝나요.'],
  };

  // 요청자(내가 올린 부탁)
  static const _requesterNext = {
    'matched': ['', '', '수행자가 부탁을 시작하면 진행 중으로 바뀌어요.'],
    'working': ['', '', '수행자가 부탁을 진행하고 있어요.'],
    'confirmation': ['confirm', '완료 확인하기', '받은 물건·결과를 확인한 뒤 완료를 눌러 주세요.'],
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
        if (widget.showHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 8),
            child: Text('진행 중', style: AppType.tabTitle),
          ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(12)),
          child: const Text(
            '지원·수락·완료는 상대방에게 바로 전달돼요. 앱 안의 결제·정산은 아직 없어서 사례비는 직접 주고받아요.',
            style: TextStyle(fontSize: 12.5, color: AppColors.yellowDeep, height: 1.5, fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Row(
            children: [
              for (final f in const [
                ['active', '진행 중'],
                ['finished', '완료·취소'],
                ['all', '전체'],
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChipWidget(label: f[1], active: filter == f[0], onTap: () => setState(() => filter = f[0])),
                ),
            ],
          ),
        ),
        if (widget.received.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(
              '받은 지원 ${widget.received.length}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
          ),
          for (final a in widget.received) _receivedCard(a),
          const SizedBox(height: 6),
        ],
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 50),
            child: Column(
              children: [
                AppIcon('clipboard', size: 26, color: AppColors.ink2),
                SizedBox(height: 10),
                Text(
                  '해당하는 부탁이 없어요',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                SizedBox(height: 4),
                Text(
                  '관심 있는 부탁에 지원하면 이곳에서 다음 단계를 확인할 수 있어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.sub, height: 1.6),
                ),
              ],
            ),
          ),
        for (final it in visible) _card(it, widget.trades[it.id]!),
      ],
    );
  }

  Widget _receivedCard(Application a) => Container(
    margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(a.requestTitle, style: const TextStyle(fontSize: 13, color: AppColors.sub)),
        const SizedBox(height: 4),
        Text(
          '${a.helperName}님이 지원했어요',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        if (a.offerPrice != null || (a.msg?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 6),
          Text(
            [if (a.offerPrice != null) '제안 ${won(a.offerPrice!)}', if (a.msg?.isNotEmpty ?? false) a.msg!].join(' · '),
            style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.5),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _outlined('거절', () => widget.onReject(a))),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => widget.onAccept(a),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('수락하기', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _card(TaskItem it, Trade trade) {
    final requester = it.isMine;
    final step = (requester ? _requesterNext : _helperNext)[trade.status];
    final next = step != null && step[0].isNotEmpty ? step : null;
    final current = _steps.indexOf(trade.status);
    final statusColor = switch (trade.status) {
      'completed' => AppColors.green,
      'cancelled' => AppColors.sub,
      _ => AppColors.yellowDeep,
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: trade.status == 'completed'
                  ? AppColors.greenSoft
                  : trade.status == 'cancelled'
                  ? AppColors.page
                  : AppColors.yellowSoft,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              trade.label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: statusColor),
            ),
          ),
          InkWell(
            onTap: () => widget.openDetail(it),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      it.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                  ),
                  const Text('›', style: TextStyle(fontSize: 20, color: AppColors.faint)),
                ],
              ),
            ),
          ),
          Text(
            '${it.place ?? '장소 확인 필요'} · ${it.mode == 'together' ? '무료' : '사례비 ${won(it.price)}'}',
            style: const TextStyle(fontSize: 13, color: AppColors.sub),
          ),
          const SizedBox(height: 14),
          if (trade.status != 'cancelled')
            Row(
              children: [
                for (int i = 0; i < _steps.length; i++)
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i < current
                                ? AppColors.ink
                                : i == current
                                ? AppColors.yellow
                                : AppColors.page,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            i < current ? '✓' : '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: i < current ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _stepLabels[i],
                          style: TextStyle(
                            fontSize: 11.5,
                            color: i == current ? AppColors.ink : AppColors.sub,
                            fontWeight: i == current ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Text(
            step != null
                ? step[2]
                : (trade.status == 'completed'
                      ? '부탁이 완료됐어요. 앱 안의 결제·정산은 아직 없어요.'
                      : requester
                      ? '거래가 취소됐어요.'
                      : '지원이 취소되거나 거절됐어요.'),
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
                    backgroundColor: AppColors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(next[1], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                ),
              ),
            ),
          if (requester && trade.status == 'confirmation') _link('보완 요청 · 진행 중으로 돌아가기', () => widget.updateTrade(it.id, 'revise')),
          if (trade.canCancel)
            cancelId == it.id
                ? Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trade.status == 'pending' ? '이 부탁의 지원을 취소할까요?' : '시작 전인 거래를 취소할까요?',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _outlined('유지하기', () => setState(() => cancelId = null))),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _outlined('취소 확정', () {
                                widget.updateTrade(it.id, 'cancel');
                                setState(() => cancelId = null);
                              }, danger: true),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : _link(trade.status == 'pending' ? '지원 취소' : '거래 취소', () => setState(() => cancelId = it.id)),
        ],
      ),
    );
  }

  Widget _link(String label, VoidCallback onTap) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.sub,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        minimumSize: const Size(0, 44),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
      ),
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
