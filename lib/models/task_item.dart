class TaskItem {
  final int id;
  final String mode; // ask | sea | together
  final String cat;
  final String title;
  final String? region;
  final String? place;
  final String? country;
  final double distM;
  final int mins;
  final int price;
  final String who;
  final double rating;
  final int reviews;
  final int deals;
  final int resp;
  final bool verified;
  final int helpCnt;
  final int reqCnt;
  final double x, y;
  final String desc;
  final bool hot;
  final String? extra;

  const TaskItem({
    required this.id,
    required this.mode,
    this.cat = 'etc',
    required this.title,
    this.region,
    this.place,
    this.country,
    required this.distM,
    this.mins = 0,
    this.price = 0,
    required this.who,
    this.rating = 5.0,
    this.reviews = 0,
    this.deals = 0,
    this.resp = 100,
    this.verified = true,
    this.helpCnt = 0,
    this.reqCnt = 1,
    this.x = 50,
    this.y = 50,
    required this.desc,
    this.hot = false,
    this.extra,
  });
}
