import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/screen_frame.dart';
import '../models/job_posting.dart';
import '../repositories/job_posting_repository.dart';

/// 단기알바 모집 등록. 시안(`gyumsa-refined`)의 `GyJobForm`.
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
  static const _steps = ['회사와 업무', '근무 조건', '급여와 모집'];

  int step = 0;
  String? error;

  final title = TextEditingController();
  final company = TextEditingController();
  final companyAddress = TextEditingController();
  final businessNo = TextEditingController();
  final desc = TextEditingController();
  final requirements = TextEditingController();

  String workType = JobPosting.workTypes.first;
  final location = TextEditingController();
  DateTime? start;
  DateTime? end;
  final schedule = TextEditingController();
  final breakMin = TextEditingController(text: '0');
  final headcount = TextEditingController(text: '1');
  final benefits = TextEditingController();

  String payType = JobPosting.payTypes.first;
  final pay = TextEditingController();
  DateTime? payDate;
  final payNote = TextEditingController();
  DateTime? deadline;
  final contact = TextEditingController();
  String contactMethod = JobPosting.contactMethods.first;
  final email = TextEditingController();
  bool confirmed = false;

  final _scroll = ScrollController();

  @override
  void dispose() {
    for (final c in [title, company, companyAddress, businessNo, desc, requirements, location, schedule, breakMin, headcount, benefits, pay, payNote, contact, email]) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  int get _breakMin => int.tryParse(breakMin.text.trim()) ?? -1;
  int get _headcount => int.tryParse(headcount.text.trim()) ?? 0;
  int get _pay => int.tryParse(pay.text.trim().replaceAll(',', '')) ?? 0;

  /// 휴게시간을 뺀 실제 근무 시간(분). 아직 못 정하면 null.
  int? get _netMinutes {
    final s = start, e = end;
    if (s == null || e == null || _breakMin < 0) return null;
    return e.difference(s).inMinutes - _breakMin;
  }

  bool get _emailOk =>
      contactMethod != '이메일 지원' || RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.text.trim());

  bool _validAt(int s) {
    switch (s) {
      case 0:
        return title.text.trim().length >= 2 &&
            company.text.trim().isNotEmpty &&
            companyAddress.text.trim().isNotEmpty &&
            desc.text.trim().length >= 10;
      case 1:
        final net = _netMinutes;
        return location.text.trim().isNotEmpty &&
            start != null &&
            start!.isAfter(DateTime.now()) &&
            net != null &&
            net > 0 &&
            _headcount > 0;
      default:
        final d = deadline, p = payDate, s = start, e = end;
        return _pay > 0 &&
            p != null && e != null && !p.isBefore(DateTime(e.year, e.month, e.day)) &&
            d != null && s != null && d.isAfter(DateTime.now()) && !d.isAfter(s) &&
            contact.text.trim().isNotEmpty &&
            confirmed &&
            _emailOk;
    }
  }

  static const _errors = [
    '모집 제목·회사·주소와 업무 내용(10자 이상)을 입력해 주세요.',
    '미래의 근무 일정, 장소, 인원과 휴게시간을 확인해 주세요.',
    '급여·지급일·마감·담당자·지원 이메일 및 확인 체크를 확인해 주세요.',
  ];

  void _next() {
    if (!_validAt(step)) {
      setState(() => error = _errors[step]);
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
    final job = JobPosting(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      title: title.text.trim(),
      company: company.text.trim(),
      companyAddress: companyAddress.text.trim(),
      businessNo: businessNo.text.trim(),
      desc: desc.text.trim(),
      requirements: requirements.text.trim(),
      workType: workType,
      location: location.text.trim(),
      start: start!,
      end: end!,
      schedule: schedule.text.trim(),
      breakMin: _breakMin,
      headcount: _headcount,
      benefits: benefits.text.trim(),
      payType: payType,
      pay: _pay,
      payDate: payDate!,
      payNote: payNote.text.trim(),
      deadline: deadline!,
      contact: contact.text.trim(),
      contactMethod: contactMethod,
      email: email.text.trim(),
      region: widget.scope,
    );
    JobPostingRepository.add(job);
    widget.onSubmit(job);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: '단기알바 모집',
      onBack: () => step > 0 ? setState(() => step--) : Navigator.pop(context),
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
        children: [
          _stepBar(),
          Text(['어떤 일을 함께하나요?', '언제, 어디서 일하나요?', '급여와 지원 방법을 알려주세요'][step],
              style: AppType.section.copyWith(fontSize: 22, height: 1.4)),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 8),
            child: Text('필수 항목 · 작성 내용은 등록할 때 이 기기에 저장돼요.', style: AppType.caption.copyWith(height: 1.7)),
          ),
          ...switch (step) { 0 => _step0(), 1 => _step1(), _ => _step2() },
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(error!, style: AppType.meta.copyWith(fontSize: 12, color: AppColors.red)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 23, 0, 12),
            child: Text('시안에서는 이 기기에만 등록돼요. 실제 지원 접수는 연동 전입니다.',
                style: AppType.caption.copyWith(fontSize: 11, height: 1.7)),
          ),
          ElevatedButton(onPressed: _next, child: Text(step == 2 ? '단기알바 등록하기' : '다음')),
        ],
      ),
    );
  }

  Widget _stepBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(children: [
        for (int i = 0; i < _steps.length; i++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == _steps.length - 1 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: i == step ? AppColors.green : AppColors.line, width: 2)),
              ),
              child: Text(_steps[i],
                  style: AppType.caption.copyWith(
                    fontSize: 11,
                    fontWeight: i == step ? AppType.w700 : AppType.w400,
                    color: i == step ? AppColors.green : AppColors.faint,
                  )),
            ),
          ),
      ]),
    );
  }

  List<Widget> _step0() => [
        AppField(label: '모집 제목', required: true, controller: title, placeholder: '예: 주말 공연 안내 스태프 모집'),
        AppField(label: '회사·상호명', required: true, controller: company, placeholder: '실제 고용하는 회사 또는 사업장 이름'),
        AppField(label: '회사 주소', required: true, controller: companyAddress, placeholder: '도로명 주소와 상세 주소'),
        AppField(
          label: '사업자등록번호 (선택)',
          controller: businessNo,
          placeholder: '000-00-00000',
          hint: '입력만으로 사업자 인증이 완료되지는 않아요.',
        ),
        AppField(
          label: '하는 일',
          required: true,
          controller: desc,
          maxLines: 4,
          placeholder: '담당 업무, 업무 범위, 현장 환경을 10자 이상 작성해 주세요.',
        ),
        AppField(
          label: '지원 자격·우대사항 (선택)',
          controller: requirements,
          maxLines: 2,
          placeholder: '필요한 경험·기술, 준비물·복장 등',
        ),
      ];

  List<Widget> _step1() {
    final net = _netMinutes;
    return [
      AppSelectField(
        label: '근무 방식',
        value: workType,
        options: JobPosting.workTypes,
        onChanged: (v) => setState(() => workType = v),
      ),
      AppField(
        label: '실제 근무 장소',
        required: true,
        controller: location,
        placeholder: '회사와 다르면 별도 입력 · 재택이면 \'재택\' 입력',
      ),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: AppDateField(
            label: '근무 시작',
            required: true,
            value: start,
            onChanged: (v) => setState(() => start = v),
            first: DateTime.now(),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: AppDateField(
            label: '근무 종료',
            required: true,
            value: end,
            onChanged: (v) => setState(() => end = v),
            first: start ?? DateTime.now(),
          ),
        ),
      ]),
      AppField(
        label: '반복 일정 (선택)',
        controller: schedule,
        placeholder: '예: 10월 매주 토요일 · 날짜가 여러 개면 적어주세요',
      ),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: AppField(
            label: '휴게시간 (분)',
            required: true,
            controller: breakMin,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: AppField(
            label: '모집 인원 (명)',
            required: true,
            controller: headcount,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ]),
      if (net != null && net > 0)
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)),
          child: Text('입력한 첫 근무 기준 · 휴게 제외 ${net ~/ 60}시간 ${net % 60}분',
              style: AppType.meta.copyWith(fontSize: 12, height: 1.8, color: AppColors.goalMintInk)),
        ),
      AppField(
        label: '식사·교통비·기타 지원 (선택)',
        controller: benefits,
        maxLines: 2,
        placeholder: '예: 식사 제공, 교통비 별도 지급',
      ),
    ];
  }

  List<Widget> _step2() => [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: AppSelectField(
              label: '급여 기준',
              required: true,
              value: payType,
              options: JobPosting.payTypes,
              onChanged: (v) => setState(() => payType = v),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: AppField(
              label: '급여 (원, 세전)',
              required: true,
              controller: pay,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ]),
        AppDateField(
          label: '급여 지급 예정일',
          required: true,
          withTime: false,
          value: payDate,
          onChanged: (v) => setState(() => payDate = v),
          first: end ?? DateTime.now(),
        ),
        AppField(
          label: '급여 상세 조건 (선택)',
          controller: payNote,
          maxLines: 2,
          placeholder: '지급 방식, 수당·공제, 휴게시간 급여 포함 여부 등',
        ),
        AppDateField(
          label: '지원 마감',
          required: true,
          value: deadline,
          onChanged: (v) => setState(() => deadline = v),
          first: DateTime.now(),
          last: start,
          hint: '현재 이후, 근무 시작 이전으로 설정해 주세요.',
        ),
        AppField(label: '채용 담당자', required: true, controller: contact, placeholder: '담당자 이름 또는 부서'),
        AppSelectField(
          label: '지원 방법',
          value: contactMethod,
          options: JobPosting.contactMethods,
          onChanged: (v) => setState(() => contactMethod = v),
        ),
        if (contactMethod == '이메일 지원')
          AppField(
            label: '지원 이메일',
            required: true,
            controller: email,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
          ),
        AppCheckRow(
          value: confirmed,
          onChanged: (v) => setState(() => confirmed = v),
          label: '업무·근무 조건·급여 내용을 확인했습니다.',
        ),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title.text.trim().isEmpty ? '모집 제목' : title.text.trim(),
                style: AppType.body.copyWith(fontSize: 13, fontWeight: AppType.w600)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text('${company.text.trim()} · $_headcount명 모집', style: AppType.caption.copyWith(fontSize: 12)),
            ),
            Text('$payType ${nf(_pay)}원 · 세전',
                style: AppType.body.copyWith(fontSize: 13, fontWeight: AppType.w700, color: AppColors.green)),
          ]),
        ),
      ];
}
