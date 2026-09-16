import 'package:flutter/material.dart';

import '../../../core/storage/local_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../benefits/data/point_rules.dart';

/// 홈 최상단의 "지금까지 모은 금액 + 목표" 영역.
///
/// 기획 시안 v9의 `CompactEarnings`를 옮긴 것. 사례비(원)와 포인트를 1P = [pointValue]원
/// 기준으로 합산해 보여주고, 목표 금액은 사용자가 직접 입력해 이 기기에 보관한다.
///
/// 표시되는 금액은 체험에서 완료 처리한 거래의 합계이지 실제 정산액이 아니다.
class IncomeSummary extends StatefulWidget {
  /// 완료한 거래의 사례비 합계(원)
  final int cash;

  /// 보유 포인트
  final int points;
  const IncomeSummary({super.key, required this.cash, required this.points});

  @override
  State<IncomeSummary> createState() => _IncomeSummaryState();
}

class _IncomeSummaryState extends State<IncomeSummary> {
  static const _key = 'incomeGoal';
  static const _min = 1000;
  static const _max = 100000000;

  late int goal = LocalStore.read<int>(_key, 0);
  bool editing = false;
  String? error;
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void _openEditor() {
    ctrl.text = goal > 0 ? '$goal' : '';
    setState(() {
      error = null;
      editing = !editing;
    });
  }

  void _save() {
    final v = int.tryParse(ctrl.text.replaceAll(RegExp(r'[,\s]'), ''));
    if (v == null || v < _min || v > _max) {
      setState(() => error = '${nf(_min)}원부터 ${nf(_max)}원까지 숫자로 입력해 주세요');
      return;
    }
    LocalStore.write(_key, v);
    setState(() {
      goal = v;
      editing = false;
      error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.cash + widget.points * pointValue;
    final percent = goal > 0 ? (total * 100 / goal).floor().clamp(0, 100) : 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(22, 6, 22, 8),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('지금까지 모은 금액', style: AppType.meta.copyWith(color: AppColors.onDarkSub)),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: nf(total), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.gold)),
              const TextSpan(text: '원', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.gold)),
            ])),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '돈 ${nf(widget.cash)}원 + 포인트 ${nf(widget.points)}P · 1P = $pointValue원 기준',
              style: const TextStyle(fontSize: 11.5, color: AppColors.onDarkSub),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text('체험에서 완료한 내역 기준이에요. 실제 정산액이 아니에요.', style: TextStyle(fontSize: 10.5, color: AppColors.onDarkFaint)),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(children: [
              Expanded(
                child: Text(goal > 0 ? '목표 ${won(goal)}' : '나의 목표 금액',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              if (goal > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('$percent%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.gold)),
                ),
              InkWell(
                onTap: _openEditor,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.onDarkFill, borderRadius: BorderRadius.circular(8)),
                  child: Text(goal > 0 ? '수정' : '설정', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: goal > 0 ? percent / 100 : 0,
                minHeight: 7,
                backgroundColor: AppColors.onDarkFill,
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
          ),
          if (goal > 0)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                total >= goal ? '목표 달성! 다음 목표를 정해볼까요?' : '${won(goal - total)}만큼 더 모으면 달성해요',
                style: const TextStyle(fontSize: 11.5, color: Colors.white70),
              ),
            ),

          if (editing) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 15, color: AppColors.ink, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: '예: 300000',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide.none),
                ),
              ),
            ),
            if (error != null)
              Padding(padding: const EdgeInsets.only(top: 6), child: Text(error!, style: const TextStyle(fontSize: 11.5, color: AppColors.red))),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => editing = false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Color(0xFF3A3D42)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    ),
                    child: const Text('취소', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.ink,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    ),
                    child: const Text('목표 저장', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}
