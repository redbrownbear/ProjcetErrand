import 'package:flutter/material.dart';

import '../models/job_posting.dart';

/// 단기알바 모집 폼의 값과 검증. 화면은 [JobPostScreen]이 그린다.
///
/// 부탁 쓰기의 [RequestForm]처럼 값·검증을 화면에서 떼어 두면, 단계별 조건을 위젯 없이 확인할 수 있다.
class JobPostForm {
  static const steps = ['회사와 업무', '근무 조건', '급여와 모집'];

  static const errors = [
    '모집 제목·회사·주소와 업무 내용(10자 이상)을 입력해 주세요.',
    '미래의 근무 일정, 장소, 인원과 휴게시간을 확인해 주세요.',
    '급여·지급일·마감·담당자·지원 이메일 및 확인 체크를 확인해 주세요.',
  ];

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

  void dispose() {
    for (final c in [
      title,
      company,
      companyAddress,
      businessNo,
      desc,
      requirements,
      location,
      schedule,
      breakMin,
      headcount,
      benefits,
      pay,
      payNote,
      contact,
      email,
    ]) {
      c.dispose();
    }
  }

  // ── 값 ──────────────────────────────────────────────────────────────────

  int get breakMinutes => int.tryParse(breakMin.text.trim()) ?? -1;
  int get headcountValue => int.tryParse(headcount.text.trim()) ?? 0;
  int get payValue => int.tryParse(pay.text.trim().replaceAll(',', '')) ?? 0;

  /// 휴게시간을 뺀 실제 근무 시간(분). 아직 못 정하면 null.
  int? get netMinutes {
    final s = start, e = end;
    if (s == null || e == null || breakMinutes < 0) return null;
    return e.difference(s).inMinutes - breakMinutes;
  }

  bool get emailOk => contactMethod != '이메일 지원' || RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.text.trim());

  // ── 검증 ────────────────────────────────────────────────────────────────

  /// [step]단계를 넘어갈 수 있는지. [now]는 테스트에서 바꿔 끼운다.
  bool validAt(int step, [DateTime? now]) {
    final at = now ?? DateTime.now();
    switch (step) {
      case 0:
        return title.text.trim().length >= 2 &&
            company.text.trim().isNotEmpty &&
            companyAddress.text.trim().isNotEmpty &&
            desc.text.trim().length >= 10;
      case 1:
        final net = netMinutes;
        return location.text.trim().isNotEmpty &&
            start != null &&
            start!.isAfter(at) &&
            net != null &&
            net > 0 &&
            headcountValue > 0;
      default:
        final d = deadline, p = payDate, s = start, e = end;
        return payValue > 0 &&
            p != null &&
            e != null &&
            !p.isBefore(DateTime(e.year, e.month, e.day)) &&
            d != null &&
            s != null &&
            d.isAfter(at) &&
            !d.isAfter(s) &&
            contact.text.trim().isNotEmpty &&
            confirmed &&
            emailOk;
    }
  }

  /// 등록할 값. 마지막 단계까지 [validAt]을 통과했을 때만 부른다.
  JobPosting toPosting({required String region}) => JobPosting(
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
    breakMin: breakMinutes,
    headcount: headcountValue,
    benefits: benefits.text.trim(),
    payType: payType,
    pay: payValue,
    payDate: payDate!,
    payNote: payNote.text.trim(),
    deadline: deadline!,
    contact: contact.text.trim(),
    contactMethod: contactMethod,
    email: email.text.trim(),
    region: region,
  );
}
