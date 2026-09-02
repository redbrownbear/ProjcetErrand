import '../data/gongu.dart';
import '../models/gongu.dart';

/// 공구 목록의 출처를 감싸는 이음매. [LocalErrandRepository]와 동일한 목적.
abstract class GonguRepository {
  List<Gongu> fetchItems();
}

class LocalGonguRepository implements GonguRepository {
  @override
  List<Gongu> fetchItems() => List.of(gonguItems);
}
