import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_nav.dart';
import '../../../core/compliance/safety_policy.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/kit.dart';
import '../../errand/models/application.dart';
import '../../errand/models/going_deal.dart';
import '../../errand/models/task_item.dart';
import '../widgets/trip_parts.dart';

/// 가는 김에(시안 v78 '어! 나도!')의 화면들 — 나 여기 가요 · 일정 상세(어! 나도) · 내 일정 · 내 활동.
///
/// 흐름: 가는 사람이 장소·시각을 올린다 → 이웃이 '어! 나도!'로 필요한 걸 보낸다 → 가는 사람이 수락한 것만 진행한다
/// (부탁 → 수락 → 구매 → 전달). 서버에서는 부탁(mode `going`)과 신청서·거래 흐름 그대로다.
/// 앱 안의 결제는 아직 없어서 물건값과 부탁 비용은 만나서 직접 주고받는다.

final _still = ValueNotifier<int>(0);
Listenable _listen(AppNav nav) => nav.session ?? _still;

TaskItem? _find(AppNav nav, int id) {
  for (final t in [...nav.items(), ...tripList(nav)]) {
    if (t.id == id) return t;
  }
  return null;
}

void _needLogin(AppNav nav, VoidCallback f) {
  final gate = nav.requireLogin;
  if (gate == null) {
    f();
  } else {
    gate(f);
  }
}

