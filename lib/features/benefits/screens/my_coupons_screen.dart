import 'package:flutter/material.dart';

import '../../../core/navigation/screen_route.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/screen_frame.dart';
import '../data/reward_brands.dart';
import '../models/coupon.dart';

class MyCouponsScreen extends StatefulWidget {
  final List<Coupon> coupons;
  final void Function(int id) useCoupon;
  final VoidCallback onClose;
  final void Function(ScreenRoute) push;
  final VoidCallback goPointsHub;
  const MyCouponsScreen({super.key, required this.coupons, required this.useCoupon, required this.onClose, required this.push, required this.goPointsHub});
  @override
  State<MyCouponsScreen> createState() => _MyCouponsScreenState();
}

class _MyCouponsScreenState extends State<MyCouponsScreen> {
  String tab = 'live';
  Coupon? sel;

  @override
  Widget build(BuildContext context) {
    final live = widget.coupons.where((c) => !c.used).toList();
    final used = widget.coupons.where((c) => c.used).toList();
    final list = tab == 'live' ? live : used;

    return Stack(children: [
      ScreenFrame(
        title: '내 쿠폰',
        onBack: widget.onClose,
        child: Column(children: [
          Container(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
            child: Row(children: [
              _tabBtn('live', '사용 가능 ${live.length}'),
              _tabBtn('used', '사용 완료 ${used.length}'),
            ]),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                          tab == 'live' ? '아직 쿠폰이 없어요.\n포인트샵에서 교환해보세요.' : '사용 완료한 쿠폰이 없어요.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.sub, fontSize: 13, height: 1.7),
                        ),
                        if (tab == 'live')
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: ElevatedButton(
                              onPressed: widget.goPointsHub,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)), elevation: 0),
                              child: const Text('포인트 모으러 가기', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            ),
                          ),
                      ]),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    children: [for (final c in list) _CouponCard(c: c, onOpen: () => setState(() => sel = c))],
                  ),
          ),
        ]),
      ),
      if (sel != null)
        _CouponDetail(c: sel!, onClose: () => setState(() => sel = null), onUse: () {
          widget.useCoupon(sel!.id);
          setState(() => sel = null);
        }),
    ]);
  }

  Widget _tabBtn(String k, String label) {
    final on = tab == k;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => tab = k),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: on ? AppColors.ink : Colors.transparent, width: 2))),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: on ? AppColors.ink : AppColors.faint)),
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon c;
  final VoidCallback onOpen;
  const _CouponCard({required this.c, required this.onOpen});
  @override
  Widget build(BuildContext context) {
    final b = brandOf(c.brandK);
    return Opacity(
      opacity: c.used ? .55 : 1,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Container(width: 52, height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)), child: Text(b.icon, style: const TextStyle(fontSize: 26))),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.name, style: const TextStyle(fontSize: 11.5, color: AppColors.sub, fontWeight: FontWeight.w700)),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(c.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink))),
                  Text('유효기간 ${c.exp}${c.used ? ' · 사용 완료' : ''}', style: const TextStyle(fontSize: 11.5, color: AppColors.faint)),
                ],
              ),
            ),
            if (!c.used) const Text('쿠폰 보기 ›', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
          ]),
        ),
      ),
    );
  }
}

class _CouponDetail extends StatelessWidget {
  final Coupon c;
  final VoidCallback onClose, onUse;
  const _CouponDetail({required this.c, required this.onClose, required this.onUse});
  @override
  Widget build(BuildContext context) {
    final b = brandOf(c.brandK);
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: const Color(0x8C141420),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(b.icon, style: const TextStyle(fontSize: 34)),
                  Padding(padding: const EdgeInsets.only(top: 6), child: Text(b.name, style: const TextStyle(fontSize: 12.5, color: AppColors.sub, fontWeight: FontWeight.w700))),
                  Padding(padding: const EdgeInsets.only(top: 3, bottom: 16), child: Text(c.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink))),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      SizedBox(
                        height: 56,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [for (int i = 0; i < 48; i++) Container(width: i % 3 == 0 ? 3 : (i % 2 == 0 ? 1 : 2), margin: const EdgeInsets.symmetric(horizontal: .75), color: AppColors.ink)],
                        ),
                      ),
                      Padding(padding: const EdgeInsets.only(top: 8), child: Text(c.code, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: 2))),
                    ]),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(10)),
                    child: Column(children: [
                      _row('쿠폰번호', c.code),
                      _row('유효기간', c.exp),
                      _row('상태', c.used ? '사용 완료' : '사용 가능'),
                    ]),
                  ),
                  if (!c.used)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onUse,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                        child: const Text('사용 완료 처리', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                      ),
                    )
                  else
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('이미 사용한 쿠폰이에요', style: TextStyle(color: AppColors.faint, fontWeight: FontWeight.w700, fontSize: 14))),
                  TextButton(onPressed: onClose, child: const Text('닫기', style: TextStyle(color: AppColors.sub, fontSize: 13, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String l, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: const TextStyle(fontSize: 12, color: AppColors.sub)),
        Text(v, style: const TextStyle(fontSize: 12.5, color: AppColors.ink, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
