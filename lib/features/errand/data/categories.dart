import '../../../core/models/cat.dart';

const cats = [
  Cat('line', '줄서기', 'queue'),
  Cat('buy', '사오기', 'bag'),
  Cat('pickup', '받아오기', 'box'),
  Cat('photo', '사진', 'camera'),
  Cat('ticket', '티켓·굿즈', 'ticket'),
  Cat('move', '운반', 'truck'),
  Cat('clean', '청소', 'broom'),
  Cat('pet', '펫', 'pet'),
  Cat('proxy', '구매대행', 'cart'),
  Cat('etc', '기타', 'sparkles'),
];

Cat catOf(String k) {
  for (final c in cats) {
    if (c.k == k) return c;
  }
  return const Cat('etc', '부탁', 'users');
}
