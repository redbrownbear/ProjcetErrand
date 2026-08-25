class TaskItem {
  final int id;
  final String mode, cat, title, place, who, gender;
  final double dist, temp, x, y;
  final int mins, price, age;
  final bool hot;
  final String desc;
  final String? extra;
  const TaskItem({
    required this.id, required this.mode, required this.cat, required this.title,
    required this.place, required this.dist, required this.mins, required this.price,
    required this.who, required this.gender, required this.age, required this.temp,
    required this.hot, required this.x, required this.y, required this.desc, this.extra,
  });
}
