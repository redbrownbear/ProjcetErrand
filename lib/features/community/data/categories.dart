import '../../../core/models/cat.dart';

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
