import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../models/tickets.dart';

/// 이달의 럭키드로우 (시안 v77 `ldOpen`).
///
/// 1~4등 상품 · 내 응모 현황 · 응모권 모으는 방법 · 응모하기 순서다.
/// 추첨과 발표는 서버가 붙어야 하므로, 여기서는 응모권을 '응모함'으로 옮기는 데까지만 한다.
class LuckyDrawScreen extends StatefulWidget {
  final TicketWallet Function() wallet;

  /// [n]장을 응모한다. 성공하면 true.
  final bool Function(int n) onEnter;
  const LuckyDrawScreen({super.key, required this.wallet, required this.onEnter});

  @override
  State<LuckyDrawScreen> createState() => _LuckyDrawScreenState();
}

class _LuckyDrawScreenState extends State<LuckyDrawScreen> {
  final draw = LuckyDraw(DateTime.now());
  late int count = widget.wallet().have;
  int ruleTab = 0;

  @override
  Widget build(BuildContext context) {
    final w = widget.wallet();
    if (count > w.have) count = w.have;
    final now = DateTime.now();

    return PageFrame(
      title: '${draw.month}월 럭키드로우',
      background: AppColors.card,
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Text('응모 횟수', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.blue)),
          const Spacer(),
          _Stepper(
            value: count,
            max: w.have,
            onChanged: (v) => setState(() => count = v),
          ),
        ]),
        const SizedBox(height: 8),
        Stack(alignment: Alignment.centerRight, children: [
          BigButton(
            label: '응모하기',
            height: 54,
            onTap: count > 0
                ? () {
                    if (widget.onEnter(count)) setState(() => count = widget.wallet().have);
                  }
                : null,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text('${w.have}개 보유', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
          ),
        ]),
      ]),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        children: [
          _firstPrize(),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _smallPrize(LuckyDraw.prizes[1], const Color(0xFFF2F4F6), Icons.flight_rounded, AppColors.green)),
            const SizedBox(width: 8),
            Expanded(child: _smallPrize(LuckyDraw.prizes[2], const Color(0xFFFBEEDF), Icons.card_giftcard_rounded, const Color(0xFFB07A3B))),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outline)),
            child: Row(children: [
              const _Rank('4', 'th', color: AppColors.ink),
              const SizedBox(width: 12),
              Expanded(child: Text(LuckyDraw.prizes[3].title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
              _peopleChip(LuckyDraw.prizes[3].people, light: true),
            ]),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _stat('이번 달 내 응모', '${w.entered}장')),
            const SizedBox(width: 8),
            Expanded(child: _stat('보유 응모권', '${w.have}장')),
          ]),
          const SizedBox(height: 22),
          const Text('응모권 모으는 방법', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.outline)),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                for (final (i, l) in const ['참여 가능', '참여 완료'].indexed)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => ruleTab = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: ruleTab == i ? AppColors.ink : AppColors.line, width: ruleTab == i ? 2 : 1)),
                        ),
                        alignment: Alignment.center,
                        child: Text(l, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ruleTab == i ? AppColors.ink : AppColors.faint)),
                      ),
                    ),
                  ),
              ]),
              ..._rules(w, now),
            ]),
          ),
          const SizedBox(height: 14),
          const Text(
            '응모권은 겸사겸사 활동으로만 받을 수 있어요. 구매·현금 환전·양도할 수 없고, 응모한 응모권은 되돌릴 수 없어요. '
            '그달 응모한 응모권 중에서 겸사겸사가 추첨해요.',
            style: TextStyle(fontSize: 12, color: AppColors.sub, height: 1.6),
          ),
        ],
      ),
    );
  }

  List<Widget> _rules(TicketWallet w, DateTime now) {
    final done = ruleTab == 1;
    final groups = <String, String>{
      '매일': '매일마다 응모권 드려요',
      '부탁': '부탁하고 응모권 모아요',
      '미션': '미션하고 응모권 모아요',
      '커뮤니티': '이야기 나누고 응모권 모아요',
      '최초': '최초 1회만 가능해요',
    };
    final out = <Widget>[];
    for (final g in groups.entries) {
      // 반복해서 받는 규칙은 언제나 '참여 가능'에, 한 번만 받는 규칙은 받은 뒤 '참여 완료'로 옮긴다.
      final rules = TicketRules.all.where((r) => r.group == g.key && (done ? !w.canClaim(r, now) : w.canClaim(r, now))).toList();
      if (rules.isEmpty) continue;
      out.add(Padding(
        padding: const EdgeInsets.fromLTRB(2, 16, 0, 6),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: g.value.split(' ').first, style: const TextStyle(fontWeight: FontWeight.w800)),
          TextSpan(text: g.value.substring(g.value.indexOf(' '))),
        ]), style: const TextStyle(fontSize: 14, color: AppColors.ink)),
      ));
      for (final r in rules) {
        out.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: done ? AppColors.greenSoft : AppColors.page, shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, size: 18, color: done ? AppColors.green : AppColors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(text: r.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: ' 하면 ${r.n}개', style: const TextStyle(color: AppColors.sub)),
              ]), style: const TextStyle(fontSize: 14, color: AppColors.ink)),
            ),
          ]),
        ));
      }
    }
    if (out.isEmpty) {
      out.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('아직 완료한 항목이 없어요', style: TextStyle(fontSize: 13, color: AppColors.sub))),
      ));
    }
    return out;
  }

  Widget _firstPrize() {
    final p = LuckyDraw.prizes[0];
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3A3F47), Color(0xFF191F28)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Rank('1', 'st', color: Color(0xFFE9C46A)),
          const SizedBox(height: 10),
          Text(draw.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFE9C46A), letterSpacing: 0.4)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 96),
            child: Text(p.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3, letterSpacing: -0.8)),
          ),
          const SizedBox(height: 8),
          const Text('응모권 1장이 추첨 기회 1번', style: TextStyle(fontSize: 12, color: Color(0xB3FFFFFF))),
        ]),
        Positioned(right: 0, top: 0, child: _peopleChip(p.people)),
        Positioned(
          right: 4,
          bottom: 0,
          child: _PrizeBadge(icon: Icons.flight_rounded, bg: const Color(0xFFFFE07A), fg: AppColors.blue, label: p.short, size: 84),
        ),
      ]),
    );
  }

  Widget _smallPrize(({String rank, String title, String short, int people}) p, Color bg, IconData icon, Color fg) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      child: Column(children: [
        Row(children: [
          _Rank(p.rank.substring(0, 1), p.rank.substring(1), color: fg == AppColors.green ? AppColors.sub : const Color(0xFFB07A3B)),
          const Spacer(),
          _peopleChip(p.people, light: true),
        ]),
        const Spacer(),
        _PrizeBadge(icon: icon, bg: Colors.white, fg: fg, size: 54),
        const Spacer(),
        Text(p.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _peopleChip(int n, {bool light = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: light ? const Color(0x14191F28) : const Color(0x26FFFFFF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(n == 1 ? '당첨 1명' : '$n명', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: light ? AppColors.sub : Colors.white)),
      );

  Widget _stat(String k, String v) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k, style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
          const SizedBox(height: 6),
          Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
      );
}

class _Rank extends StatelessWidget {
  final String n;
  final String suffix;
  final Color color;
  const _Rank(this.n, this.suffix, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: n, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, height: 1)),
        TextSpan(text: suffix, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
      ]),
      style: TextStyle(color: color),
    );
  }
}

class _PrizeBadge extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final String? label;
  final double size;
  const _PrizeBadge({required this.icon, required this.bg, required this.fg, this.label, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size + (label == null ? 0 : 8),
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Transform.rotate(angle: -0.5, child: Icon(icon, size: size * 0.62, color: fg)),
        ),
        if (label != null)
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(6)),
              child: Text(label!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
      ]),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  const _Stepper({required this.value, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData i, bool on, VoidCallback f) => GestureDetector(
          onTap: on ? f : null,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(9)),
            child: Icon(i, size: 18, color: on ? AppColors.ink : AppColors.faint),
          ),
        );
    return Row(children: [
      btn(Icons.remove_rounded, value > 0, () => onChanged(value - 1)),
      SizedBox(
        width: 48,
        child: Text('$value개', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.blue)),
      ),
      btn(Icons.add_rounded, value < max, () => onChanged(value + 1)),
    ]);
  }
}
