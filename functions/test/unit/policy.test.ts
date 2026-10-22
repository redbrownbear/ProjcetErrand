import assert from 'node:assert/strict';
import { describe, test } from 'node:test';

import { DEFAULT_POLICY, findBlocked, requestViolation } from '../../src/safety/policy';

describe('금지 품목 · 물건값 상한', () => {
  test('띄어쓰기 · 대소문자와 상관없이 금지어를 찾는다', () => {
    assert.equal(findBlocked('편의점에서 소주 2병', DEFAULT_POLICY), '소주');
    assert.equal(findBlocked('전자 담배 액상', DEFAULT_POLICY), '담배');
    assert.equal(findBlocked('감 기 약 사다 주세요', DEFAULT_POLICY), '감기약');
  });

  test('짧은 말이 다른 낱말 속에 있어도 걸리지 않는다', () => {
    for (const ok of ['기술 서적 반납', '미술관 앞에서 만나요', '식당 예약 대신 해 주세요', '술집 앞 택배함', '약국 앞 정류장']) {
      assert.equal(findBlocked(ok, DEFAULT_POLICY), null, ok);
    }
  });

  test('부탁 글: 금지어 또는 건당 물건값 상한(국내 5만 · 해외 10만)', () => {
    assert.match(requestViolation({ title: '맥주 사다 주세요', mode: 'ask' }, DEFAULT_POLICY) ?? '', /맥주/);
    assert.match(requestViolation({ title: '아이패드', mode: 'ask', budget: 50_001 }, DEFAULT_POLICY) ?? '', /50,000원/);
    assert.equal(requestViolation({ title: '휴지', mode: 'ask', budget: 50_000 }, DEFAULT_POLICY), null);
    assert.equal(requestViolation({ title: '면세 화장품', mode: 'sea', budget: 90_000 }, DEFAULT_POLICY), null);
    assert.match(requestViolation({ title: '면세 화장품', mode: 'sea', budget: 100_001 }, DEFAULT_POLICY) ?? '', /100,000원/);
  });
});
