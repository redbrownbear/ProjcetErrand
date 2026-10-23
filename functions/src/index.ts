/**
 * 겸사겸사 서버 함수 진입점 — 여기 export된 이름이 곧 배포되는 함수 이름이다.
 * 이미 깔린 앱이 이름으로 부르므로 **이름을 바꾸거나 빼지 않는다**(test/unit/exports.test.ts가 지킨다).
 *
 * 모듈마다 core.ts(로직, Firestore만 받아 테스트 가능) · callables.ts(앱이 부르는 함수) · triggers.ts(문서 변경 · 예약 실행).
 * 구조와 새 함수 추가 방법은 functions/README.md, 설계는 docs/1차_백엔드_설계.md.
 */
import { initializeApp } from 'firebase-admin/app';

import './config';

initializeApp();

// 부탁 · 지원 · 거래 (W3)
export {
  acceptApplication,
  advanceTrade,
  applyToRequest,
  cancelRequest,
  expireRequests,
  rejectApplication,
  withdrawApplication,
} from './errand/callables';
// 알림 (W4)
export { onApplicationWrite, onTradeWrite } from './notify/triggers';
// 운영 · 신고 (W5 · A34 · A36)
export { adminResolveReport, adminSetRequestHidden, adminSetSuspended } from './admin/callables';
export { onReportCreate } from './admin/triggers';
// 금지 품목 · 물건값 상한 (A20)
export { onRequestWrite } from './safety/triggers';
// 동선 · 추천 (W6 · W7)
export { onRequestPlaced, onRouteWrite } from './route/triggers';
// 채팅 · 댓글 · 사진
export { markChatRead, sendMessage } from './chat/callables';
export { addComment } from './comment/callables';
export { addTradePhoto } from './photo/callables';
// 제안하기 (A15 · A29 · A30)
export { answerProposerAsk, askProposer, createProposal, decideProposal, joinProposal, leaveProposal, raiseProposalMax } from './proposal/callables';
// 포인트 (B09)
export { earnPoints, expirePoints, redeemPoints, useCoupon } from './points/callables';
// 로그인 (카카오 · 네이버)
export { socialSignIn } from './auth/callables';
