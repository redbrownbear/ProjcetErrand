import 'package:cloud_firestore/cloud_firestore.dart';

/// `users/{uid}` 문서. 내 정보 화면에 보이는 "나"의 실제 정보다.
///
/// 이 안에는 **서버에만 있는 값**만 담는다. 도와준 횟수·거래 완료 수·이번 달 사례비처럼
/// 거래 기록에서 계산되는 값은 여기 저장하지 않고 [ProfileStats]가 그때그때 센다.
/// 같은 숫자를 두 곳에 두면 반드시 어긋나기 때문이다.
class UserProfile {
  final String uid;
  final String email;
  final String nickname;

  /// 활동 지역. 아직 고르지 않았으면 null.
  final String? region;

  /// 본인인증 여부. 인증 수단이 붙기 전까지는 항상 false다.
  final bool verified;

  /// 보유 포인트
  final int points;

  final DateTime? createdAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.nickname,
    this.region,
    this.verified = false,
    this.points = 0,
    this.createdAt,
  });

  static const defaultNickname = '겸사겸사 이웃님';

  factory UserProfile.fromMap(String uid, Map<String, dynamic> m) {
    final created = m['createdAt'];
    return UserProfile(
      uid: uid,
      email: m['email'] is String ? m['email'] as String : '',
      nickname: m['nickname'] is String && (m['nickname'] as String).isNotEmpty ? m['nickname'] as String : defaultNickname,
      region: m['region'] is String ? m['region'] as String : null,
      verified: m['verified'] == true,
      points: m['points'] is int ? m['points'] as int : 0,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  /// 서버에 문서가 아직 없을 때 쓰는 기본값. 로그인 계정 정보만 채운다.
  factory UserProfile.blank({required String uid, required String email, String? nickname}) => UserProfile(
        uid: uid,
        email: email,
        nickname: (nickname == null || nickname.isEmpty) ? defaultNickname : nickname,
      );

  Map<String, Object?> toMap() => {
        'email': email,
        'nickname': nickname,
        'region': region,
        'verified': verified,
        'points': points,
      };

  UserProfile copyWith({String? nickname, String? region, bool? verified, int? points}) => UserProfile(
        uid: uid,
        email: email,
        nickname: nickname ?? this.nickname,
        region: region ?? this.region,
        verified: verified ?? this.verified,
        points: points ?? this.points,
        createdAt: createdAt,
      );
}

/// 내 정보 화면의 숫자들. 전부 실제 기록에서 센 값이고, 셀 자료가 없으면 null이다.
///
/// null은 화면에서 '—'로 그린다. 아직 없는 기능(후기·응답률)을 그럴듯한 숫자로
/// 채워 두면 나중에 진짜 값이 들어왔을 때 사용자가 먼저 이상함을 느낀다.
class ProfileStats {
  /// 내가 지원해서 완료까지 간 건수
  final int helped;

  /// 내가 올린 부탁 수
  final int requested;

  /// 완료한 거래 수 (helped + 내 부탁 중 완료)
  final int completed;

  /// 진행 중인 건수
  final int active;

  /// 시작해 놓고 취소한 건수. 신뢰 레벨 점수를 깎는 유일한 항목이다.
  final int cancelled;

  /// 완료한 거래의 사례비 합계(원)
  final int earnedCash;

  /// 이번 달 완료분의 사례비 합계(원)
  final int monthEarnedCash;

  /// 관심 저장 수
  final int saved;

  /// 지원한 부탁 수 (취소 제외)
  final int applied;

  /// 쓸 수 있는 쿠폰 수
  final int coupons;

  /// 후기 평점·개수. 후기 기능이 붙기 전에는 null.
  final double? rating;
  final int reviews;

  /// 응답률(%). 집계 자료가 없으면 null.
  final int? responseRate;

  const ProfileStats({
    this.helped = 0,
    this.requested = 0,
    this.completed = 0,
    this.active = 0,
    this.cancelled = 0,
    this.earnedCash = 0,
    this.monthEarnedCash = 0,
    this.saved = 0,
    this.applied = 0,
    this.coupons = 0,
    this.rating,
    this.reviews = 0,
    this.responseRate,
  });
}
