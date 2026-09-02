import '../data/items.dart';
import '../models/task_item.dart';

/// 부탁(errand) 목록의 출처를 감싸는 이음매.
/// 지금은 하드코딩 시드 데이터를 반환하지만, 나중에 백엔드가 준비되면
/// [FirestoreErrandRepository] 같은 구현체로 교체하면 됨 — 호출부(HomeShell)는 그대로.
abstract class ErrandRepository {
  List<TaskItem> fetchSeedItems();
}

class LocalErrandRepository implements ErrandRepository {
  @override
  List<TaskItem> fetchSeedItems() => List.of(seedItems);
}
