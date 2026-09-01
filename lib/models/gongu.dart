class GonguStep {
  final int n;
  final String label;
  const GonguStep(this.n, this.label);
}

class Gongu {
  final String id, icon, brand, title;
  final int list, price, joined, target;
  final List<GonguStep> steps;
  const Gongu({
    required this.id,
    required this.icon,
    required this.brand,
    required this.title,
    required this.list,
    required this.price,
    required this.joined,
    required this.target,
    required this.steps,
  });
}
