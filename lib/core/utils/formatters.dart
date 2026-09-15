import 'dart:math';

import '../../features/errand/models/task_item.dart';

String _comma(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return (n < 0 ? '-' : '') + buf.toString();
}

String won(int n) => '${_comma(n)}원';

String nf(int n) => _comma(n);

String kwon(int n) => '${(n / 1000).round()}천원';

String distLabel(TaskItem it) {
  if (it.mode == 'sea') return it.country ?? '해외';
  final d = it.distM;
  if (d == null) return '거리 미확인';
  return d >= 1000 ? '${(d / 1000).round()}km' : '${d.round()}m';
}

/// 마감 안내 문구. 마감 정보가 없는 부탁은 임의로 만들지 않고 협의로 표시한다.
String deadlineLabel(TaskItem it) {
  final d = it.deadline;
  if (d == null) return '마감 시각 협의';
  return '${dateTimeLabel(d)}까지';
}

String dateTimeLabel(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.month}월 ${d.day}일 ${two(d.hour)}:${two(d.minute)}';
}

const paymentLabels = {
  'none': '구매비 없음',
  'prepaid': '요청자가 매장에 결제 완료',
  'reimburse': '도우미 선결제 후 영수증 정산',
};

String metaOf(TaskItem it) {
  if (it.mode == 'sea') {
    return [it.country, it.place].where((s) => s != null && s.isNotEmpty).join(' · ');
  }
  final parts = [
    distLabel(it),
    it.mins > 0 ? '약 ${it.mins}분' : '',
    it.region ?? '',
  ].where((s) => s.isNotEmpty);
  return parts.join(' · ');
}

String shortRegion(String r) {
  if (r == '전국') return '전국';
  return r.replaceFirst(RegExp(r'^(서울|부산|대전|인천|대구|광주|울산) '), '');
}

final _rand = Random();
String genCode() {
  final buf = StringBuffer('GC');
  for (var i = 0; i < 12; i++) {
    buf.write(_rand.nextInt(10));
  }
  return buf.toString();
}
