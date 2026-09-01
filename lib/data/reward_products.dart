import '../models/reward_product.dart';
import 'reward_brands.dart';

const rewardProducts = [
  RewardProduct('r1', 'starbucks', '아이스 아메리카노 T', 4500, hot: true),
  RewardProduct('r2', 'starbucks', '카페라떼 T', 5000),
  RewardProduct('r3', 'mega', '아메리카노', 2000, hot: true),
  RewardProduct('r4', 'compose', '아메리카노', 2200),
  RewardProduct('r5', 'ediya', '아메리카노', 3200),
  RewardProduct('r6', 'twosome', '아메리카노 + 조각케이크', 9500),
  RewardProduct('r7', 'bbq', '황금올리브치킨 + 콜라', 23000, hot: true),
  RewardProduct('r8', 'baskin', '싱글레귤러', 3900),
  RewardProduct('r9', 'baskin', '파인트', 9800, hot: true),
  RewardProduct('r10', 'cu', '5,000원 모바일 상품권', 5000, hot: true),
  RewardProduct('r11', 'gs25', '10,000원 모바일 상품권', 10000),
  RewardProduct('r12', 'paris', '5,000원 모바일 상품권', 5000),
  RewardProduct('r13', 'tlj', '5,000원 모바일 상품권', 5000),
  RewardProduct('r14', 'moms', '싸이버거 세트', 8500),
  RewardProduct('r15', 'lotteria', '불고기버거 세트', 8000),
  RewardProduct('r16', 'burgerking', '와퍼 세트', 9500),
  RewardProduct('r17', 'oliveyoung', '10,000원 상품권', 10000),
];

class RewardGoal {
  final String name;
  final int remain;
  const RewardGoal(this.name, this.remain);
}

RewardGoal? nextRewardGoal(int pts) {
  final ups = rewardProducts.where((p) => p.points > pts).toList()
    ..sort((a, b) => a.points.compareTo(b.points));
  if (ups.isEmpty) return null;
  final up = ups.first;
  return RewardGoal('${brandOf(up.brand).name} ${up.name}', up.points - pts);
}
