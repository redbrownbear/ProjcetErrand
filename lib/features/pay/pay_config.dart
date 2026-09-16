import 'package:flutter/foundation.dart';

/// 겸사페이 개발 스위치.
///
/// 충전·출금은 **전자금융거래법 검토가 끝나기 전까지 실제로 열지 않는다.**
/// 잔액을 보관했다가 나중에 쓰게 하는 순간 선불전자지급수단에 해당할 수 있고,
/// 그러면 등록 의무가 생긴다. 이건 코드로 해결할 문제가 아니다.
///
/// 그때까지 흐름만 만져볼 수 있도록 **디버그 빌드에서만** 원장에 줄을 쌓는 통로를
/// 열어 둔다. 실제 돈은 1원도 움직이지 않고, 기록에도 '개발용'이라고 남는다.
///
/// [kDebugMode]는 컴파일 타임 상수라, 릴리스 빌드에서는 이 값을 보는 분기 전체가
/// 트리 셰이킹으로 사라진다. 실수로 켠 채 배포되는 일이 없다.
class PayConfig {
  PayConfig._();

  /// 디버그 빌드에서만 충전·출금 버튼이 실제로 동작한다.
  static const debugTopUp = kDebugMode;

  /// 개발용 충전 버튼이 제안하는 금액
  static const quickCharge = [10000, 30000, 50000];

  /// 한 번에 넣을 수 있는 최대 금액. 개발 중 실수로 큰 숫자를 넣어
  /// 화면이 깨지는 걸 막는 정도의 상한이다.
  static const maxAmount = 1000000;

  static const chargeLabel = '개발용 충전';
  static const withdrawLabel = '개발용 출금';
}
