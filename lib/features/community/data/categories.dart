import '../../../core/models/cat.dart';

/// 같이해요 커뮤니티 카테고리
const tcats = [
  Cat('meal', '밥친구', 'food'),
  Cat('sport', '운동', 'walk'),
  Cat('movie', '영화', 'play'),
  Cat('art', '전시', 'sparkles'),
  Cat('show', '공연', 'ticket'),
  Cat('study', '스터디', 'clipboard'),
  Cat('hobby', '취미', 'sparkles'),
  Cat('cafe', '카페', 'coffee'),
  Cat('pet', '반려동물', 'pet'),
  Cat('talk', '동네수다', 'chat'),
];

Cat tcatOf(String? k) {
  for (final c in tcats) {
    if (c.k == k) return c;
  }
  return const Cat('etc', '모임', 'users');
}
