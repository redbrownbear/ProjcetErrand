import assert from 'node:assert/strict';
import { test } from 'node:test';

import { docId, fields, ownPhotoPath } from '../../src/shared/input';
import { kstDay } from '../../src/shared/kst';

test('fields: 객체가 아니면 빈 묶음', () => {
  assert.deepEqual(fields(null), {});
  assert.deepEqual(fields('x'), {});
  assert.deepEqual(fields({ a: 1 }), { a: 1 });
});

test('docId: 빈 값 · 경로 넘나들기 · 너무 긴 값 거부', () => {
  assert.equal(docId('abc', 'id'), 'abc');
  for (const bad of ['', 'a/b', 'x'.repeat(129), 3, undefined]) {
    assert.throws(() => docId(bad, 'id'), { code: 'invalid-argument' });
  }
});

test('ownPhotoPath: 내 폴더 바로 아래 파일만', () => {
  assert.equal(ownPhotoPath('trades/t1/u1/a.jpg', 't1', 'u1'), 'trades/t1/u1/a.jpg');
  for (const bad of ['trades/t1/u2/a.jpg', 'trades/t1/u1/x/a.jpg', 'trades/t1/u1/../u2/a.jpg', 'trades/t2/u1/a.jpg', null]) {
    assert.throws(() => ownPhotoPath(bad, 't1', 'u1'), { code: 'invalid-argument' });
  }
});

test('kstDay: 한국 날짜', () => {
  assert.equal(kstDay(Date.UTC(2026, 9, 22, 14, 59)), '2026-10-22');
  assert.equal(kstDay(Date.UTC(2026, 9, 22, 15, 0)), '2026-10-23');
});
