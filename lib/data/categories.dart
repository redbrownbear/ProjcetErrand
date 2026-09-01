import '../models/cat.dart';

const cats = [
  Cat('line', '줄서기', '🧍'),
  Cat('buy', '사오기', '🛍️'),
  Cat('pickup', '받아오기', '📦'),
  Cat('photo', '사진', '📸'),
  Cat('ticket', '티켓·굿즈', '🎫'),
  Cat('move', '운반', '🚚'),
  Cat('clean', '청소', '🧹'),
  Cat('pet', '펫', '🐶'),
  Cat('proxy', '구매대행', '🛒'),
  Cat('etc', '기타', '✨'),
];

Cat catOf(String k) {
  for (final c in cats) {
    if (c.k == k) return c;
  }
  return const Cat('etc', '부탁', '🙌');
}

/// 같이해요 커뮤니티 카테고리
const tcats = [
  Cat('meal', '밥친구', '🍚'),
  Cat('sport', '운동', '🏃'),
  Cat('movie', '영화', '🎬'),
  Cat('art', '전시', '🎨'),
  Cat('show', '공연', '🎵'),
  Cat('study', '스터디', '📚'),
  Cat('hobby', '취미', '🎮'),
  Cat('cafe', '카페', '☕'),
  Cat('pet', '반려동물', '🐶'),
  Cat('talk', '동네수다', '🗣'),
];

Cat tcatOf(String? k) {
  for (final c in tcats) {
    if (c.k == k) return c;
  }
  return const Cat('etc', '모임', '🙌');
}
