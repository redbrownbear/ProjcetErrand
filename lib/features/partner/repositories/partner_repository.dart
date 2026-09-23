import '../../../core/storage/local_store.dart';
import '../models/partner_proposal.dart';

/// 저장한 협업 제안서. 시안과 같이 **이 기기에만** 남는다.
///
/// 실제 서비스에서는 운영팀이 받아 검토해야 하므로 서버 연동이 필요하다.
/// 화면에도 "실제 담당자 접수는 연동 전"이라고 밝혀 둔다.
class PartnerRepository {
  static const _key = 'partnerProposals';

  static List<PartnerProposal> load() {
    final raw = LocalStore.read<List<dynamic>>(_key, const []);
    return [
      for (final e in raw)
        if (e is Map<String, dynamic>) PartnerProposal.fromJson(e),
    ];
  }

  static void save(List<PartnerProposal> list) => LocalStore.write(_key, [for (final p in list) p.toJson()]);

  /// 새 제안서를 맨 앞에 넣고 저장한다.
  static List<PartnerProposal> add(PartnerProposal proposal) {
    final next = [proposal, ...load()];
    save(next);
    return next;
  }
}