Future<void> _push(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

/// 일정을 연다 — 내 일정이면 받은 부탁 관리, 남의 일정이면 '어! 나도' 시트
void openTrip(BuildContext context, AppNav nav, TaskItem t) {
  if (t.isMine && !t.sample) {
    _push(context, MyTripScreen(nav: nav, id: t.id));
  } else {
    showSheet(context, (_) => _TripSheet(nav: nav, id: t.id, initial: t));
  }
}

void openTripRegister(BuildContext context, AppNav nav) =>
    _needLogin(nav, () => _push(context, TripRegisterScreen(nav: nav)));

void openTripActivity(BuildContext context, AppNav nav) => _push(context, TripActivityScreen(nav: nav));

// ── 나 여기 가요 ──────────────────────────────────────────────────────────

class TripRegisterScreen extends StatefulWidget {
  final AppNav nav;
  const TripRegisterScreen({super.key, required this.nav});

  @override
  State<TripRegisterScreen> createState() => _TripRegisterScreenState();
}

class _TripRegisterScreenState extends State<TripRegisterScreen> {
  static const _quick = ['이마트', '홈플러스', '편의점', '올리브영', '다이소', '약국', '카페', '치킨집', '역 근처'];

  final place = TextEditingController();
  final note = TextEditingController(text: '간 김에 뭐 사다드릴까요?');
  late int day; // 0 오늘 · 1 내일
  late TimeOfDay time;
  final kinds = <String>{'사다주기'};
  int max = 3;
  (double, double)? pick;
  String? error;

  @override
  void initState() {
    super.initState();
    // 한 시간 뒤를 30분 단위로 올린 시각
    final now = DateTime.now().add(const Duration(hours: 1));
    final def = now.minute == 0 ? now : DateTime(now.year, now.month, now.day, now.hour, now.minute <= 30 ? 30 : 0).add(Duration(hours: now.minute <= 30 ? 0 : 1));
    final today = DateTime.now();
    day = def.day == today.day ? 0 : 1;
    time = TimeOfDay(hour: def.hour, minute: def.minute);
  }

  @override
  void dispose() {
    place.dispose();
    note.dispose();
    super.dispose();
  }

  DateTime get _goAt {
    final d = DateTime.now().add(Duration(days: day));
    return DateTime(d.year, d.month, d.day, time.hour, time.minute);
  }

  void _quickPick(String name) {
    final cur = place.text.trim();
    place.text = cur.isNotEmpty && !_quick.contains(cur) ? '$cur $name' : name;
    setState(() => error = null);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: time);
    if (t != null) setState(() => time = t);
  }

  void _submit() {
    final p = place.text.trim();
    if (p.length < 2) {
      setState(() => error = '가시는 곳을 2자 이상 적어 주세요');
      return;
    }
    if (_goAt.isBefore(DateTime.now().add(const Duration(minutes: 5)))) {
      setState(() => error = '지금보다 5분 이후 시각으로 정해 주세요');
      return;
    }
    final session = widget.nav.session;
    if (session == null) return;
    session.addTrip(
      place: p,
      goAt: _goAt,
      note: note.text.trim(),
      kinds: [for (final k in tripKinds) if (kinds.contains(k)) k],
      capacity: max,
      lat: pick?.$1,
      lng: pick?.$2,
    );
    final at = _goAt;
    Navigator.pop(context);
    showSheet(
      context,
      (ctx) => SheetFrame(
        bottom: BigButton(label: '확인', onTap: () => Navigator.pop(ctx)),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, size: 44, color: AppColors.green),
            const SizedBox(height: 10),
            Text(pick == null ? '일정을 올렸어요' : '지도에 떴어요', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              '${tripDay(at)} ${tripTime(at)} · $p\n이웃이 "어! 나도" 하면 알려드릴게요',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.sub, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final at = _goAt;
    return PageFrame(
      title: '나 여기 가요',
      background: AppColors.card,
      bottom: BigButton(label: '지도에 올리기', bg: AppColors.ink, fg: Colors.white, onTap: _submit),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        children: [
          const FieldLabel('어디 가세요?'),
          TextField(
            controller: place,
            maxLength: 30,
            onChanged: (_) => setState(() => error = null),
            decoration: const InputDecoration(hintText: '예) 죽전역 이마트', counterText: ''),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final q in _quick) _chip(q, false, () => _quickPick(q))],
          ),
          const FieldLabel('지도에 콕 찍어도 돼요', hint: '선택 · 찍으면 이웃 지도에 핀이 떠요'),
          TripMap(
            trips: const [],
            scope: widget.nav.session?.scope ?? '전국',
            height: 200,
            onOpen: (_) {},
            picked: pick,
            onPick: (lat, lng) => setState(() => pick = (lat, lng)),
          ),
          if (pick != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () => setState(() => pick = null), child: const Text('찍은 위치 지우기')),
            ),
          const FieldLabel('언제 가세요?'),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    for (final (i, l) in [(0, '오늘'), (1, '내일')])
                      GestureDetector(
                        onTap: () => setState(() => day = i),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: day == i ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            l,
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: day == i ? AppColors.ink : AppColors.sub),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: Text(tripTime(at), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.line, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
          const FieldLabel('이웃에게 한마디', hint: '선택'),
          TextField(
            controller: note,
            maxLength: 40,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(counterText: ''),
          ),
          const FieldLabel('어떤 부탁을 받을까요?'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final k in tripKinds)
                _chip(k, kinds.contains(k), () {
                  setState(() {
                    if (kinds.contains(k)) {
                      if (kinds.length > 1) kinds.remove(k);
                    } else {
                      kinds.add(k);
                    }
                  });
                }),
            ],
          ),
          const FieldLabel('최대 몇 건까지 받을까요?'),
          Row(
            children: [
              _stepBtn('−', max > 1 ? () => setState(() => max--) : null),
              SizedBox(
                width: 48,
                child: Text('$max', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ),
              _stepBtn('+', max < 5 ? () => setState(() => max++) : null),
              const SizedBox(width: 8),
              const Text('건', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.sub)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.yellowSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3E2A3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('이렇게 보여요', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.yellowInk)),
                const SizedBox(height: 4),
                Text(
                  '${tripDay(at)} ${tripTime(at)} · ${place.text.trim().isEmpty ? '가시는 곳' : place.text.trim()}',
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                ),
                if (note.text.trim().isNotEmpty)
                  Text('“${note.text.trim()}”', style: const TextStyle(fontSize: 13.5, color: AppColors.ink2)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '부탁은 내가 수락한 것만 진행해요. 주류·담배·의약품은 받을 수 없고, 물건값은 건당 ${nf(tripMaxItemPrice)}원까지예요. '
            '앱 안의 결제는 아직 없어서 물건값·부탁 비용은 만나서 직접 주고받아요.',
            style: const TextStyle(fontSize: 12.5, color: AppColors.sub, height: 1.5),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.red)),
            ),
        ],
      ),
    );
  }
}

