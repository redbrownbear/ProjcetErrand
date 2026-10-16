extension StableSort<T> on List<T> {
  /// 비교 결과가 같은 것끼리는 원래 순서를 지키는 정렬.
  ///
  /// Dart의 [List.sort]는 안정 정렬이 아니다. 32개 이하일 때만 우연히 순서가 지켜지고,
  /// 그보다 많으면 같은 값끼리 뒤섞인다. '진짜 부탁 먼저, 나머지는 원래 순서'처럼
  /// 일부만 비교하는 정렬은 반드시 이걸 쓴다.
  void sortStable(int Function(T a, T b) compare) {
    final indexed = [for (var i = 0; i < length; i++) (i, this[i])];
    indexed.sort((x, y) {
      final c = compare(x.$2, y.$2);
      return c != 0 ? c : x.$1.compareTo(y.$1);
    });
    for (var i = 0; i < length; i++) {
      this[i] = indexed[i].$2;
    }
  }
}
