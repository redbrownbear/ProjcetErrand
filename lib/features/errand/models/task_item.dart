import 'comment.dart';

class TaskItem {
  final int id;
  final String mode; // ask | sea | together
  final String cat;
  final String? tcat; // together 카테고리
  final String title;
  final String? region;
  final String? place;
  final String? country;
  final String? cc; // 해외 국가 코드
  final String? city;
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
  final String? ago;
  final int likes;
  final int joinCur;
  final int joinMax;
  final List<Comment> comments;
  final double? lat, lng;

  const TaskItem({
    required this.id,
    required this.mode,
    this.cat = 'etc',
    this.tcat,
    required this.title,
    this.region,
    this.place,
    this.country,
    this.cc,
    this.city,
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
    this.ago,
    this.likes = 0,
    this.joinCur = 0,
    this.joinMax = 0,
    this.comments = const [],
    this.lat,
    this.lng,
  });
}