Widget _chip(String label, bool on, VoidCallback onTap) => GestureDetector(
  onTap: onTap,
  child: Container(
    height: 32,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    alignment: Alignment.center,
    decoration: BoxDecoration(color: on ? AppColors.ink : AppColors.page, borderRadius: BorderRadius.circular(16)),
    child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: on ? Colors.white : AppColors.ink2)),
  ),
);

Widget _stepBtn(String label, VoidCallback? onTap) => GestureDetector(
  onTap: onTap,
  child: Container(
    width: 44,
    height: 44,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(14)),
    child: Text(label, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: onTap == null ? AppColors.faint : AppColors.ink)),
  ),
);

// ── 이웃 일정 상세 · 어! 나도 ─────────────────────────────────────────────

class _TripSheet extends StatefulWidget {
  final AppNav nav;
  final int id;
  final TaskItem initial;
  const _TripSheet({required this.nav, required this.id, required this.initial});

  @override
  State<_TripSheet> createState() => _TripSheetState();
}

class _TripSheetState extends State<_TripSheet> {
  final item = TextEditingController();
  final price = TextEditingController();
  int? fee;
  String spot = '문 앞';
  String? error;
  bool sending = false;

  @override
  void dispose() {
    item.dispose();
    price.dispose();
    super.dispose();
  }

  int get _price => int.tryParse(price.text) ?? 0;
  int get _fee => fee ?? recommendedFee(_price);

