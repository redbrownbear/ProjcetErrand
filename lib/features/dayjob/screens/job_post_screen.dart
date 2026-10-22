import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/screen_frame.dart';
import '../models/job_posting.dart';
import '../repositories/job_posting_repository.dart';
import 'job_post_form.dart';

/// 단기알바 모집 등록.
///
/// 회사와 업무 → 근무 조건 → 급여와 모집, 세 단계로 나눈다. 일상 부탁과 달리
/// **근로 조건**이라 회사·주소·근무시간·휴게시간·급여 기준·지급일·담당자를
/// 빠뜨리지 못하게 단계마다 막는다.
class JobPostScreen extends StatefulWidget {
  final String scope;
  final void Function(JobPosting) onSubmit;
  const JobPostScreen({super.key, required this.scope, required this.onSubmit});

  @override
  State<JobPostScreen> createState() => _JobPostScreenState();
}

class _JobPostScreenState extends State<JobPostScreen> {
  final f = JobPostForm();
  int step = 0;
  String? error;

  final _scroll = ScrollController();

  @override
  void dispose() {
    f.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _next() {
    if (!f.validAt(step)) {
      setState(() => error = JobPostForm.errors[step]);
      return;
    }
    setState(() => error = null);
    if (step < 2) {
      setState(() => step++);
      _scroll.jumpTo(0);
      return;
    }
    _submit();
  }

  void _submit() {
    final job = f.toPosting(region: widget.scope);
    JobPostingRepository.add(job);
    widget.onSubmit(job);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // 시스템 뒤로가기도 화면 왼쪽 위 버튼처럼 한 단계씩 돌아간다 — 바로 닫히면 쓰던 내용이 날아간다.
    return PopScope(
      canPop: step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => step--);
      },
      child: _frame(),
    );
  }

  Widget _frame() {
    return ScreenFrame(
      title: '단기알바 모집',
      onBack: () => step > 0 ? setState(() => step--) : Navigator.pop(context),
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
        children: [
          _stepBar(),
          Text(
            ['어떤 일을 함께하나요?', '언제, 어디서 일하나요?', '급여와 지원 방법을 알려주세요'][step],
            style: AppType.section.copyWith(fontSize: 22, height: 1.4),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 8),
            child: Text('필수 항목 · 작성 내용은 등록할 때 이 기기에 저장돼요.', style: AppType.caption.copyWith(height: 1.7)),
          ),
          ...switch (step) {
            0 => _step0(),
            1 => _step1(),
            _ => _step2(),
          },
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(error!, style: AppType.meta.copyWith(fontSize: 12, color: AppColors.red)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 23, 0, 12),
            child: Text('시안에서는 이 기기에만 등록돼요. 실제 지원 접수는 연동 전입니다.', style: AppType.caption.copyWith(fontSize: 11, height: 1.7)),
          ),
          ElevatedButton(onPressed: _next, child: Text(step == 2 ? '단기알바 등록하기' : '다음')),
        ],
      ),
    );
  }

  Widget _stepBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          for (int i = 0; i < JobPostForm.steps.length; i++)
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == JobPostForm.steps.length - 1 ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: i == step ? AppColors.green : AppColors.line, width: 2)),
                ),
                child: Text(
                  JobPostForm.steps[i],
                  style: AppType.caption.copyWith(
                    fontSize: 11,
                    fontWeight: i == step ? AppType.w700 : AppType.w400,
                    color: i == step ? AppColors.green : AppColors.faint,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _step0() => [
    AppField(label: '모집 제목', required: true, controller: f.title, placeholder: '예: 주말 공연 안내 스태프 모집'),
    AppField(label: '회사·상호명', required: true, controller: f.company, placeholder: '실제 고용하는 회사 또는 사업장 이름'),
    AppField(label: '회사 주소', required: true, controller: f.companyAddress, placeholder: '도로명 주소와 상세 주소'),
    AppField(label: '사업자등록번호 (선택)', controller: f.businessNo, placeholder: '000-00-00000', hint: '입력만으로 사업자 인증이 완료되지는 않아요.'),
    AppField(label: '하는 일', required: true, controller: f.desc, maxLines: 4, placeholder: '담당 업무, 업무 범위, 현장 환경을 10자 이상 작성해 주세요.'),
    AppField(label: '지원 자격·우대사항 (선택)', controller: f.requirements, maxLines: 2, placeholder: '필요한 경험·기술, 준비물·복장 등'),
  ];

  List<Widget> _step1() {
    final net = f.netMinutes;
    return [
      AppSelectField(
        label: '근무 방식',
        value: f.workType,
        options: JobPosting.workTypes,
        onChanged: (v) => setState(() => f.workType = v),
      ),
      AppField(label: '실제 근무 장소', required: true, controller: f.location, placeholder: '회사와 다르면 별도 입력 · 재택이면 \'재택\' 입력'),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppDateField(
              label: '근무 시작',
              required: true,
              value: f.start,
              onChanged: (v) => setState(() => f.start = v),
              first: DateTime.now(),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: AppDateField(
              label: '근무 종료',
              required: true,
              value: f.end,
              onChanged: (v) => setState(() => f.end = v),
              first: f.start ?? DateTime.now(),
            ),
          ),
        ],
      ),
      AppField(label: '반복 일정 (선택)', controller: f.schedule, placeholder: '예: 10월 매주 토요일 · 날짜가 여러 개면 적어주세요'),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppField(
              label: '휴게시간 (분)',
              required: true,
              controller: f.breakMin,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: AppField(
              label: '모집 인원 (명)',
              required: true,
              controller: f.headcount,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
      if (net != null && net > 0)
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)),
          child: Text(
            '입력한 첫 근무 기준 · 휴게 제외 ${net ~/ 60}시간 ${net % 60}분',
            style: AppType.meta.copyWith(fontSize: 12, height: 1.8, color: AppColors.goalMintInk),
          ),
        ),
      AppField(label: '식사·교통비·기타 지원 (선택)', controller: f.benefits, maxLines: 2, placeholder: '예: 식사 제공, 교통비 별도 지급'),
    ];
  }

  List<Widget> _step2() => [
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppSelectField(
            label: '급여 기준',
            required: true,
            value: f.payType,
            options: JobPosting.payTypes,
            onChanged: (v) => setState(() => f.payType = v),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: AppField(
            label: '급여 (원, 세전)',
            required: true,
            controller: f.pay,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    ),
    AppDateField(
      label: '급여 지급 예정일',
      required: true,
      withTime: false,
      value: f.payDate,
      onChanged: (v) => setState(() => f.payDate = v),
      first: f.end ?? DateTime.now(),
    ),
    AppField(label: '급여 상세 조건 (선택)', controller: f.payNote, maxLines: 2, placeholder: '지급 방식, 수당·공제, 휴게시간 급여 포함 여부 등'),
    AppDateField(
      label: '지원 마감',
      required: true,
      value: f.deadline,
      onChanged: (v) => setState(() => f.deadline = v),
      first: DateTime.now(),
      last: f.start,
      hint: '현재 이후, 근무 시작 이전으로 설정해 주세요.',
    ),
    AppField(label: '채용 담당자', required: true, controller: f.contact, placeholder: '담당자 이름 또는 부서'),
    AppSelectField(
      label: '지원 방법',
      value: f.contactMethod,
      options: JobPosting.contactMethods,
      onChanged: (v) => setState(() => f.contactMethod = v),
    ),
    if (f.contactMethod == '이메일 지원')
      AppField(
        label: '지원 이메일',
        required: true,
        controller: f.email,
        keyboardType: TextInputType.emailAddress,
        onChanged: (_) => setState(() {}),
      ),
    AppCheckRow(value: f.confirmed, onChanged: (v) => setState(() => f.confirmed = v), label: '업무·근무 조건·급여 내용을 확인했습니다.'),
    Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            f.title.text.trim().isEmpty ? '모집 제목' : f.title.text.trim(),
            style: AppType.body.copyWith(fontSize: 13, fontWeight: AppType.w600),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text('${f.company.text.trim()} · ${f.headcountValue}명 모집', style: AppType.caption.copyWith(fontSize: 12)),
          ),
          Text(
            '${f.payType} ${nf(f.payValue)}원 · 세전',
            style: AppType.body.copyWith(fontSize: 13, fontWeight: AppType.w700, color: AppColors.green),
          ),
        ],
      ),
    ),
  ];
}
