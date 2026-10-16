class Coupon {
  final int id;
  final String brandK, name, exp, code;
  final int points;
  final bool used;
  const Coupon({
    required this.id,
    required this.brandK,
    required this.name,
    required this.points,
    required this.exp,
    required this.code,
    this.used = false,
  });

  /// 교환한 날부터 쓸 수 있는 기간
  static const validFor = Duration(days: 365);

  /// 유효기간 표기 (예: 2027.10.16). 교환한 날짜를 기준으로 만든다.
  static String expiryFrom(DateTime issued) {
    final d = issued.add(validFor);
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  Coupon copyWith({bool? used}) =>
      Coupon(id: id, brandK: brandK, name: name, points: points, exp: exp, code: code, used: used ?? this.used);

  /// 이 기기 사본용
  Map<String, Object?> toJson() => {
    'id': id,
    'brandK': brandK,
    'name': name,
    'points': points,
    'exp': exp,
    'code': code,
    'used': used,
  };

  static Coupon? fromJson(Object? json) {
    if (json is! Map || json['id'] is! int) return null;
    return Coupon(
      id: json['id'] as int,
      brandK: '${json['brandK'] ?? ''}',
      name: '${json['name'] ?? ''}',
      points: json['points'] is int ? json['points'] as int : 0,
      exp: '${json['exp'] ?? ''}',
      code: '${json['code'] ?? ''}',
      used: json['used'] == true,
    );
  }
}
