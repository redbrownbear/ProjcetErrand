import '../models/reward_brand.dart';

const rshopCats = [
  ['all', '전체'],
  ['cafe', '카페'],
  ['chicken', '치킨'],
  ['cvs', '편의점'],
  ['dessert', '디저트'],
  ['fastfood', '패스트푸드'],
  ['life', '생활'],
];

const rewardBrands = [
  RewardBrand('starbucks', '스타벅스', '☕', 'cafe'),
  RewardBrand('mega', '메가커피', '☕', 'cafe'),
  RewardBrand('compose', '컴포즈커피', '☕', 'cafe'),
  RewardBrand('ediya', '이디야', '☕', 'cafe'),
  RewardBrand('twosome', '투썸플레이스', '🍰', 'cafe'),
  RewardBrand('bbq', 'BBQ', '🍗', 'chicken'),
  RewardBrand('baskin', '배스킨라빈스', '🍨', 'dessert'),
  RewardBrand('paris', '파리바게뜨', '🥐', 'dessert'),
  RewardBrand('tlj', '뚜레쥬르', '🥖', 'dessert'),
  RewardBrand('cu', 'CU', '🏪', 'cvs'),
  RewardBrand('gs25', 'GS25', '🏪', 'cvs'),
  RewardBrand('moms', '맘스터치', '🍔', 'fastfood'),
  RewardBrand('lotteria', '롯데리아', '🍔', 'fastfood'),
  RewardBrand('burgerking', '버거킹', '🍔', 'fastfood'),
  RewardBrand('oliveyoung', '올리브영', '💄', 'life'),
];

RewardBrand brandOf(String k) {
  for (final b in rewardBrands) {
    if (b.k == k) return b;
  }
  return const RewardBrand('', '브랜드', '🎁', 'life');
}
