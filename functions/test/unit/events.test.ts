import assert from 'node:assert/strict';
import { test } from 'node:test';

import { applicationEvents, tradeEvents } from '../../src/notify/events';

const app = (status: string, extra: Record<string, unknown> = {}) => ({
  status,
  helperUid: 'h',
  requesterUid: 'r',
  helperName: '지수',
  requestTitle: '편의점 택배 찾아 주세요',
  ...extra,
});
const trade = (status: string, extra: Record<string, unknown> = {}) => ({
  status,
  requesterUid: 'r',
  helperUid: 'h',
  requestId: '1',
  title: '택배',
  ...extra,
});

test('새 지원 → 요청자에게', () => {
  const [ev, ...rest] = applicationEvents('1', undefined, app('pending'));
  assert.equal(rest.length, 0);
  assert.equal(ev.to, 'r');
  assert.equal(ev.kind, 'application.new');
  assert.match(ev.body, /지수님이 "편의점 택배 찾아 주세요"에 지원했어요/);
});

test('수락·거절 → 지원자에게, 철회 → 요청자에게', () => {
  assert.deepEqual(
    applicationEvents('1', app('pending'), app('accepted', { tradeId: 't1' })).map((e) => [e.to, e.kind, e.tradeId]),
    [['h', 'application.accepted', 't1']],
  );
  assert.deepEqual(applicationEvents('1', app('pending'), app('rejected')).map((e) => [e.to, e.kind]), [['h', 'application.rejected']]);
  assert.deepEqual(applicationEvents('1', app('pending'), app('withdrawn')).map((e) => [e.to, e.kind]), [['r', 'application.withdrawn']]);
});

test('상태가 그대로이거나 삭제·수락 뒤 취소면 지원 알림 없음', () => {
  assert.equal(applicationEvents('1', app('pending'), app('pending', { msg: '수정' })).length, 0);
  assert.equal(applicationEvents('1', app('pending'), undefined).length, 0);
  assert.equal(applicationEvents('1', app('accepted'), app('cancelled')).length, 0);
});

test('거래 단계별 받는 사람', () => {
  const to = (prev: string, next: string, extra = {}) => tradeEvents('t', trade(prev), trade(next, extra)).map((e) => [e.to, e.kind]);
  assert.deepEqual(to('matched', 'working'), [['r', 'trade.started']]);
  assert.deepEqual(to('working', 'confirmation'), [['r', 'trade.confirmRequested']]);
  assert.deepEqual(to('confirmation', 'working'), [['h', 'trade.revise']]);
  assert.deepEqual(to('confirmation', 'completed'), [['h', 'trade.completed']]);
  assert.deepEqual(to('matched', 'cancelled', { cancelledBy: 'helper' }), [['r', 'trade.cancelled']]);
  assert.deepEqual(to('matched', 'cancelled', { cancelledBy: 'requester' }), [['h', 'trade.cancelled']]);
});

test('거래 생성(matched)·단계 그대로면 거래 알림 없음', () => {
  assert.equal(tradeEvents('t', undefined, trade('matched')).length, 0);
  assert.equal(tradeEvents('t', trade('working'), trade('working')).length, 0);
});

test('긴 제목은 줄인다', () => {
  const [ev] = applicationEvents('1', undefined, app('pending', { requestTitle: '가'.repeat(40) }));
  assert.match(ev.body, /"가{20}…"/);
});

test('가는 김에(going) 신청은 지원이 아니라 부탁으로 알린다', () => {
  const [ev] = applicationEvents('1', undefined, app('pending', { requestMode: 'going', requestTitle: '내일 오사카 가요' }));
  assert.equal(ev.to, 'r');
  assert.equal(ev.title, '새 부탁이 왔어요');
  assert.match(ev.body, /부탁을 보냈어요/);
  const [acc] = applicationEvents('1', app('pending', { requestMode: 'going' }), app('accepted', { requestMode: 'going', tradeId: 't' }));
  assert.equal(acc.to, 'h');
  assert.equal(acc.title, '부탁이 수락됐어요');
});