  Future<void> _send(TaskItem t) async {
    final what = item.text.trim();
    final problem = what.length < 2
        ? '부탁할 물건을 2자 이상 적어 주세요'
        : SafetyPolicy.findBlocked(what) != null
        ? SafetyPolicy.blockedMessage(SafetyPolicy.findBlocked(what)!)
        : _price > tripMaxItemPrice
        ? '물건값은 건당 ${nf(tripMaxItemPrice)}원까지 부탁할 수 있어요'
        : null;
    if (problem != null) {
      setState(() => error = problem);
      return;
    }
    final session = widget.nav.session;
    if (session == null) return;
    _needLogin(widget.nav, () async {
      setState(() => sending = true);
      final ok = await session.askGoing(t, what, _fee, est: _price, spot: spot);
      if (!mounted) return;
      setState(() => sending = false);
      if (ok) item.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _listen(widget.nav),
      builder: (context, _) {
        final t = _find(widget.nav, widget.id) ?? widget.initial;
        final at = tripAt(t);
        final ask = widget.nav.session?.myGoingAsk(t.id);
        final active = ask != null && ask.stageIndex >= 0;
        return SheetFrame(
          bottom: _bottom(t, active ? ask : null),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(8)),
                    child: Text('${tripDay(at)} ${tripTime(at)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    [t.who, if (t.sample && t.ago != null) t.ago!, if (t.sample) '예시'].join(' · '),
                    style: const TextStyle(fontSize: 13, color: AppColors.sub, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('${t.place ?? t.title}에 가요', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
              if (t.desc.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('“${t.desc}”', style: const TextStyle(fontSize: 14.5, color: AppColors.ink2)),
                ),
              if (t.kinds.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, children: [for (final k in t.kinds) _chip(k, false, () {})]),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < t.capacity; i++)
                    Container(
                      width: 22,
                      height: 8,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: i < t.acceptedCount ? AppColors.yellow : AppColors.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    '${t.acceptedCount}명 어! 나도 · ${t.closed ? '접수 마감' : (t.seatsLeft > 0 ? '${t.seatsLeft}자리 남음' : '마감')}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink2),
                  ),
                ],
              ),
              if (active)
                _status(ask)
              else if (t.sample)
                _note('체험용 예시 일정이라 부탁할 수 없어요. 실제 이웃 일정에서 "어! 나도!"를 눌러 보세요.')
              else if (!t.takesAsks)
                _note(t.closed ? '글쓴이가 부탁 접수를 마감했어요.' : '자리가 다 찼거나 시간이 지났어요.')
              else
                _form(),
            ],
          ),
        );
      },
    );
  }

  Widget _note(String text) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(14)),
    child: Text(text, style: const TextStyle(fontSize: 13.5, color: AppColors.sub, height: 1.5)),
  );

  Widget _form() {
    final p = _price;
    final fees = {1000, 2000, 3000, 5000, recommendedFee(p)}.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.yellowSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF3E2A3)),
          ),
          child: const Text('어! 나도, 하나만 사다 주세요', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ),
        const FieldLabel('뭐가 필요해요?'),
        TextField(
          controller: item,
          maxLength: 40,
          onChanged: (_) => setState(() => error = null),
          decoration: const InputDecoration(hintText: '예) 우유 1L, 식빵 1봉', counterText: ''),
        ),
        const FieldLabel('예상 물건값', hint: '영수증 보고 맞춰요'),
        TextField(
          controller: price,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() => error = null),
          decoration: const InputDecoration(hintText: '0', suffixText: '원'),
        ),
        FieldLabel('부탁 비용', hint: p > 0 ? '이 가격대 추천 ${nf(recommendedFee(p))}원' : null),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final v in fees) _chip('${nf(v)}원', v == _fee, () => setState(() => fee = v))],
        ),
        const FieldLabel('어디서 받을까요?'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final v in const ['문 앞', '가까운 역', '직접 만나서']) _chip(v, v == spot, () => setState(() => spot = v))],
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('만나서 드릴 금액', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sub)),
                  ),
                  Text(won(p + _fee), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '물건값 ${won(p)} + 부탁 비용 ${won(_fee)} · 영수증을 보고 실제 물건값으로 맞춰요. 앱 안의 결제는 아직 없어요.',
                style: const TextStyle(fontSize: 11.5, color: AppColors.sub, height: 1.45),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.red)),
          ),
      ],
    );
  }

  Widget _status(GoingDeal d) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(d.ask, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
              TripTag(d.stage, d.stageIndex),
            ],
          ),
          TripStageBar(d.stageIndex),
          const SizedBox(height: 8),
          _kv('만나서 드릴 금액', '${won((d.est ?? 0) + d.price)} (물건값 ${won(d.est ?? 0)} + 부탁 비용 ${won(d.price)})'),
          if (d.spot != null) _kv('받는 곳', d.spot!),
          if (d.status == 'confirmation')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('구매했대요. 물건을 받았으면 "받았어요"를 눌러 주세요.', style: TextStyle(fontSize: 13, color: AppColors.blue, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 92, child: Text(k, style: const TextStyle(fontSize: 13, color: AppColors.sub, fontWeight: FontWeight.w600))),
        Expanded(child: Text(v, style: const TextStyle(fontSize: 13.5, height: 1.45))),
      ],
    ),
  );

  Widget? _bottom(TaskItem t, GoingDeal? d) {
    final session = widget.nav.session;
    if (d != null && session != null) {
      final chat = d.tradeId != null && widget.nav.openChat != null && d.status != 'cancelled';
      return Row(
        children: [
          if (d.status == 'pending')
            Expanded(
              child: BigButton(label: '부탁 취소', bg: AppColors.page, onTap: () => session.advanceDeal(d, 'cancel')),
            ),
          if (chat)
            Expanded(
              child: BigButton(label: '채팅하기', bg: AppColors.page, onTap: () => widget.nav.openChat!(d.tradeId!)),
            ),
          if (d.status == 'confirmation') ...[
            const SizedBox(width: 8),
            Expanded(child: BigButton(label: '받았어요', onTap: () => session.advanceDeal(d, 'confirm'))),
          ],
        ],
      );
    }
    if (t.sample || !t.takesAsks || t.isMine) return BigButton(label: '닫기', bg: AppColors.page, onTap: () => Navigator.pop(context));
    return Row(
      children: [
        Expanded(child: BigButton(label: '취소', bg: AppColors.page, onTap: () => Navigator.pop(context))),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: BigButton(label: sending ? '보내는 중…' : '어! 나도!', onTap: sending ? null : () => _send(t))),
      ],
    );
  }
}

