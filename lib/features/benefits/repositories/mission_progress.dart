import '../../../core/storage/local_store.dart';

/// 미션 참여 단계. 시안(`gyumsa-refined`)의 `missionProgress`.
///
/// 개편 전에는 "완료했는지"만 있어서 목록에서 참여 중인 미션을 구분할 수 없었다.
/// 시안은 참여 시작 → 인증 제출 → 검수 → 적립 네 단계를 보여주므로 중간 상태를
/// 들고 있어야 한다. 적립 완료는 기존 `doneMissions`가 그대로 맡는다.
///
/// 이 기기에만 남는다. 실제 서비스에서는 제휴사 검수 결과를 서버가 갖고 있어야 한다.
enum MissionStage {
  /// 아직 시작 전
  ready,

  /// 참여 중 — 인증 내용을 쓰는 단계
  active,

  /// 인증 제출 후 검수 대기
  review,
}

class MissionProgress {
  static const _key = 'missionProgress';

  /// 미션 id → 단계
  final Map<String, MissionStage> stages;

  /// 미션 id → 제출한 인증 내용
  final Map<String, String> proofs;

  const MissionProgress({this.stages = const {}, this.proofs = const {}});

  MissionStage stageOf(String id) => stages[id] ?? MissionStage.ready;
  String proofOf(String id) => proofs[id] ?? '';

  static MissionProgress load() {
    final raw = LocalStore.read<Map<String, dynamic>>(_key, const {});
    final stages = <String, MissionStage>{};
    final proofs = <String, String>{};
    for (final e in raw.entries) {
      final v = e.value;
      if (v is! Map) continue;
      stages[e.key] = MissionStage.values.firstWhere(
        (s) => s.name == '${v['stage']}',
        orElse: () => MissionStage.ready,
      );
      proofs[e.key] = '${v['proof'] ?? ''}';
    }
    return MissionProgress(stages: stages, proofs: proofs);
  }

  /// [id]의 단계를 바꾸고 저장한 새 값을 돌려준다.
  MissionProgress update(String id, MissionStage stage, {String? proof}) {
    final nextStages = {...stages, id: stage};
    final nextProofs = {...proofs, id: ?proof};
    final next = MissionProgress(stages: nextStages, proofs: nextProofs);
    LocalStore.write(_key, {
      for (final key in nextStages.keys)
        key: {'stage': nextStages[key]!.name, 'proof': nextProofs[key] ?? ''},
    });
    return next;
  }
}
