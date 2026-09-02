import '../data/partner_missions.dart';
import '../data/reward_products.dart';
import '../models/partner_mission.dart';
import '../models/reward_product.dart';

/// 혜택/포인트 관련 목록(리워드 상품, 파트너 미션)의 출처를 감싸는 이음매.
/// [LocalErrandRepository]와 동일한 목적.
abstract class BenefitsRepository {
  List<RewardProduct> fetchRewardProducts();
  List<PartnerMission> fetchPartnerMissions();
}

class LocalBenefitsRepository implements BenefitsRepository {
  @override
  List<RewardProduct> fetchRewardProducts() => List.of(rewardProducts);

  @override
  List<PartnerMission> fetchPartnerMissions() => List.of(partnerMissions);
}
