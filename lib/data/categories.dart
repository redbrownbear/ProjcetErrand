import '../models/cat.dart';

const cats = [
  Cat('line', '줄서기', '🧍', 'ask'),
  Cat('buy', '사오기', '🛍️', 'ask'),
  Cat('pickup', '받아오기', '📦', 'ask'),
  Cat('photo', '사진', '📸', 'ask'),
  Cat('ticket', '티켓·굿즈', '🎫', 'ask'),
  Cat('move', '운반', '🚚', 'ask'),
  Cat('clean', '청소', '🧹', 'ask'),
  Cat('pet', '반려동물', '🐕', 'ask'),
  Cat('carpool', '카풀', '🚗', 'ask'),
  Cat('rent', '빌려주기', '🔑', 'ask'),
  Cat('assemble', '조립·설치', '🔧', 'ask'),
  Cat('study', '과외·레슨', '📚', 'ask'),
  Cat('share', '나눔', '🎁', 'share'),
  Cat('movie', '영화', '🎬', 'together'),
  Cat('meal', '밥친구', '🍜', 'together'),
  Cat('run', '러닝메이트', '🏃', 'together'),
];

Cat? catOf(String k) {
  for (final c in cats) {
    if (c.k == k) return c;
  }
  return null;
}
