/**
 * geohash — 위치를 격자 문자열로 줄인다. 6자리 ≈ 1.2km × 0.6km(서울 위도).
 * 동선은 정확한 좌표 대신 이 격자만 저장한다(설계 W6 · 위치 정밀도 C12).
 * 앱(lib/core/utils/geohash.dart)과 같은 계산이다.
 */
const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';

export function encode(lat: number, lng: number, precision = 6): string {
  let latLo = -90, latHi = 90, lngLo = -180, lngHi = 180;
  let hash = '', bit = 0, ch = 0, even = true;
  while (hash.length < precision) {
    if (even) {
      const mid = (lngLo + lngHi) / 2;
      if (lng >= mid) { ch = (ch << 1) | 1; lngLo = mid; } else { ch <<= 1; lngHi = mid; }
    } else {
      const mid = (latLo + latHi) / 2;
      if (lat >= mid) { ch = (ch << 1) | 1; latLo = mid; } else { ch <<= 1; latHi = mid; }
    }
    even = !even;
    if (++bit === 5) { hash += BASE32[ch]; bit = 0; ch = 0; }
  }
  return hash;
}

/** 격자 가운데 좌표와 격자 크기(도) */
export function decode(hash: string): { lat: number; lng: number; dLat: number; dLng: number } {
  let latLo = -90, latHi = 90, lngLo = -180, lngHi = 180, even = true;
  for (const c of hash) {
    const v = BASE32.indexOf(c);
    if (v < 0) throw new Error(`geohash 글자가 아니에요: ${c}`);
    for (let b = 4; b >= 0; b--) {
      const on = (v >> b) & 1;
      if (even) { const m = (lngLo + lngHi) / 2; if (on) lngLo = m; else lngHi = m; }
      else { const m = (latLo + latHi) / 2; if (on) latLo = m; else latHi = m; }
      even = !even;
    }
  }
  return { lat: (latLo + latHi) / 2, lng: (lngLo + lngHi) / 2, dLat: latHi - latLo, dLng: lngHi - lngLo };
}

export const isGeohash = (s: unknown, len = 6): s is string => typeof s === 'string' && s.length === len && [...s].every((c) => BASE32.includes(c));

const KM_PER_LAT = 111.32;
const kmPerLng = (lat: number) => 111.32 * Math.cos((lat * Math.PI) / 180);

/** 두 점 사이 거리(km, 짧은 거리용 근사) */
export function distanceKm(aLat: number, aLng: number, bLat: number, bLng: number): number {
  const x = (bLng - aLng) * kmPerLng((aLat + bLat) / 2);
  const y = (bLat - aLat) * KM_PER_LAT;
  return Math.hypot(x, y);
}

/**
 * 출발 → 도착 선분을 따라가며, 선분에서 [radiusKm] 안에 드는 6자리 격자를 모은다(W7 매칭용).
 * 길이가 [maxCells]를 넘으면 반경을 줄여 다시 센다 — 문서가 커지고 매칭이 넓어지는 걸 막는다.
 */
export function corridorCells(from: string, to: string, radiusKm: number, maxCells = 300): string[] {
  const a = decode(from), b = decode(to);
  let r = Math.max(0.1, radiusKm);
  for (;;) {
    const out = new Set<string>();
    const len = distanceKm(a.lat, a.lng, b.lat, b.lng);
    const steps = Math.max(1, Math.ceil(len / 0.3));
    const dLatR = r / KM_PER_LAT;
    for (let i = 0; i <= steps; i++) {
      const t = i / steps;
      const lat = a.lat + (b.lat - a.lat) * t;
      const lng = a.lng + (b.lng - a.lng) * t;
      const dLngR = r / kmPerLng(lat);
      // 반경 안을 격자 크기보다 촘촘하게 훑는다(6자리 격자 ≈ 0.6km × 1.1km)
      const n = Math.ceil(r / 0.25);
      for (let y = -n; y <= n; y++) {
        for (let x = -n; x <= n; x++) {
          const py = (y / n) * dLatR, px = (x / n) * dLngR;
          if ((py * KM_PER_LAT) ** 2 + (px * kmPerLng(lat)) ** 2 > r * r) continue;
          out.add(encode(lat + py, lng + px, 6));
        }
      }
      out.add(encode(lat, lng, 6));
    }
    if (out.size <= maxCells || r <= 0.1) return [...out].slice(0, maxCells);
    r = r * 0.7;
  }
}
