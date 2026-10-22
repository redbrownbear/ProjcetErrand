/**
 * 겸사겸사 서버 함수 진입점.
 * 설계: docs/1차_백엔드_설계.md (W3 거래 흐름 서버화)
 */
import { initializeApp } from 'firebase-admin/app';

import './config';

initializeApp();

export {
  acceptApplication,
  advanceTrade,
  applyToRequest,
  cancelRequest,
  expireRequests,
  rejectApplication,
  withdrawApplication,
} from './errand/callables';

export { onApplicationWrite, onRequestPlaced, onRequestWrite, onRouteWrite, onTradeWrite } from './notify/triggers';
export { adminResolveReport, adminSetRequestHidden, adminSetSuspended } from './admin/callables';
export { markChatRead, sendMessage } from './chat/callables';
export { addComment } from './comment/callables';
export { addTradePhoto } from './photo/callables';