// ── 내 일정 · 받은 부탁 ───────────────────────────────────────────────────

class MyTripScreen extends StatelessWidget {
  final AppNav nav;
  final int id;
  const MyTripScreen({super.key, required this.nav, required this.id});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _listen(nav),
      builder: (context, _) {
        final session = nav.session;
        final t = _find(nav, id);
        if (t == null || session == null) {
          return const PageFrame(title: '내 일정', child: Center(child: Text('지난 일정이에요', style: TextStyle(color: AppColors.sub))));
        }
        final at = tripAt(t);
        final waiting = session.receivedFor(id);
        final taken = session.takenFor(id);
        final ended = t.isExpired;
        return PageFrame(
          title: '내 일정',
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.yellowSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF3E2A3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${tripDay(at)} ${tripTime(at)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(t.place ?? t.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    if (t.desc.isNotEmpty) Text('“${t.desc}”', style: const TextStyle(fontSize: 13.5, color: AppColors.ink2)),
                    const SizedBox(height: 6),
                    Text(
                      '${t.acceptedCount}/${t.capacity}명 수락${t.closed ? ' · 접수 마감' : ''}${ended ? ' · 종료' : ''}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.sub, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (!ended) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: BigButton(
                        label: t.closed ? '접수 다시 열기' : '접수 마감하기',
                        bg: AppColors.page,
                        height: 44,
                        onTap: () => session.setTripClosed(t, !t.closed),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BigButton(
                        label: '일정 취소',
                        bg: AppColors.page,
                        height: 44,
                        onTap: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('일정을 취소할까요?'),
                              content: const Text('답을 기다리던 부탁은 거절로 알려요. 이미 수락한 부탁은 진행 중인 부탁에서 따로 정리해 주세요.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('유지')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('일정 취소')),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          if (await session.cancelTrip(t) && context.mounted) Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 8),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink2),
                    children: [
                      const TextSpan(text: '받은 부탁 '),
                      TextSpan(text: '${waiting.length + taken.length}', style: const TextStyle(color: AppColors.ink)),
                    ],
                  ),
                ),
              ),
              if (waiting.isEmpty && taken.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                  decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(18)),
                  child: const Text('아직 부탁이 없어요. 이웃이 "어! 나도" 하면 알림으로 알려드려요.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.sub, height: 1.5)),
                ),
              for (final a in waiting) _waitingCard(context, a, full: t.seatsLeft == 0),
              for (final d in taken) _takenCard(context, d),
            ],
          ),
        );
      },
    );
  }

  Widget _card({required String name, required String item, required Widget tag, required List<String> meta, Widget? actions}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(name, size: 30),
                const SizedBox(width: 10),
                Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                tag,
              ],
            ),
            const SizedBox(height: 10),
            Text(item, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [for (final m in meta) Text(m, style: const TextStyle(fontSize: 12, color: AppColors.sub, fontWeight: FontWeight.w600))],
            ),
            if (actions != null) ...[const SizedBox(height: 12), actions],
          ],
        ),
      );

  Widget _waitingCard(BuildContext context, Application a, {required bool full}) {
    final session = nav.session!;
    return _card(
      name: a.helperName,
      item: a.msg ?? '',
      tag: const TripTag('답을 기다려요', 0),
      meta: [
        '예상 물건값 ${won(a.est ?? 0)}',
        '부탁 비용 ${won(a.offerPrice ?? 0)}',
        if (a.spot != null) '받는 곳 ${a.spot}',
      ],
      actions: Row(
        children: [
          Expanded(child: BigButton(label: '거절', bg: AppColors.page, height: 44, onTap: () => session.rejectApplication(a))),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: BigButton(label: full ? '자리가 다 찼어요' : '수락', height: 44, onTap: full ? null : () => session.acceptApplication(a)),
          ),
        ],
      ),
    );
  }

  Widget _takenCard(BuildContext context, GoingDeal d) {
    final session = nav.session!;
    final chat = d.tradeId != null && nav.openChat != null && d.status != 'cancelled';
    return _card(
      name: d.counterpart ?? '이웃',
      item: d.ask,
      tag: TripTag(d.stage, d.stageIndex),
      meta: ['예상 물건값 ${won(d.est ?? 0)}', '부탁 비용 ${won(d.price)}', if (d.spot != null) '받는 곳 ${d.spot}'],
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (d.status == 'matched' || d.status == 'working')
            BigButton(label: '구매 완료', height: 44, onTap: () => session.markBought(d)),
          if (d.status == 'confirmation')
            const Text('구매 완료를 알렸어요 · 받는 분이 확인하면 끝나요. 영수증은 채팅으로 보여 주세요.', style: TextStyle(fontSize: 12.5, color: AppColors.sub, fontWeight: FontWeight.w700)),
          if (d.status == 'completed')
            Text('전달 완료 · 부탁 비용 ${won(d.price)} + 물건값은 직접 받아요', style: const TextStyle(fontSize: 12.5, color: AppColors.green, fontWeight: FontWeight.w700)),
          if (chat)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () => nav.openChat!(d.tradeId!), child: const Text('채팅하기')),
            ),
          if (d.status == 'matched')
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => session.advanceDeal(d, 'cancel'),
                style: TextButton.styleFrom(foregroundColor: AppColors.sub),
                child: const Text('시작 전 취소'),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 내 활동 ───────────────────────────────────────────────────────────────

