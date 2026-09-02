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

  Coupon copyWith({bool? used}) => Coupon(
        id: id, brandK: brandK, name: name, points: points, exp: exp, code: code,
        used: used ?? this.used,
      );
}
