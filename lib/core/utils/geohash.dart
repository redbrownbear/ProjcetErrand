/// geohash — 위치를 격자 문자열로 줄인다. 6자리 ≈ 1.2km × 0.6km(서울 위도).
/// 동선은 정확한 좌표 대신 이 격자만 저장한다(설계 W6). 서버 functions/src/route/geohash.ts와 같은 계산이다.
class Geohash {
  Geohash._();

  static const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  static String encode(double lat, double lng, [int precision = 6]) {
    var latLo = -90.0, latHi = 90.0, lngLo = -180.0, lngHi = 180.0;
    final out = StringBuffer();
    var bit = 0, ch = 0, even = true;
    while (out.length < precision) {
      if (even) {
        final mid = (lngLo + lngHi) / 2;
        if (lng >= mid) {
          ch = (ch << 1) | 1;
          lngLo = mid;
        } else {
          ch <<= 1;
          lngHi = mid;
        }
      } else {
        final mid = (latLo + latHi) / 2;
        if (lat >= mid) {
          ch = (ch << 1) | 1;
          latLo = mid;
        } else {
          ch <<= 1;
          latHi = mid;
        }
      }
      even = !even;
      if (++bit == 5) {
        out.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return out.toString();
  }

  /// 격자 가운데 좌표
  static (double lat, double lng) center(String hash) {
    var latLo = -90.0, latHi = 90.0, lngLo = -180.0, lngHi = 180.0;
    var even = true;
    for (final c in hash.split('')) {
      final v = _base32.indexOf(c);
      if (v < 0) throw FormatException('geohash 글자가 아니에요: $c');
      for (var b = 4; b >= 0; b--) {
        final on = (v >> b) & 1 == 1;
        if (even) {
          final m = (lngLo + lngHi) / 2;
          if (on) {
            lngLo = m;
          } else {
            lngHi = m;
          }
        } else {
          final m = (latLo + latHi) / 2;
          if (on) {
            latLo = m;
          } else {
            latHi = m;
          }
        }
        even = !even;
      }
    }
    return ((latLo + latHi) / 2, (lngLo + lngHi) / 2);
  }

  static bool isValid(String s, [int len = 6]) => s.length == len && s.split('').every(_base32.contains);
}
