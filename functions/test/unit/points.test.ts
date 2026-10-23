import assert from 'node:assert/strict';
import { describe, test } from 'node:test';

import { attendReward, kstDay } from '../../src/points/core';

describe('출석 보상(B09) — 앱 Attendance.todayReward와 같은 규칙', () => {
  test('첫 출석 1P, 같은 날 두 번은 없음', () => {
    const r = attendReward(null, '2026-10-23')!;
    assert.equal(r.amount, 1);
    assert.deepEqual(r.next, { last: '2026-10-23', streak: 1, month: '2026-10', monthCount: 1 });
    assert.equal(attendReward(r.next, '2026-10-23'), null);
  });

  test('7일 연속마다 +10P, 하루 쉬면 연속만 처음부터', () => {
    let s = attendReward(null, '2026-10-01')!.next;
    for (let d = 2; d <= 6; d++) s = attendReward(s, `2026-10-0${d}`)!.next;
    const seventh = attendReward(s, '2026-10-07')!;
    assert.equal(seventh.amount, 11);
    const gap = attendReward(seventh.next, '2026-10-09')!;
    assert.equal(gap.next.streak, 1);
    assert.equal(gap.next.monthCount, 8);
  });

  test('월 누적 20일째 +100P, 다음 달은 새로', () => {
    const r = attendReward({ last: '2026-10-25', streak: 1, month: '2026-10', monthCount: 19 }, '2026-10-27')!;
    assert.equal(r.amount, 101);
    const nov = attendReward({ last: '2026-10-31', streak: 3, month: '2026-10', monthCount: 25 }, '2026-11-01')!;
    assert.deepEqual([nov.next.streak, nov.next.monthCount], [4, 1]);
  });

  test('한국 날짜', () => {
    assert.equal(kstDay(Date.UTC(2026, 9, 22, 15, 30)), '2026-10-23');
  });
});
