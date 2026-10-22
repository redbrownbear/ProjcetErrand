import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/core/backend/server_api.dart';
import 'package:gyeomsa/features/admin/models/admin_report.dart';
import 'package:gyeomsa/features/admin/repositories/admin_repository.dart';
import 'package:gyeomsa/features/admin/screens/admin_reports_screen.dart';

/// 서버 대신 메모리에서 답하는 운영자 저장소
class _FakeRepo implements AdminRepository {
  final List<AdminReport> reports;
  final calls = <String>[];
  String? failWith;
  bool hidden = false;
  _FakeRepo(this.reports);

  @override
  Stream<List<AdminReport>> watchReports({int limit = 200}) => Stream.value(reports);

  @override
  Stream<AdminUser> watchUser(String uid) =>
      Stream.value(AdminUser(uid: uid, nickname: uid == 'b' ? '신고된이웃' : '신고한이웃'));

  @override
  Stream<AdminRequest?> watchRequest(String id) => Stream.value(
    AdminRequest(id: id, title: '편의점 택배 찾아 주세요', status: hidden ? 'hidden' : 'open', who: '신고된이웃', hiddenBy: hidden ? 'admin' : null),
  );

  @override
  Future<void> resolve(String reportId, ReportResolution resolution, String memo) async {
    if (failWith != null) throw ServerException(failWith!);
    calls.add('resolve:$reportId:${resolution.name}:$memo');
  }

  @override
  Future<void> setSuspended(String uid, bool suspended, {String? reason}) async => calls.add('suspend:$uid:$suspended');

  @override
  Future<void> setRequestHidden(String requestId, bool hidden, {String? reason}) async {
    this.hidden = hidden;
    calls.add('hide:$requestId:$hidden');
  }
}

AdminReport _report(String id, {String target = 'b', String? status, String? resolution}) => AdminReport.fromDoc(id, {
  'reporterUid': 'a',
  'targetUid': target,
  'requestId': '7',
  'reason': '노쇼·약속 불이행',
  'detail': '약속 장소에 안 나왔어요',
  'createdAt': Timestamp.fromDate(DateTime(2026, 10, 22, 14, 5)),
  'status': ?status,
  'resolution': ?resolution,
})!;

void main() {
  Future<void> phone(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(360 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pump();
  }

  test('신고 문서 읽기: 상태가 없으면 처리 전, resolved면 결과, 필수 값이 없으면 버린다', () {
    expect(_report('r1').resolved, isFalse);
    final done = _report('r2', status: 'resolved', resolution: 'warned');
    expect(done.resolution, ReportResolution.warned);
    expect(AdminReport.fromDoc('x', {'reason': '기타'}), isNull);
    expect(const AdminRequest(id: '1', title: 't', status: 'hidden', who: '', hiddenBy: 'admin').canUnhide, isTrue);
    expect(const AdminRequest(id: '1', title: 't', status: 'hidden', who: '').canUnhide, isFalse);
  });

  testWidgets('목록: 처리 전 · 처리됨으로 나누고, 같은 사람 신고 수를 보여 준다', (tester) async {
    final repo = _FakeRepo([_report('r1'), _report('r2'), _report('r3', target: 'c', status: 'resolved', resolution: 'dismissed')]);
    await phone(tester, AdminReportsScreen(repo: repo));
    await tester.pump();
    expect(find.text('처리 전 2'), findsOneWidget);
    expect(find.text('처리됨 1'), findsOneWidget);
    expect(find.textContaining('이 사람 신고 2건'), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('admin-tab-done')));
    await tester.pump();
    expect(find.text('문제 없음'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('상세: 경고 처리 · 글 내리기 · 정지는 확인 뒤, 실패 문구', (tester) async {
    final repo = _FakeRepo([_report('r1')]);
    await phone(tester, AdminReportDetailScreen(report: repo.reports.first, repo: repo));
    await tester.pump();
    expect(find.text('신고된이웃'), findsOneWidget);
    expect(find.text('편의점 택배 찾아 주세요'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('admin-memo')), '첫 신고');
    await tester.tap(find.byKey(const Key('admin-resolve-warned')));
    await tester.pump();
    expect(repo.calls, contains('resolve:r1:warned:첫 신고'));
    expect(find.text('처리했어요: 경고'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('admin-hide')));
    await tester.tap(find.byKey(const Key('admin-hide')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('hide:7:true'));

    await tester.ensureVisible(find.byKey(const Key('admin-resolve-suspended')));
    await tester.tap(find.byKey(const Key('admin-resolve-suspended')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(repo.calls.where((c) => c.contains('suspended')), isEmpty);

    repo.failWith = '운영자만 할 수 있어요.';
    await tester.tap(find.byKey(const Key('admin-resolve-dismissed')));
    await tester.pump();
    expect(find.text('운영자만 할 수 있어요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
