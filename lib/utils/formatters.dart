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

String fmtDist(double d) => d == d.roundToDouble() ? d.toInt().toString() : d.toString();

String km(double d) {
  if (d == 0) return '무료';
  if (d < 1) return '${(d * 1000).round()}m';
  return '${fmtDist(d)}km';
}
