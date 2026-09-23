import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gyeomsa/features/dayjob/models/job_posting.dart';
import 'package:gyeomsa/features/dayjob/screens/job_post_screen.dart';
import 'package:gyeomsa/features/errand/screens/create_choice_screen.dart';

/// 단기알바는 일상 부탁과 달리 **채용**이라, 근로 조건을 빠뜨린 채 다음 단계로
/// 넘어가지 못해야 한다. 시안(`gyumsa-refined`)의 세 단계 검증을 그대로 본다.
void main() {
  testWidgets('부탁하기 — 세 갈래를 먼저 고른다', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final picked = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: CreateChoiceScreen(
        onLocal: () => picked.add('ask'),
        onOverseas: () => picked.add('sea'),
        onJob: () => picked.add('job'),
      ),
    ));
    await tester.pump();

    expect(find.text('어떤 일을 맡기고 싶으세요?'), findsOneWidget);
    for (final s in ['일상 부탁', '해외 사다주기', '단기알바 모집']) {
      expect(find.text(s), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('단기알바 모집 — 회사·업무를 비우면 다음으로 못 간다', (tester) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: JobPostScreen(scope: '서울 서초구', onSubmit: (_) {}),
    ));
    await tester.pump();

    expect(find.text('어떤 일을 함께하나요?'), findsOneWidget);
    await tester.dragUntilVisible(find.text('다음'), find.byType(ListView), const Offset(0, -300));
    await tester.tap(find.text('다음'));
    await tester.pump();

    expect(find.text('모집 제목·회사·주소와 업무 내용(10자 이상)을 입력해 주세요.'), findsOneWidget);
    // 1단계를 통과하지 못했으므로 2단계 제목은 아직 없다.
    expect(find.text('언제, 어디서 일하나요?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('모집글 — 휴게시간을 뺀 근무 시간과 마감 여부', () {
    final job = JobPosting(
      id: '1', title: '주말 공연 안내 스태프', company: '○○기획', companyAddress: '서울 서초구 1',
      businessNo: '', desc: '관람객 동선을 안내해요.', requirements: '',
      workType: '현장 근무', location: '양재시민의숲',
      start: DateTime(2026, 10, 3, 10), end: DateTime(2026, 10, 3, 18),
      schedule: '', breakMin: 60, headcount: 3, benefits: '',
      payType: '일급', pay: 110000, payDate: DateTime(2026, 10, 5), payNote: '',
      deadline: DateTime(2026, 10, 1, 18), contact: '김담당',
      contactMethod: '앱 내 지원', email: '', region: '서울 서초구',
    );

    expect(job.workMinutes, 8 * 60 - 60);
    expect(job.contactLine, '앱 내 지원');
    // 저장·복원을 거쳐도 같은 값이어야 한다.
    final back = JobPosting.fromJson(job.toJson())!;
    expect(back.title, job.title);
    expect(back.start, job.start);
    expect(back.pay, job.pay);
    expect(back.breakMin, job.breakMin);
  });
}
