import assert from 'node:assert/strict';
import { test } from 'node:test';

import { advance } from '../../src/domain/tradeMachine';

test('정상 경로: matched → working → confirmation → completed', () => {
  assert.deepEqual(advance('matched', 'start', 'helper'), { ok: true, next: 'working' });
  assert.deepEqual(advance('working', 'finish', 'helper'), { ok: true, next: 'confirmation' });
  assert.deepEqual(advance('confirmation', 'confirm', 'requester'), { ok: true, next: 'completed' });
});

test('보완 요청은 요청자만, 진행 중으로 되돌린다', () => {
  assert.deepEqual(advance('confirmation', 'revise', 'requester'), { ok: true, next: 'working' });
  assert.deepEqual(advance('confirmation', 'revise', 'helper'), { ok: false, reason: 'wrong-role' });
});

test('역할이 틀리면 거부', () => {
  assert.deepEqual(advance('matched', 'start', 'requester'), { ok: false, reason: 'wrong-role' });
  assert.deepEqual(advance('confirmation', 'confirm', 'helper'), { ok: false, reason: 'wrong-role' });
});

test('단계를 건너뛰거나 끝난 거래는 거부', () => {
  assert.deepEqual(advance('matched', 'finish', 'helper'), { ok: false, reason: 'not-allowed-now' });
  assert.deepEqual(advance('working', 'cancel', 'helper'), { ok: false, reason: 'not-allowed-now' });
  assert.deepEqual(advance('completed', 'revise', 'requester'), { ok: false, reason: 'not-allowed-now' });
  assert.deepEqual(advance('cancelled', 'start', 'helper'), { ok: false, reason: 'not-allowed-now' });
});

test('시작 전 취소는 양쪽 모두 가능', () => {
  assert.deepEqual(advance('matched', 'cancel', 'helper'), { ok: true, next: 'cancelled' });
  assert.deepEqual(advance('matched', 'cancel', 'requester'), { ok: true, next: 'cancelled' });
});