class TripActivityScreen extends StatelessWidget {
  final AppNav nav;
  const TripActivityScreen({super.key, required this.nav});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _listen(nav),
      builder: (context, _) {
        final session = nav.session;
        final mineTrips = [for (final t in nav.items()) if (t.isGoing && t.isMine && !t.sample) t]
          ..sort((a, b) => tripAt(b).compareTo(tripAt(a)));
        final asks = [for (final d in session?.goingDeals ?? const <GoingDeal>[]) if (d.requester) d];
        final earned = [
          for (final d in session?.goingDeals ?? const <GoingDeal>[]) if (!d.requester && d.status == 'completed') d.price,
        ].fold(0, (a, b) => a + b);
        Widget sec(String s) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text(s, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink2)),
        );
        Widget none(String s) => Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(18)),
          child: Text(s, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.sub)),
        );
        return PageFrame(
          title: '내 활동',
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
            children: [
              sec('내가 가는 곳'),
              if (mineTrips.isEmpty) none('등록한 일정이 없어요.'),
              for (final t in mineTrips)
                TripRow(t: t, pending: session?.receivedFor(t.id).length ?? 0, onTap: () => openTrip(context, nav, t)),
              sec('내가 한 부탁'),
              if (asks.isEmpty) none('아직 한 부탁이 없어요.'),
              for (final d in asks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        final t = _find(nav, d.requestId);
                        if (t != null) openTrip(context, nav, t);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.ask, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                                  Text(d.title, style: const TextStyle(fontSize: 12, color: AppColors.sub)),
                                ],
                              ),
                            ),
                            TripTag(d.stage, d.stageIndex),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('전달 완료한 부탁 비용', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green)),
                    ),
                    Text(won(earned), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.green)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('완료 확인된 거래만 셉니다. 앱 안의 정산은 아직 없어서 직접 받은 금액이에요.', style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
              ),
            ],
          ),
        );
      },
    );
  }
}
