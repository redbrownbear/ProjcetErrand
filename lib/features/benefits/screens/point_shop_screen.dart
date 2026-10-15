import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../../core/widgets/screen_frame.dart';
import '../data/reward_brands.dart';
import '../models/coupon.dart';
import '../models/reward_product.dart';
import '../repositories/benefits_repository.dart';
import '../widgets/redeem_sheet.dart';
import '../widgets/reward_cards.dart';
import 'my_coupons_screen.dart';

class PointShopScreen extends StatefulWidget {
  final int points;
  final void Function(RewardProduct) redeem;
  final List<Coupon> coupons;
  final void Function(int id) useCoupon;
  final VoidCallback goPointsHub;
  const PointShopScreen({
    super.key,
    required this.points,
    required this.redeem,
    required this.coupons,
    required this.useCoupon,
    required this.goPointsHub,
  });
  @override
  State<PointShopScreen> createState() => _PointShopScreenState();
}

class _PointShopScreenState extends State<PointShopScreen> {
  String cat = 'all';
  String? brand;
  RewardProduct? confirm;
  RewardProduct? done;
  final wished = <String>{};

  void _toggleWish(String id) => setState(() => wished.contains(id) ? wished.remove(id) : wished.add(id));

  void _doRedeem(RewardProduct p) {
    widget.redeem(p);
    setState(() {
      confirm = null;
      done = p;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rewardProducts = LocalBenefitsRepository().fetchRewardProducts();
    var list = rewardProducts;
    if (cat != 'all') list = list.where((p) => brandOf(p.brand).cat == cat).toList();
    if (brand != null) list = list.where((p) => p.brand == brand).toList();
    final popular = rewardProducts.where((p) => p.hot).toList();
    final brandsInCat = rewardBrands.where((b) => cat == 'all' || b.cat == cat).toList();

    return Stack(
      children: [
        Positioned.fill(
          child: ScreenFrame(
            title: '포인트샵',
            subtitle: '모은 포인트를 생활 혜택으로',
            onBack: () => Navigator.of(context).pop(),
            right: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MyCouponsScreen(coupons: widget.coupons, useCoupon: widget.useCoupon, goPointsHub: widget.goPointsHub),
                ),
              ),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(9)),
                child: const Text(
                  '내 쿠폰',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('보유 포인트', style: TextStyle(fontSize: 12, color: Colors.white60)),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${nf(widget.points)}P',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.yellow),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        '1P ≈ 1원처럼\n사용할 수 있어요',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, color: Colors.white54, height: 1.5),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final c in rshopCats)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChipWidget(
                              label: c[1],
                              active: cat == c[0],
                              onTap: () => setState(() {
                                cat = c[0];
                                brand = null;
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (brand == null) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(0, 6, 0, 8),
                    child: Text(
                      '인기 교환 상품',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                  ),
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: popular.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) =>
                          RewardMini(p: popular[i], points: widget.points, onOpen: () => setState(() => confirm = popular[i])),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(0, 16, 0, 8),
                    child: Text(
                      '브랜드별 보기',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                  ),
                  GridView(
                    // 비율이 아니라 픽셀로 높이를 고정한다. 비율을 쓰면 넓은 화면에서 셀이 같이 커진다.
                    // 내용물 = 아이콘 24 + 간격 4 + 라벨 14 + 상하 여백
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 86,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      mainAxisExtent: 62,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: brandsInCat.map((b) {
                      return InkWell(
                        onTap: () => setState(() => brand = b.k),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppIcon(b.icon, size: 20, color: AppColors.ink2),
                              const SizedBox(height: 4),
                              Text(
                                b.name,
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (brand != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Text(
                          brandOf(brand!).name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => setState(() => brand = null),
                          child: const Text('전체 브랜드 ›', style: TextStyle(fontSize: 12, color: AppColors.sub)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                for (final p in list)
                  RewardCard(
                    p: p,
                    points: widget.points,
                    wished: wished.contains(p.id),
                    onWish: () => _toggleWish(p.id),
                    onRedeem: () => setState(() => confirm = p),
                    onGather: widget.goPointsHub,
                  ),
              ],
            ),
          ),
        ),
        if (confirm != null)
          RedeemSheet(
            p: confirm!,
            points: widget.points,
            onClose: () => setState(() => confirm = null),
            onConfirm: () => _doRedeem(confirm!),
          ),
        if (done != null)
          RedeemDone(
            p: done!,
            onClose: () => setState(() => done = null),
            onCoupons: () {
              setState(() => done = null);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MyCouponsScreen(coupons: widget.coupons, useCoupon: widget.useCoupon, goPointsHub: widget.goPointsHub),
                ),
              );
            },
          ),
      ],
    );
  }
}
