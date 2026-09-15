import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/services/auth_service.dart';
import '../../benefits/models/coupon.dart';
import '../../benefits/screens/my_coupons_screen.dart';

class MeView extends StatelessWidget {
  final int points;
  final List<Coupon> coupons;
  final void Function(int id) useCoupon;
  final VoidCallback goPointsHub;
  final int freeLeft;
  final int monthPoints;
  final bool isLoggedIn;
  final VoidCallback onLogin;
  final int savedCount, appliedCount, myCount;
  final VoidCallback onOpenSaved, onOpenApplied, onOpenMine;
  const MeView({
    super.key, required this.points, required this.coupons, required this.useCoupon, required this.goPointsHub,
    required this.freeLeft, required this.monthPoints, required this.isLoggedIn, required this.onLogin,
    required this.savedCount, required this.appliedCount, required this.myCount,
    required this.onOpenSaved, required this.onOpenApplied, required this.onOpenMine,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 14),
              const Text('로그인이 필요해요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('내 정보와 활동 내역은 로그인 후 볼 수 있어요.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.sub)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow, foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('로그인', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
              const SizedBox(height: 8),
              // 혜택 탭이 진행 중 탭으로 바뀌어, 로그인 전에도 혜택은 여기서 둘러볼 수 있게 한다
              TextButton(
                onPressed: goPointsHub,
                style: TextButton.styleFrom(foregroundColor: AppColors.sub, minimumSize: const Size(0, 44)),
                child: const Text('매일의 혜택 둘러보기 ›', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
        ),
      );
    }
    final liveCoupons = coupons.where((c) => !c.used).length;
    final user = FirebaseAuth.instance.currentUser;
    final nickname = (user?.displayName?.isNotEmpty ?? false) ? user!.displayName! : '겸사겸사 이웃님';
    final rows = [
      ['🛡', '본인인증', '완료'],
      ['🌏', '해외 대행 활동', '가능'],
      ['🎁', '포인트·혜택', ''],
      ['🚫', '신고 / 차단', ''],
      ['⚙️', '설정', ''],
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: 26),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
          child: Row(children: [
            Container(
              width: 58, height: 58, alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.yellowSoft, shape: BoxShape.circle),
              child: const Text('🙂', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                Padding(padding: const EdgeInsets.only(top: 2), child: Text(user?.email ?? '', style: const TextStyle(fontSize: 12.5, color: AppColors.sub, fontWeight: FontWeight.w600))),
              ],
            ),
          ]),
        ),
        if (freeLeft > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Text('🎉', style: TextStyle(fontSize: 17)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('수수료 무료 $freeLeft회 남음', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                    const Padding(padding: EdgeInsets.only(top: 2), child: Text('신규 첫 3거래 수수료 0% · 4번째부터 기본 2%', style: TextStyle(fontSize: 11, color: Colors.white60))),
                  ],
                ),
              ),
            ]),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(16)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🤝', style: TextStyle(fontSize: 20)),
                    Padding(padding: EdgeInsets.only(top: 3), child: Text('도와준 횟수', style: TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w700))),
                    Padding(padding: EdgeInsets.only(top: 2), child: Text.rich(TextSpan(text: '27', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: AppColors.green), children: [TextSpan(text: '회', style: TextStyle(fontSize: 14))]))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(16)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🙋', style: TextStyle(fontSize: 20)),
                    Padding(padding: EdgeInsets.only(top: 3), child: Text('부탁한 횟수', style: TextStyle(fontSize: 12, color: AppColors.yellowDeep, fontWeight: FontWeight.w700))),
                    Padding(padding: EdgeInsets.only(top: 2), child: Text.rich(TextSpan(text: '14', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: AppColors.yellowDeep), children: [TextSpan(text: '회', style: TextStyle(fontSize: 14))]))),
                  ],
                ),
              ),
            ),
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            _stat('41회', '거래 완료'),
            _statDivider(),
            _stat('96%', '응답률'),
            _statDivider(),
            _stat('★ 4.9', '후기 평점'),
          ]),
        ),
        const Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 6), child: Text('이번 달', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(14)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('받은 사례비', style: TextStyle(color: Colors.white60, fontSize: 11.5)),
                    Padding(padding: EdgeInsets.only(top: 3), child: Text('420,000원', style: TextStyle(color: AppColors.yellow, fontSize: 18, fontWeight: FontWeight.w800))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('보유 포인트', style: TextStyle(color: AppColors.sub, fontSize: 11.5)),
                    Padding(padding: const EdgeInsets.only(top: 3), child: Text('${nf(points)}P', style: const TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w800))),
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text('이번 달 +${nf(monthPoints)}P 적립', style: const TextStyle(color: AppColors.blue, fontSize: 10.5, fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
            ),
          ]),
        ),
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyCouponsScreen(
            coupons: coupons, useCoupon: useCoupon, goPointsHub: goPointsHub,
          ))),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Text('🎟', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              const Expanded(child: Text('내 쿠폰', style: TextStyle(fontSize: 14, color: AppColors.ink, fontWeight: FontWeight.w700))),
              Text('$liveCoupons장 ›', style: const TextStyle(fontSize: 12.5, color: AppColors.yellowDeep, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
        const Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 6), child: Text('활동 기록', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink))),
        for (final r in [
          ('🔖', '관심 저장', '$savedCount건', onOpenSaved),
          ('🎁', '매일의 혜택', '', goPointsHub),
          ('🤝', '내가 지원한 부탁', '$appliedCount건', onOpenApplied),
          ('🙋', '내가 올린 부탁', '$myCount건', onOpenMine),
          ('⭐', '내 후기', '4.9 (11)', null),
          ('💰', '수익·정산 내역', '', null),
        ])
          InkWell(
            onTap: r.$4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
              child: Row(children: [
                Text(r.$1, style: const TextStyle(fontSize: 17)),
                const SizedBox(width: 12),
                Expanded(child: Text(r.$2, style: const TextStyle(fontSize: 14, color: AppColors.ink))),
                Text('${r.$3} ›', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
              ]),
            ),
          ),
        const Padding(padding: EdgeInsets.fromLTRB(16, 14, 16, 6), child: Text('설정', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink))),
        for (final r in rows)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
            child: Row(children: [
              Text(r[0], style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 12),
              Expanded(child: Text(r[1], style: const TextStyle(fontSize: 14, color: AppColors.ink))),
              Text('${r[2]} ›', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
            ]),
          ),
        InkWell(
          onTap: () => AuthService().signOut(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: const Row(children: [
              Text('🚪', style: TextStyle(fontSize: 17)),
              SizedBox(width: 12),
              Text('로그아웃', style: TextStyle(fontSize: 14, color: AppColors.red, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _stat(String v, String l) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(children: [
          Text(v, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 3),
          Text(l, style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
        ]),
      ),
    );
  }

  Widget _statDivider() => Container(width: 1, height: 40, color: AppColors.line);
}
