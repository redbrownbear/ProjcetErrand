import 'package:flutter/material.dart';

import '../data/reward_brands.dart';
import '../data/reward_products.dart';
import '../models/reward_product.dart';
import '../models/screen_route.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
import '../widgets/chip_widget.dart';
import '../widgets/screen_frame.dart';

class PointShopScreen extends StatefulWidget {
  final int points;
  final void Function(RewardProduct) redeem;
  final VoidCallback onClose;
  final void Function(ScreenRoute) push;
  final VoidCallback goPointsHub;
  const PointShopScreen({super.key, required this.points, required this.redeem, required this.onClose, required this.push, required this.goPointsHub});
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
    var list = rewardProducts;
    if (cat != 'all') list = list.where((p) => brandOf(p.brand).cat == cat).toList();
    if (brand != null) list = list.where((p) => p.brand == brand).toList();
    final popular = rewardProducts.where((p) => p.hot).toList();
    final brandsInCat = rewardBrands.where((b) => cat == 'all' || b.cat == cat).toList();

    return Stack(children: [
      ScreenFrame(
        title: '포인트샵',
        subtitle: '모은 포인트를 생활 혜택으로',
        onBack: widget.onClose,
        right: InkWell(
          onTap: () => widget.push(const ScreenRoute(name: 'coupons')),
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(9)),
            child: const Text('🎟 내 쿠폰', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('보유 포인트', style: TextStyle(fontSize: 12, color: Colors.white60)),
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text('${nf(widget.points)}P', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.yellow))),
                  ],
                ),
                const Text('1P ≈ 1원처럼\n사용할 수 있어요', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: Colors.white54, height: 1.5)),
              ]),
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
                        child: ChipWidget(label: c[1], active: cat == c[0], onTap: () => setState(() {
                          cat = c[0];
                          brand = null;
                        })),
                      ),
                  ],
                ),
              ),
            ),
            if (brand == null) ...[
              const Padding(padding: EdgeInsets.fromLTRB(0, 6, 0, 8), child: Text('🔥 인기 교환 상품', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink))),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: popular.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _RewardMini(p: popular[i], points: widget.points, onOpen: () => setState(() => confirm = popular[i])),
                ),
              ),
              const Padding(padding: EdgeInsets.fromLTRB(0, 16, 0, 8), child: Text('브랜드별 보기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink))),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8, crossAxisSpacing: 8,
                childAspectRatio: 0.95,
                children: brandsInCat.map((b) {
                  return InkWell(
                    onTap: () => setState(() => brand = b.k),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(b.icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(b.name, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (brand != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Text('${brandOf(brand!).icon} ${brandOf(brand!).name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const Spacer(),
                  InkWell(onTap: () => setState(() => brand = null), child: const Text('전체 브랜드 ›', style: TextStyle(fontSize: 12, color: AppColors.sub))),
                ]),
              ),
            const SizedBox(height: 4),
            for (final p in list)
              _RewardCard(
                p: p, points: widget.points, wished: wished.contains(p.id),
                onWish: () => _toggleWish(p.id),
                onRedeem: () => setState(() => confirm = p),
                onGather: widget.goPointsHub,
              ),
          ],
        ),
      ),
      if (confirm != null)
        _RedeemSheet(p: confirm!, points: widget.points, onClose: () => setState(() => confirm = null), onConfirm: () => _doRedeem(confirm!)),
      if (done != null)
        _RedeemDone(p: done!, onClose: () => setState(() => done = null), onCoupons: () {
          setState(() => done = null);
          widget.push(const ScreenRoute(name: 'coupons'));
        }),
    ]);
  }
}

