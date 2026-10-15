import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_icon.dart';
import '../data/reward_brands.dart';
import '../models/reward_product.dart';

/// 교환 전 확인 시트. 교환 후 남는 포인트를 미리 보여 준다.
class RedeemSheet extends StatelessWidget {
  final RewardProduct p;
  final int points;
  final VoidCallback onClose, onConfirm;
  const RedeemSheet({super.key, required this.p, required this.points, required this.onClose, required this.onConfirm});
  @override
  Widget build(BuildContext context) {
    final b = brandOf(p.brand);
    final after = points - p.points;
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: const Color(0x73141420),
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 26),
              decoration: const BoxDecoration(
                color: AppColors.page,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: AppIcon(b.icon, size: 23, color: AppColors.ink2),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.name,
                            style: const TextStyle(fontSize: 12, color: AppColors.sub, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            p.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('이 상품으로 교환할까요?', style: TextStyle(fontSize: 14, color: AppColors.ink)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _row('사용 포인트', '-${nf(p.points)}P', color: AppColors.red),
                        _row('보유 포인트', '${nf(points)}P'),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.only(top: 9),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: AppColors.line)),
                          ),
                          child: _row('교환 후', '${nf(after)}P', bold: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onClose,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            side: const BorderSide(color: AppColors.line),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                          ),
                          child: const Text('취소', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            elevation: 0,
                          ),
                          child: Text('${nf(p.points)}P 사용하기', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String l, String v, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(fontSize: 13, color: AppColors.sub)),
          Text(
            v,
            style: TextStyle(fontSize: 13.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w700, color: color ?? AppColors.ink),
          ),
        ],
      ),
    );
  }
}

/// 교환 완료 안내
class RedeemDone extends StatelessWidget {
  final RewardProduct p;
  final VoidCallback onClose, onCoupons;
  const RedeemDone({super.key, required this.p, required this.onClose, required this.onCoupons});
  @override
  Widget build(BuildContext context) {
    final b = brandOf(p.brand);
    return Positioned.fill(
      child: Material(
        color: AppColors.page,
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.greenSoft, shape: BoxShape.circle),
                child: const AppIcon('sparkles', size: 32, color: AppColors.ink2),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 18, bottom: 8),
                child: Text(
                  '교환 완료!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
              const Text('모바일 쿠폰이 발급되었어요', style: TextStyle(fontSize: 13, color: AppColors.sub)),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    AppIcon(b.icon, size: 29, color: AppColors.ink2),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        b.name,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.sub, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        p.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onCoupons,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    elevation: 0,
                  ),
                  child: const Text('쿠폰 확인하기', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
              TextButton(
                onPressed: onClose,
                child: const Text(
                  '계속 둘러보기',
                  style: TextStyle(color: AppColors.sub, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
