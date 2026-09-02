import '../../../core/models/cat.dart';

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