class _RewardMini extends StatelessWidget {
  final RewardProduct p;
  final int points;
  final VoidCallback onOpen;
  const _RewardMini({required this.p, required this.points, required this.onOpen});
  @override
  Widget build(BuildContext context) {
    final b = brandOf(p.brand);
    final afford = points >= p.points;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: double.infinity, height: 60, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(10)), child: Text(b.icon, style: const TextStyle(fontSize: 30))),
            Padding(padding: const EdgeInsets.only(top: 8), child: Text(b.name, style: const TextStyle(fontSize: 11, color: AppColors.sub, fontWeight: FontWeight.w700))),
            Padding(padding: const EdgeInsets.only(top: 2, bottom: 6), child: SizedBox(height: 34, child: Text(p.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.35), maxLines: 2, overflow: TextOverflow.ellipsis))),
            Text('${nf(p.points)}P', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: afford ? AppColors.ink : AppColors.faint)),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final RewardProduct p;
  final int points;
  final bool wished;
  final VoidCallback onWish, onRedeem, onGather;
  const _RewardCard({required this.p, required this.points, required this.wished, required this.onWish, required this.onRedeem, required this.onGather});
  @override
  Widget build(BuildContext context) {
    final b = brandOf(p.brand);
    final afford = points >= p.points;
    final remain = p.points - points;
    final pct = (points / p.points).clamp(0, 1).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 56, height: 56, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)), child: Text(b.icon, style: const TextStyle(fontSize: 28))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(b.name, style: const TextStyle(fontSize: 11, color: AppColors.sub, fontWeight: FontWeight.w700)),
                    if (p.hot) ...[
                      const SizedBox(width: 6),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(6)), child: const Text('인기', style: TextStyle(fontSize: 10, color: AppColors.red, fontWeight: FontWeight.w700))),
                    ],
                    const Spacer(),
                    InkWell(onTap: onWish, child: Text(wished ? '♥' : '♡', style: TextStyle(fontSize: 16, color: wished ? AppColors.red : AppColors.faint))),
                  ]),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink))),
                  Text('${nf(p.points)}P', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ],
              ),
            ),
          ]),
          if (afford)
            Padding(
              padding: const EdgeInsets.only(top: 11),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRedeem,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)), elevation: 0),
                  child: const Text('교환하기', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: AppColors.page, color: AppColors.yellow))),
                    const SizedBox(width: 8),
                    Text('${(pct * 100).round()}%', style: const TextStyle(fontSize: 11, color: AppColors.sub, fontWeight: FontWeight.w700)),
                  ]),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: AppColors.sub), children: [
                      TextSpan(text: '${nf(remain)}P', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                      const TextSpan(text: '만 더 모으면 교환할 수 있어요'),
                    ])),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onGather,
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.line), padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                      child: const Text('포인트 모으러 가기 ›', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RedeemSheet extends StatelessWidget {
  final RewardProduct p;
  final int points;
  final VoidCallback onClose, onConfirm;
  const _RedeemSheet({required this.p, required this.points, required this.onClose, required this.onConfirm});
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
              decoration: const BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 18), decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)))),
                  Row(children: [
                    Container(width: 52, height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(13)), child: Text(b.icon, style: const TextStyle(fontSize: 27))),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.name, style: const TextStyle(fontSize: 12, color: AppColors.sub, fontWeight: FontWeight.w700)),
                      Text(p.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    ]),
                  ]),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('이 상품으로 교환할까요?', style: TextStyle(fontSize: 14, color: AppColors.ink))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      _row('사용 포인트', '-${nf(p.points)}P', color: AppColors.red),
                      _row('보유 포인트', '${nf(points)}P'),
                      Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.only(top: 9), decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))), child: _row('교환 후', '${nf(after)}P', bold: true)),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onClose,
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.line), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                        child: const Text('취소', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: onConfirm,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)), elevation: 0),
                        child: Text('${nf(p.points)}P 사용하기', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                    ),
                  ]),
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
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: const TextStyle(fontSize: 13, color: AppColors.sub)),
        Text(v, style: TextStyle(fontSize: 13.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w700, color: color ?? AppColors.ink)),
      ]),
    );
  }
}

class _RedeemDone extends StatelessWidget {
  final RewardProduct p;
  final VoidCallback onClose, onCoupons;
  const _RedeemDone({required this.p, required this.onClose, required this.onCoupons});
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
              Container(width: 76, height: 76, alignment: Alignment.center, decoration: const BoxDecoration(color: AppColors.greenSoft, shape: BoxShape.circle), child: const Text('🎉', style: TextStyle(fontSize: 38))),
              const Padding(padding: EdgeInsets.only(top: 18, bottom: 8), child: Text('교환 완료!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink))),
              const Text('모바일 쿠폰이 발급되었어요', style: TextStyle(fontSize: 13, color: AppColors.sub)),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Text(b.icon, style: const TextStyle(fontSize: 34)),
                  Padding(padding: const EdgeInsets.only(top: 8), child: Text(b.name, style: const TextStyle(fontSize: 12.5, color: AppColors.sub, fontWeight: FontWeight.w700))),
                  Padding(padding: const EdgeInsets.only(top: 3), child: Text(p.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink))),
                ]),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onCoupons,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)), elevation: 0),
                  child: const Text('쿠폰 확인하기', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
              TextButton(onPressed: onClose, child: const Text('계속 둘러보기', style: TextStyle(color: AppColors.sub, fontWeight: FontWeight.w700, fontSize: 14))),
            ],
          ),
        ),
      ),
    );
  }
}
