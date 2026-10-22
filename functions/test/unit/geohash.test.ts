import assert from 'node:assert/strict';
import { describe, test } from 'node:test';

import { corridorCells, decode, distanceKm, encode, isGeohash } from '../../src/route/geohash';

describe('geohash', () => {
  test('알려진 값과 같고, 가운데 좌표로 되돌아온다', () => {
    assert.equal(encode(57.64911, 10.40744, 11), 'u4pruydqqvj'); // 위키백과 예시
    const g = encode(37.4979, 127.0276, 6); // 강남역
    assert.equal(g.length, 6);
    assert.ok(isGeohash(g));
    const c = decode(g);
    assert.ok(distanceKm(c.lat, c.lng, 37.4979, 127.0276) < 1);
  });

  test('동선 격자: 출발 · 도착을 포함하고, 반경이 크면 넓어지며, 상한을 넘지 않는다', () => {
    const from = encode(37.4814, 126.9976, 6); // 방배역
    const to = encode(37.4979, 127.0276, 6); // 강남역
    const narrow = corridorCells(from, to, 0.1);
    const wide = corridorCells(from, to, 2);
    assert.ok(narrow.includes(from) && narrow.includes(to));
    assert.ok(wide.length > narrow.length);
    assert.ok(corridorCells(encode(37.56, 126.97, 6), encode(35.1, 129.04, 6), 8).length <= 300); // 서울 → 부산
    assert.ok(!narrow.includes(encode(37.5665, 126.978, 6))); // 시청은 동선 밖
  });
});
