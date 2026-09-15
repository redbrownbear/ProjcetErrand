/// 지원한 부탁 하나의 진행 상태.
///
/// 지원 대기 → 매칭 → 진행 → 완료 확인 → 완료. 작업 시작 전에만 취소할 수 있고,
/// 완료 확인 단계에서는 보완 요청으로 진행 중으로 되돌릴 수 있다.
/// 정해진 순서 밖의 요청(단계 건너뛰기·중복 완료)은 무시한다.
class Trade {
  final String status; // pending | matched | working | confirmation | completed | cancelled
  final DateTime updatedAt;
  const Trade(this.status, this.updatedAt);

  static const labels = {
    'pending': '요청자 확인 대기',
    'matched': '매칭 완료',
    'working': '진행 중',
    'confirmation': '완료 확인 대기',
    'completed': '완료',
    'cancelled': '취소됨',
  };

  static const _transitions = {
    'pending': {'accept': 'matched', 'cancel': 'cancelled'},
    'matched': {'start': 'working', 'cancel': 'cancelled'},
    'working': {'finish': 'confirmation'},
    'confirmation': {'confirm': 'completed', 'revise': 'working'},
  };

  factory Trade.pending([DateTime? now]) => Trade('pending', now ?? DateTime.now());

  String get label => labels[status] ?? status;
  bool get isFinished => status == 'completed' || status == 'cancelled';
  bool get isActive => !isFinished;
  bool get canCancel => _transitions[status]?.containsKey('cancel') ?? false;

  /// [action]이 현재 단계에서 허용되면 다음 단계, 아니면 자기 자신을 그대로 돌려준다.
  Trade advance(String action, [DateTime? now]) {
    final next = _transitions[status]?[action];
    return next == null ? this : Trade(next, now ?? DateTime.now());
  }

  Map<String, dynamic> toJson() => {'status': status, 'updatedAt': updatedAt.toIso8601String()};

  static Trade? fromJson(Object? json) {
    if (json is! Map) return null;
    final status = json['status'];
    final at = DateTime.tryParse('${json['updatedAt']}');
    if (status is! String || !labels.containsKey(status) || at == null) return null;
    return Trade(status, at);
  }
}
