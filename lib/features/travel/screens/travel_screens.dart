import 'package:flutter/material.dart';

import '../../../core/backend/server_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../../core/widgets/kit.dart';
import '../../errand/data/countries.dart';
import '../../errand/widgets/task_card.dart';
import '../models/travel_plan.dart';
import '../repositories/travel_repository.dart';

String _md(DateTime d) => '${d.month}.${d.day}';

/// 마이 › 내 여행 일정 (개발 To-do A11). 나라 · 도시 · 출국일 · 귀국일을 적어 둔다.
/// 해외 사다주기(B04)가 열리기 전까지는 모아 두기만 하고, 다른 사람에게 보이지 않는다.
class TravelListScreen extends StatelessWidget {
  final String uid;
  final TravelRepository? repo;

  /// 테스트에서 오늘 날짜를 고정한다
  final DateTime? today;
  const TravelListScreen({super.key, required this.uid, this.repo, this.today});

  @override
  Widget build(BuildContext context) {
    final r = repo ?? TravelRepository(uid);
    final now = today ?? DateTime.now();
    return StreamBuilder<List<TravelPlan>>(
      stream: r.watch(),
      builder: (context, snap) {
        final list = TravelPlan.sorted(snap.data ?? const <TravelPlan>[], now);
        final full = list.length >= TravelPlan.maxPlans;
        void edit([TravelPlan? plan]) => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => TravelEditScreen(repo: r, plan: plan, count: list.length, today: today)),
        );
        final past = list.where((p) => p.stateOn(now) == 'past').toList();
        final coming = list.where((p) => p.stateOn(now) != 'past').toList();
        return PageFrame(
          title: '내 여행 일정',
          bottom: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: BigButton(
              label: full ? '일정은 ${TravelPlan.maxPlans}개까지예요' : '여행 일정 추가하기',
              onTap: full ? null : () => edit(),
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Text(
                '출국 일정을 적어 두면, 해외 사다주기가 열릴 때 그 나라 부탁을 먼저 알려 드릴게요. '
                '일정은 나만 볼 수 있어요.',
                style: AppType.meta.copyWith(fontSize: 13, height: 1.55),
              ),
              const SizedBox(height: 14),
              if (snap.connectionState == ConnectionState.waiting && list.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              else if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Text(
                    '아직 적어 둔 여행이 없어요.\n출국 예정이 있으면 적어 보세요.',
                    textAlign: TextAlign.center,
                    style: AppType.meta.copyWith(fontSize: 13.5, height: 1.6),
                  ),
                )
              else ...[
                for (final p in coming) _TravelCard(plan: p, today: now, onEdit: () => edit(p), onDelete: () => r.delete(p.id)),
                if (past.isNotEmpty) ...[
                  Padding(padding: const EdgeInsets.fromLTRB(4, 12, 0, 8), child: Text('지난 여행', style: AppType.sectionSmall)),
                  for (final p in past) _TravelCard(plan: p, today: now, onDelete: () => r.delete(p.id)),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TravelCard extends StatefulWidget {
  final TravelPlan plan;
  final DateTime today;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;
  const _TravelCard({required this.plan, required this.today, this.onEdit, required this.onDelete});

  @override
  State<_TravelCard> createState() => _TravelCardState();
}

class _TravelCardState extends State<_TravelCard> {
  bool confirm = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.plan;
    final state = p.stateOn(widget.today);
    final dim = state == 'past';
    final left = p.daysLeft(widget.today);
    final badge = switch (state) {
      'away' => '여행 중',
      'upcoming' => left == 0 ? '오늘 출국' : 'D-$left',
      _ => '다녀옴',
    };
    final country = countryOf(p.cc).name;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CountryFlag(cc: p.cc, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.city.isEmpty ? country : '$country · ${p.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.body.copyWith(fontSize: 15, fontWeight: AppType.w700, color: dim ? AppColors.sub : AppColors.ink),
                    ),
                    Text(
                      '${_md(p.depart)} 출국 → ${_md(p.back)} 귀국 · ${p.days}일',
                      style: AppType.meta.copyWith(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: state == 'past' ? AppColors.page : AppColors.yellowSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badge, style: AppType.meta.copyWith(fontWeight: AppType.w700, color: dim ? AppColors.sub : AppColors.yellowInk)),
              ),
            ],
          ),
          if (p.takeAsks || p.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 48),
              child: Text(
                [if (p.takeAsks) '해외 부탁 받아 볼 생각 있음', if (p.note.isNotEmpty) p.note].join(' · '),
                style: AppType.meta,
              ),
            ),
          Row(
            children: [
              const SizedBox(width: 40),
              if (widget.onEdit != null) TextButton(onPressed: widget.onEdit, child: const Text('고치기')),
              TextButton(
                onPressed: () {
                  if (confirm) {
                    widget.onDelete();
                  } else {
                    setState(() => confirm = true);
                  }
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.red),
                child: Text(confirm ? '한 번 더 누르면 지워져요' : '지우기'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 여행 일정 추가 · 고치기. 나라 → 도시 → 날짜 → 해외 부탁 생각 순으로, 대부분 칩을 누르는 것으로 끝난다.
class TravelEditScreen extends StatefulWidget {
  final TravelRepository repo;
  final TravelPlan? plan;

  /// 지금 적어 둔 일정 수(새로 만들 때 상한 확인)
  final int count;
  final DateTime? today;
  const TravelEditScreen({super.key, required this.repo, this.plan, this.count = 0, this.today});

  @override
  State<TravelEditScreen> createState() => _TravelEditScreenState();
}

class _TravelEditScreenState extends State<TravelEditScreen> {
  late final DateTime today = widget.today ?? DateTime.now();
  late String? cc = widget.plan?.cc;
  late final TextEditingController city = TextEditingController(text: widget.plan?.city ?? '');
  late final TextEditingController note = TextEditingController(text: widget.plan?.note ?? '');
  late DateTimeRange? range = widget.plan == null ? null : DateTimeRange(start: widget.plan!.depart, end: widget.plan!.back);
  late bool takeAsks = widget.plan?.takeAsks ?? false;
  bool saving = false;
  String? error;

  @override
  void dispose() {
    city.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final first = DateTime(today.year, today.month, today.day);
    final r = await showDateRangePicker(
      context: context,
      firstDate: range != null && range!.start.isBefore(first) ? range!.start : first,
      lastDate: first.add(const Duration(days: TravelPlan.maxAheadDays + TravelPlan.maxStayDays)),
      initialDateRange: range,
      helpText: '출국일 · 귀국일',
      saveText: '확인',
    );
    if (r != null) setState(() => range = r);
  }

  TravelPlan? get _plan => cc == null || range == null
      ? null
      : TravelPlan(
          id: widget.plan?.id ?? '',
          cc: cc!,
          city: city.text.trim(),
          depart: range!.start,
          back: range!.end,
          takeAsks: takeAsks,
          note: note.text.trim(),
        );

  Future<void> _save() async {
    final p = _plan;
    if (p == null) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.repo.save(p, existing: widget.count, today: today);
      if (mounted) Navigator.pop(context);
    } on ServerException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(t, style: AppType.sectionSmall),
  );

  @override
  Widget build(BuildContext context) {
    final cities = cc == null ? const <String>[] : countryOf(cc).cities;
    final r = range;
    return PageFrame(
      title: widget.plan == null ? '여행 일정 추가' : '여행 일정 고치기',
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: BigButton(label: saving ? '저장하는 중…' : '저장하기', onTap: _plan != null && !saving ? _save : null),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _label('어느 나라로 가요?'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in countries)
                ChipWidget(
                  label: c.name,
                  active: cc == c.cc,
                  onTap: () => setState(() {
                    if (cc != c.cc) city.clear();
                    cc = c.cc;
                  }),
                ),
            ],
          ),
          if (cc != null) ...[
            _label('도시 (선택)'),
            if (cities.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final n in cities)
                    ChipWidget(label: n, active: city.text == n, onTap: () => setState(() => city.text = city.text == n ? '' : n)),
                ],
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: city,
              maxLength: 30,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: '직접 적기', counterText: ''),
            ),
          ],
          _label('언제 가요?'),
          LineButton(
            label: r == null ? '출국일 · 귀국일 고르기' : '${_md(r.start)} 출국 → ${_md(r.end)} 귀국 · ${r.duration.inDays + 1}일',
            height: 46,
            onTap: _pickDates,
          ),
          _label('가는 길에'),
          Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            child: SwitchListTile(
              value: takeAsks,
              onChanged: (v) => setState(() => takeAsks = v),
              activeTrackColor: AppColors.green,
              title: Text('해외 부탁을 받아 볼 생각이 있어요', style: AppType.body.copyWith(fontWeight: AppType.w600)),
              subtitle: Text('해외 사다주기는 아직 준비 중이에요. 열리면 이 나라 부탁을 먼저 알려 드릴게요.', style: AppType.meta),
            ),
          ),
          _label('메모 (선택)'),
          TextField(
            controller: note,
            maxLength: 60,
            decoration: const InputDecoration(hintText: '예: 출장이라 시간 여유는 적어요', counterText: ''),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(error!, style: AppType.meta.copyWith(color: AppColors.red, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
