import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

/// 신뢰 레벨.
///
/// 거래를 잘 마칠수록 점수가 쌓이고, 점수가 구간을 넘으면 레벨이 오른다.
/// 시작해 놓고 취소하면 점수가 깎인다.
///
/// **실제 기록에서만 계산한다.** 후기 기능이 없으므로 후기 점수는 들어가지 않고,
/// 지금 셀 수 있는 것(완료·도움·취소·본인인증)만으로 만든다. 없는 지표를 섞어서
/// 그럴듯한 숫자를 만들면, 나중에 진짜 후기가 들어왔을 때 레벨이 이유 없이 출렁인다.
///
/// 서버에 저장하지 않고 매번 센다. 거래 기록이 원본이고 레벨은 거기서 나온 값이라,
/// 두 곳에 두면 언젠가 어긋나고 그때 어느 쪽이 맞는지 알 수 없게 된다.
/// (다른 사람의 레벨을 보여줄 때가 되면 그때 서버 집계로 옮긴다)
class TrustLevel {
  static const perCompleted = 10; // 거래를 끝까지 마쳤을 때
  static const perHelped = 5; // 그중 내가 도와준 쪽이면 더
  static const verifiedBonus = 20; // 본인인증
  static const perCancelled = 5; // 시작해 놓고 취소했을 때 (차감)

  /// (필요 점수, 레벨, 이름). 위로 갈수록 간격이 넓어져서 초반에 자주 오른다.
  static const tiers = <(int, int, String)>[
    (0, 1, '새싹 이웃'),
    (30, 2, '동네 이웃'),
    (80, 3, '믿음직한 이웃'),
    (160, 4, '든든한 이웃'),
    (300, 5, '동네 반장'),
  ];

  /// 쌓은 신뢰 점수. 0 아래로는 내려가지 않는다.
  final int score;
  const TrustLevel(this.score);

  factory TrustLevel.from({
    required int completed,
    required int helped,
    required int cancelled,
    required bool verified,
  }) {
    final raw = completed * perCompleted +
        helped * perHelped +
        (verified ? verifiedBonus : 0) -
        cancelled * perCancelled;
    return TrustLevel(raw < 0 ? 0 : raw);
  }

  /// 지금 속한 구간
  (int, int, String) get _tier {
    var found = tiers.first;
    for (final t in tiers) {
      if (score >= t.$1) found = t;
    }
    return found;
  }

  int get level => _tier.$2;
  String get name => _tier.$3;

  /// 이번 레벨이 시작된 점수
  int get floor => _tier.$1;

  /// 다음 레벨에 필요한 점수. 최고 레벨이면 null.
  int? get nextAt {
    for (final t in tiers) {
      if (t.$1 > score) return t.$1;
    }
    return null;
  }

  bool get isMax => nextAt == null;

  /// 아직 아무 기록도 없는 상태
  bool get isFresh => score == 0;

  /// 이번 레벨 안에서의 진행률
  double get progress {
    final next = nextAt;
    if (next == null) return 1;
    final span = next - floor;
    if (span <= 0) return 1;
    return ((score - floor) / span).clamp(0.0, 1.0);
  }

  String get nextHint {
    final next = nextAt;
    if (next == null) return '최고 레벨이에요';
    return '다음 레벨까지 ${next - score}점';
  }

  Color get color => switch (level) {
        2 => AppColors.green,
        3 => AppColors.blue,
        4 => AppColors.purple,
        >= 5 => AppColors.yellowDeep,
        _ => AppColors.sub,
      };

  /// 무엇을 하면 오르는지. 규칙을 숨기지 않고 그대로 보여준다.
  static const rule = '거래를 끝까지 마치면 +$perCompleted점 · 도와준 거래는 +$perHelped점 더 · '
      '본인인증 +$verifiedBonus점 · 시작한 거래를 취소하면 −$perCancelled점';
}
