/// 이용자가 직접 올린 단기알바 모집글. 시안(`gyumsa-refined`)의 `GyJobForm`.
///
/// 앞서 있던 [DayJob]은 제휴사에서 받아 온 **예시 공고**다. 이건 앱 안에서
/// 사람이 직접 쓴 모집글이라, 일상 부탁과 달리 근로 조건을 빠짐없이 적게 한다.
/// (회사·주소·업무·근무시간·휴게시간·급여 기준·지급일·담당자)
class JobPosting {
  final String id;
  final String title;
  final String company;
  final String companyAddress;
  final String businessNo;
  final String desc;
  final String requirements;

  /// 현장 근무 | 재택 근무 | 협의
  final String workType;
  final String location;
  final DateTime start;
  final DateTime end;
  final String schedule;
  final int breakMin;
  final int headcount;
  final String benefits;

  /// 시급 | 일급 | 총액
  final String payType;
  final int pay;
  final DateTime payDate;
  final String payNote;
  final DateTime deadline;
  final String contact;

  /// 앱 내 지원 | 이메일 지원
  final String contactMethod;
  final String email;
  final String region;

  const JobPosting({
    required this.id,
    required this.title,
    required this.company,
    required this.companyAddress,
    required this.businessNo,
    required this.desc,
    required this.requirements,
    required this.workType,
    required this.location,
    required this.start,
    required this.end,
    required this.schedule,
    required this.breakMin,
    required this.headcount,
    required this.benefits,
    required this.payType,
    required this.pay,
    required this.payDate,
    required this.payNote,
    required this.deadline,
    required this.contact,
    required this.contactMethod,
    required this.email,
    required this.region,
  });

  static const payTypes = ['시급', '일급', '총액'];
  static const workTypes = ['현장 근무', '재택 근무', '협의'];
  static const contactMethods = ['앱 내 지원', '이메일 지원'];

  /// 휴게시간을 뺀 실제 근무 시간(분)
  int get workMinutes => end.difference(start).inMinutes - breakMin;

  bool get closed => deadline.isBefore(DateTime.now());

  /// 지원 방법 한 줄. 이메일 지원이면 주소를 그대로 보여준다.
  String get contactLine => contactMethod == '이메일 지원' ? email : contactMethod;

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'company': company, 'companyAddress': companyAddress,
        'businessNo': businessNo, 'desc': desc, 'requirements': requirements,
        'workType': workType, 'location': location,
        'start': start.toIso8601String(), 'end': end.toIso8601String(),
        'schedule': schedule, 'breakMin': breakMin, 'headcount': headcount, 'benefits': benefits,
        'payType': payType, 'pay': pay, 'payDate': payDate.toIso8601String(), 'payNote': payNote,
        'deadline': deadline.toIso8601String(), 'contact': contact,
        'contactMethod': contactMethod, 'email': email, 'region': region,
      };

  static JobPosting? fromJson(Map<String, dynamic> j) {
    DateTime? d(String k) => DateTime.tryParse('${j[k]}');
    final start = d('start'), end = d('end'), payDate = d('payDate'), deadline = d('deadline');
    if (start == null || end == null || payDate == null || deadline == null) return null;
    return JobPosting(
      id: '${j['id'] ?? ''}',
      title: '${j['title'] ?? ''}',
      company: '${j['company'] ?? ''}',
      companyAddress: '${j['companyAddress'] ?? ''}',
      businessNo: '${j['businessNo'] ?? ''}',
      desc: '${j['desc'] ?? ''}',
      requirements: '${j['requirements'] ?? ''}',
      workType: '${j['workType'] ?? '현장 근무'}',
      location: '${j['location'] ?? ''}',
      start: start, end: end,
      schedule: '${j['schedule'] ?? ''}',
      breakMin: j['breakMin'] is int ? j['breakMin'] as int : 0,
      headcount: j['headcount'] is int ? j['headcount'] as int : 1,
      benefits: '${j['benefits'] ?? ''}',
      payType: '${j['payType'] ?? '시급'}',
      pay: j['pay'] is int ? j['pay'] as int : 0,
      payDate: payDate,
      payNote: '${j['payNote'] ?? ''}',
      deadline: deadline,
      contact: '${j['contact'] ?? ''}',
      contactMethod: '${j['contactMethod'] ?? '앱 내 지원'}',
      email: '${j['email'] ?? ''}',
      region: '${j['region'] ?? ''}',
    );
  }
}
