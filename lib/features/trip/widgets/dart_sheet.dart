import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';

/// 여행 어디 갈까? — 움직이는 과녁에 다트를 던져 여행지를 정한다 (시안 v43 `openRoulette`).
class DartSheet extends StatefulWidget {
  final bool abroad;

  /// 당첨된 곳의 이웃 이야기 보기
  final void Function(String place, bool abroad) onStories;
  const DartSheet({super.key, this.abroad = false, required this.onStories});

  @override
  State<DartSheet> createState() => _DartSheetState();
}

const _domestic = ['제주', '부산', '강릉', '전주', '여수', '경주', '속초', '대전', '담양', '보성', '태안', '영덕', '단양', '양양', '남해', '하동', '곡성', '순창', '안동', '통영', '평창', '영월', '서산', '고창'];
const _abroad = ['도쿄', '오사카', '후쿠오카', '타이베이', '다낭', '방콕', '싱가포르', '홍콩', '파리', '런던', 'LA', '뉴욕'];

/// 당첨 카드에 붙는 한 줄 추천. 없는 곳은 일반 문구로 둔다.
const _tips = <String, (String, String, String)>{
  '제주': ('성산일출봉', '고기국수', '애월 바다 앞 숙소'),
  '부산': ('해운대 블루라인', '돼지국밥', '광안리 오션뷰'),
  '강릉': ('안목해변 카페거리', '초당순두부', '경포 한옥스테이'),
  '전주': ('한옥마을', '비빔밥', '한옥 게스트하우스'),
  '여수': ('밤바다 해상케이블카', '게장백반', '돌산 오션뷰'),
  '경주': ('황리단길', '황남빵', '보문호수 리조트'),
  '속초': ('영금정', '오징어순대', '대포항 근처 숙소'),
  '도쿄': ('시부야 스카이', '이자카야', '신주쿠 비즈니스호텔'),
  '오사카': ('도톤보리', '타코야키', '난바 숙소'),
  '타이베이': ('지우펀', '야시장 간식', '시먼딩 숙소'),
  '다낭': ('미케 비치', '쌀국수', '한시장 근처 숙소'),
};

class _DartSheetState extends State<DartSheet> with TickerProviderStateMixin {
  late bool abroad = widget.abroad;
  late final AnimationController spin = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController throwC = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  final _rand = Random();
  String? result;

  List<String> get places => abroad ? _abroad : _domestic;

  @override
  void dispose() {
    spin.dispose();
    throwC.dispose();
    super.dispose();
  }

  Future<void> _throw() async {
    setState(() => result = null);
    await throwC.forward(from: 0);
    if (!mounted) return;
    setState(() => result = places[_rand.nextInt(places.length)]);
  }

  @override
  Widget build(BuildContext context) {
    final tip = result == null ? null : _tips[result];
    return SheetFrame(
      title: '여행 어디 갈까?',
      sub: '움직이는 과녁을 보고 던지기를 눌러요. 다트가 꽂힌 곳에서 가장 가까운 여행지가 당첨돼요',
      bottom: result == null
          ? BigButton(label: '던지기!', icon: 'target', onTap: throwC.isAnimating ? null : _throw)
          : Row(children: [
              Expanded(child: BigButton(label: '다시 던지기', bg: AppColors.page, fg: AppColors.inkSoft, onTap: _throw)),
              const SizedBox(width: 8),
              Expanded(
                child: BigButton(
                  label: '$result 이야기',
                  bg: AppColors.ink,
                  fg: Colors.white,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onStories(result!, abroad);
                  },
                ),
              ),
            ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Seg(
          labels: const ['국내', '해외'],
          index: abroad ? 1 : 0,
          margin: EdgeInsets.zero,
          onChanged: (i) => setState(() {
            abroad = i == 1;
            result = null;
          }),
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 240,
            height: 240,
            child: AnimatedBuilder(
              animation: Listenable.merge([spin, throwC]),
              builder: (_, _) => CustomPaint(painter: _Board(places, spin.value, throwC.value, result != null)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (result != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('🎯 $result 당첨!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              _tipRow('명소', tip?.$1 ?? '$result 대표 명소를 이웃 이야기에서 찾아봐요'),
              _tipRow('맛집', tip?.$2 ?? '현지인 추천 맛집'),
              _tipRow('숙소', tip?.$3 ?? '제휴 숙소 혜택 확인'),
            ]),
          )
        else
          Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
            for (final p in places)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)),
                child: Text(p, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              ),
          ]),
      ]),
    );
  }

  Widget _tipRow(String k, String v) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(children: [
          SizedBox(width: 40, child: Text(k, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.yellowInk))),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 13.5, color: AppColors.ink))),
        ]),
      );
}

class _Board extends CustomPainter {
  final List<String> places;
  final double turn;
  final double thrown;
  final bool landed;
  _Board(this.places, this.turn, this.thrown, this.landed);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    const rings = [Color(0xFFFFCD1F), Colors.white, Color(0xFFF04452), Colors.white, Color(0xFFFFCD1F)];
    for (var i = 0; i < rings.length; i++) {
      canvas.drawCircle(c, r * (1 - i * 0.18), Paint()..color = rings[i]);
    }
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.ink);

    // 움직이는 이름들
    final n = places.length;
    for (var i = 0; i < n; i++) {
      final a = 2 * pi * (i / n + turn);
      final pos = c + Offset(cos(a), sin(a)) * r * 0.78;
      final tp = TextPainter(
        text: TextSpan(text: places[i], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ink)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // 날아오는 다트
    if (thrown > 0 || landed) {
      final t = landed ? 1.0 : Curves.easeIn.transform(thrown);
      final tip = Offset(c.dx + 6, c.dy - 4);
      final start = Offset(size.width + 30, -30);
      final p = Offset.lerp(start, tip, t)!;
      final dart = Paint()
        ..color = AppColors.ink
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p, p + const Offset(26, -26), dart);
      canvas.drawCircle(p, 3, Paint()..color = AppColors.ink);
      canvas.drawLine(p + const Offset(22, -22), p + const Offset(34, -24), Paint()
        ..color = AppColors.blue
        ..strokeWidth = 4);
      canvas.drawLine(p + const Offset(22, -22), p + const Offset(24, -34), Paint()
        ..color = AppColors.blue
        ..strokeWidth = 4);
    }
  }

  @override
  bool shouldRepaint(_Board old) => true;
}
