import 'trade.dart';

/// '가는 김에 · 제가 가요' 글에서 생긴 부탁 하나.
///
/// 일반 부탁은 부탁 하나에 거래 하나라 부탁 id로 묶어 보지만([Trade]), 가는 김에 글은
/// 글쓴이가 여러 사람의 부탁을 받는다. 그래서 신청(지원서)·거래마다 한 줄씩 따로 둔다.
class GoingDeal {
  /// 글(부탁) id
  final int requestId;
  final String title;

  /// 부탁 내용(신청할 때 적은 것)
  final String ask;

  /// 부탁 비용(사례비)과 예상 물건값·받는 곳
  final int price;
  final int? est;
  final String? spot;

  /// pending | matched | working | confirmation | completed | cancelled
  final String status;

  /// 내가 부탁한 쪽(신청자)이면 true, 글쓴이(맡아 주는 쪽)면 false
  final bool requester;

  /// 상대 이름 — 내가 글쓴이면 신청자 이름, 신청자면 비워 둔다(글쓴이 이름은 글에 있다)
  final String? counterpart;
  final String? tradeId;
  final DateTime updatedAt;

  const GoingDeal({
    required this.requestId,
    required this.title,
    required this.ask,
    required this.price,
    required this.status,
    required this.requester,
    required this.updatedAt,
    this.counterpart,
    this.tradeId,
    this.est,
    this.spot,
  });

  /// 시안 v78의 네 단계 — 부탁 → 수락 → 구매 → 전달.
  /// 서버 단계(matched·working·confirmation·completed)를 이 말로 보여 준다
  String get stage => switch (status) {
    'pending' => '답을 기다려요',
    'matched' => '수락했어요',
    'working' || 'confirmation' => '구매했어요',
    'completed' => '전달 완료',
    _ => '취소·거절됐어요',
  };

  /// 0 부탁 · 1 수락 · 2 구매 · 3 전달 (취소는 -1)
  int get stageIndex => switch (status) {
    'pending' => 0,
    'matched' => 1,
    'working' || 'confirmation' => 2,
    'completed' => 3,
    _ => -1,
  };

  String get key => tradeId ?? 'app:$requestId';
  Trade get trade => Trade(status, updatedAt);
}
