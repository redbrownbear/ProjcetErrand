/**
 * 배포되는 함수 이름 목록. 이미 깔린 앱이 이 이름으로 부르므로, 이름을 바꾸거나 빼면 예전 앱이 깨진다.
 * 새 함수를 더했으면 아래 목록에도 더한다. 정말 빼야 하면(예전 앱이 더는 없을 때) 이유를 WORKLOG에 남기고 지운다.
 */
import assert from 'node:assert/strict';
import { test } from 'node:test';

const DEPLOYED = [
  // 부탁 · 지원 · 거래
  'acceptApplication',
  'advanceTrade',
  'applyToRequest',
  'cancelRequest',
  'expireRequests',
  'rejectApplication',
  'withdrawApplication',
  // 알림
  'onApplicationWrite',
  'onTradeWrite',
  // 운영 · 신고
  'adminResolveReport',
  'adminSetRequestHidden',
  'adminSetSuspended',
  'onReportCreate',
  // 금지 품목
  'onRequestWrite',
  // 동선 · 추천
  'onRequestPlaced',
  'onRouteWrite',
  // 채팅 · 댓글 · 사진
  'addComment',
  'addTradePhoto',
  'markChatRead',
  'sendMessage',
  // 제안하기
  'answerProposerAsk',
  'askProposer',
  'createProposal',
  'decideProposal',
  'joinProposal',
  'leaveProposal',
  'raiseProposalMax',
  // 포인트
  'earnPoints',
  'expirePoints',
  'redeemPoints',
  'useCoupon',
  // 로그인
  'socialSignIn',
];

test('배포되는 함수 이름이 그대로다(예전 앱 보호)', async () => {
  const index = (await import('../../src/index')) as Record<string, unknown>;
  const now = Object.keys(index).filter((k) => typeof index[k] === 'function').sort();
  const missing = DEPLOYED.filter((n) => !now.includes(n));
  assert.deepEqual(missing, [], `없어진 함수 — 예전 앱이 부르면 실패한다: ${missing.join(', ')}`);
  const added = now.filter((n) => !DEPLOYED.includes(n));
  assert.deepEqual(added, [], `새 함수는 이 목록에도 더해 주세요: ${added.join(', ')}`);
});
