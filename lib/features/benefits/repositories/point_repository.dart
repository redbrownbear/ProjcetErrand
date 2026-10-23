import '../../../core/backend/server_api.dart';

/// 서버가 정한 적립 결과. [amount]가 0이면 이미 받은 보상이다
class EarnResult {
  final String key;
  final int amount;
  final int balance;
  const EarnResult({required this.key, required this.amount, required this.balance});

  static EarnResult fromMap(Map<String, Object?> m) => EarnResult(
    key: '${m['key'] ?? ''}',
    amount: m['amount'] is num ? (m['amount'] as num).toInt() : 0,
    balance: m['balance'] is num ? (m['balance'] as num).toInt() : 0,
  );
}

/// 포인트 서버 함수(B09, functions/src/points). 금액 · 잔액은 서버가 정하고 원장(`users/{uid}/pointLedger`)에 남긴다.
/// 실패하면 [ServerException] — 서버가 보낸 한국어 문구를 그대로 보여 준다.
class PointRepository {
  const PointRepository();

  /// 오늘 출석. 연속 · 월 누적 보너스도 서버가 계산한다
  Future<EarnResult> attend() async => EarnResult.fromMap(await ServerApi.call('earnPoints', {'kind': 'attend'}));

  /// 상품 교환. 새 잔액
  Future<int> redeem(String productId) async {
    final r = await ServerApi.call('redeemPoints', {'productId': productId});
    return r['balance'] is num ? (r['balance'] as num).toInt() : 0;
  }

  Future<void> useCoupon(int id) => ServerApi.call('useCoupon', {'couponId': '$id'});
}
