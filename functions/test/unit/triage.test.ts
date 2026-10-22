import assert from 'node:assert/strict';
import { describe, test } from 'node:test';

import { classify, firstReply } from '../../src/admin/triage';

describe('신고 자동 분류(A34)', () => {
  test('사유로 유형 · 긴급도', () => {
    assert.deepEqual(
      [classify('사기·결제 유도 의심', '', 1).category, classify('사기·결제 유도 의심', '', 1).priority],
      ['fraud', 'high'],
    );
    assert.equal(classify('노쇼·약속 불이행', '', 1).priority, 'normal');
    assert.equal(classify('연락처·외부 거래 유도', '', 1).category, 'offplatform');
  });

  test('위험한 말은 유형과 상관없이 가장 급하게', () => {
    const t = classify('노쇼·약속 불이행', '안 나와서 연락했더니 집까지 따라와 협박했어요', 1);
    assert.equal(t.category, 'noshow');
    assert.equal(t.priority, 'urgent');
    assert.ok(t.signals.some((s) => s.includes('협박')));
    assert.match(firstReply(t).body, /112/);
  });

  test("'기타'는 내용으로 다시 분류, 비슷한 낱말엔 걸리지 않음", () => {
    assert.equal(classify('기타', '먼저 계좌로 입금하라고 해요', 1).category, 'fraud');
    assert.equal(classify('기타', '카톡으로 하자고 계속 그래요', 1).category, 'offplatform');
    assert.equal(classify('기타', '', 1, '소주').category, 'prohibited');
    const plain = classify('기타', '칼국수 집 앞에서 온라인 주문한 걸 받기로 했어요', 1);
    assert.equal(plain.category, 'other');
    assert.equal(plain.priority, 'normal');
  });

  test('같은 사람에게 신고가 몰리면 high', () => {
    const t = classify('노쇼·약속 불이행', '', 3);
    assert.equal(t.priority, 'high');
    assert.ok(t.signals.some((s) => s.includes('3명')));
  });

  test('1차 안내는 앱이 하지 않는 일을 약속하지 않는다', () => {
    for (const reason of ['금지 품목·불법 부탁', '사기·결제 유도 의심', '노쇼·약속 불이행', '욕설·위협·불쾌한 행동', '연락처·외부 거래 유도', '기타']) {
      const { body } = firstReply(classify(reason, '', 1));
      assert.doesNotMatch(body, /환불해|보상해|안전결제|\d+시간 (안|이내)/, reason);
    }
  });
});
