import 'package:flutter/foundation.dart';

import 'coupon.dart';
import 'reward_product.dart';

/// 내 포인트와 쿠폰, 그리고 그걸 바꾸는 행동.
///
/// 포인트샵·내 쿠폰 화면은 열어 둔 채로 교환·사용을 한다. 예전엔 포인트를 숫자로 넘겨서
/// 화면이 연 순간의 값에 묶였다 — 교환해도 보유 포인트가 그대로였고, 교환에 실패해도
/// '교환 완료'가 떴다. 그래서 값 대신 읽는 함수와 바뀜 알림([changes])을 넘긴다.
class PointWallet {
  /// 포인트·쿠폰이 바뀌면 알린다. 열린 화면은 이걸 듣고 다시 그린다.
  final Listenable changes;

  /// 지금 값을 읽는 함수. 화면에서는 [points]·[coupons]로 읽는다.
  final int Function() readPoints;
  final List<Coupon> Function() readCoupons;

  /// 상품 교환. 실제로 교환됐으면 true (로그인을 취소했거나 포인트가 모자라면 false).
  final Future<bool> Function(RewardProduct) redeem;
  final void Function(int id) useCoupon;

  const PointWallet({
    required this.changes,
    required this.readPoints,
    required this.readCoupons,
    required this.redeem,
    required this.useCoupon,
  });

  /// 바뀌지 않는 지갑. 화면 테스트처럼 교환이 일어나지 않는 곳에 쓴다.
  factory PointWallet.fixed({int points = 0, List<Coupon> coupons = const []}) => PointWallet(
    changes: const _Never(),
    readPoints: () => points,
    readCoupons: () => coupons,
    redeem: (_) async => false,
    useCoupon: (_) {},
  );

  int get points => readPoints();
  List<Coupon> get coupons => readCoupons();

  /// 아직 안 쓴 쿠폰 수
  int get liveCoupons => coupons.where((c) => !c.used).length;
}

class _Never implements Listenable {
  const _Never();
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}
