import 'package:cloud_firestore/cloud_firestore.dart';

/// 겸사페이 거래 한 줄.
///
/// 지갑은 **잔액을 따로 저장하지 않고 이 기록을 더해서** 만든다. 돈이 걸린 값에서
/// 잔액과 내역을 따로 두면, 둘이 어긋났을 때 어느 쪽이 맞는지 아무도 모른다.
/// 원장이 원본이고 잔액은 거기서 나온 값이다.
///
/// 지금은 **실제 이체가 일어나지 않는다.** 충전·출금은 결제사(PG)와 계좌 인증이
/// 붙어야 하고, 그때는 이 기록을 앱이 아니라 서버(Cloud Functions)가 써야 한다.
/// 지금 구조는 그 자리를 비워 둔 뼈대다.
enum PayKind {
  /// 계좌·카드에서 충전
  charge('충전', 'plus'),

  /// 부탁을 마치고 받은 사례비
  earn('사례비 정산', 'handshake'),

  /// 내 계좌로 출금
  withdraw('출금', 'arrowRight'),

  /// 부탁 비용 결제
  spend('결제', 'bag'),

  /// 취소·환불
  refund('환불', 'arrowLeft');

  final String label;
  final String icon;
  const PayKind(this.label, this.icon);

  static PayKind parse(Object? raw) =>
      PayKind.values.firstWhere((k) => k.name == raw, orElse: () => PayKind.charge);
}

class PayEntry {
  /// 문서 id. 밀리초 타임스탬프를 쓴다.
  final int id;
  final PayKind kind;

  /// 부호 있는 금액(원). 들어오면 양수, 나가면 음수.
  final int amount;

  /// 화면에 보여줄 설명 (예: '커피 픽업 부탁')
  final String label;

  final DateTime at;

  /// 관련된 부탁 id. 사례비·결제처럼 거래에서 나온 기록에만 있다.
  final int? requestId;

  const PayEntry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.label,
    required this.at,
    this.requestId,
  });

  bool get isIncome => amount >= 0;

  Map<String, Object?> toMap() => {
        'kind': kind.name,
        'amount': amount,
        'label': label,
        'at': Timestamp.fromDate(at),
        'requestId': requestId,
      };

  /// 이 기기 사본용 (LocalStore는 JSON만 다룬다)
  Map<String, Object?> toJson() => {
        'id': id,
        'kind': kind.name,
        'amount': amount,
        'label': label,
        'at': at.toIso8601String(),
        'requestId': requestId,
      };

  static PayEntry? fromMap(String docId, Map<String, dynamic> m) {
    final id = int.tryParse(docId);
    final amount = m['amount'];
    if (id == null || amount is! int) return null;
    final at = m['at'];
    return PayEntry(
      id: id,
      kind: PayKind.parse(m['kind']),
      amount: amount,
      label: m['label'] is String ? m['label'] as String : '',
      at: at is Timestamp ? at.toDate() : (DateTime.tryParse('$at') ?? DateTime.now()),
      requestId: m['requestId'] is int ? m['requestId'] as int : null,
    );
  }

  static PayEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'], amount = json['amount'];
    if (id is! int || amount is! int) return null;
    return PayEntry(
      id: id,
      kind: PayKind.parse(json['kind']),
      amount: amount,
      label: json['label'] is String ? json['label'] as String : '',
      at: DateTime.tryParse('${json['at']}') ?? DateTime.now(),
      requestId: json['requestId'] is int ? json['requestId'] as int : null,
    );
  }

  /// 잔액 = 기록의 합. 음수로는 내려가지 않게 막는다(있을 수 없는 상태라 화면에서 거른다).
  static int balanceOf(Iterable<PayEntry> entries) {
    final sum = entries.fold<int>(0, (a, e) => a + e.amount);
    return sum < 0 ? 0 : sum;
  }
}
