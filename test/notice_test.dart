import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/features/notice/models/notice.dart';
import 'package:gyeomsa/features/notice/repositories/notice_repository.dart';
import 'package:gyeomsa/features/notice/screens/notice_screens.dart';

class _Fixed extends NoticeRepository {
  final List<Notice> list;
  const _Fixed(this.list);
  @override
  Stream<List<Notice>> watch({int limit = 50}) => Stream.value(list);
}

/// A33 공지: 숨김 · 예약 · 고정 순서, 목록 · 상세가 폰 폭에서 깨지지 않는다
void main() {
  final now = DateTime(2026, 10, 23, 12);
  Notice n(String id, int daysAgo, {bool pinned = false}) =>
      Notice(id: id, title: '공지 $id', body: '본문 $id\n둘째 줄', pinned: pinned, publishedAt: now.subtract(Duration(days: daysAgo)));

  test('문서 읽기: 숨긴 글 · 제목 없는 글은 버린다', () {
    final at = Timestamp.fromDate(now);
    expect(Notice.fromDoc('a', {'title': '점검', 'kind': 'update', 'publishedAt': at})!.kindLabel, '업데이트');
    expect(Notice.fromDoc('b', {'title': '점검', 'kind': '??', 'publishedAt': at})!.kindLabel, '공지');
    expect(Notice.fromDoc('c', {'title': '점검', 'hidden': true, 'publishedAt': at}), isNull);
    expect(Notice.fromDoc('d', {'title': ' ', 'publishedAt': at}), isNull);
    expect(Notice.fromDoc('e', {'title': '점검'}), isNull);
  });

  test('예약 글은 그 시각부터, 고정 먼저 그다음 최신 순, 새 글 수', () {
    final list = [n('old', 5), n('new', 1), n('pin', 9, pinned: true), n('future', -1)];
    final v = Notice.visible(list, now);
    expect(v.map((x) => x.id), ['pin', 'new', 'old']);
    expect(Notice.unseen(v, now.subtract(const Duration(days: 2))), 1);
    expect(Notice.unseen(v, null), 3);
  });

  testWidgets('목록 → 상세', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: NoticeListScreen(repo: _Fixed([n('a', 1), n('b', 3, pinned: true)]), now: now)));
    await tester.pump();
    expect(find.text('고정 · 공지'), findsOneWidget);
    expect(find.text('공지 a'), findsOneWidget);
    await tester.tap(find.text('공지 a'));
    await tester.pumpAndSettle();
    expect(find.text('본문 a\n둘째 줄'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('공지가 없으면 빈 화면', (tester) async {
    await tester.pumpWidget(MaterialApp(home: NoticeListScreen(repo: const _Fixed([]), now: now)));
    await tester.pump();
    expect(find.text('아직 올라온 공지가 없어요'), findsOneWidget);
  });
}
