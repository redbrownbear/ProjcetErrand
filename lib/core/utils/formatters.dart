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
  return it.distM >= 1000 ? '${(it.distM / 1000).round()}km' : '${it.distM.round()}m';
}

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
