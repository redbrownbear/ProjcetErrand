/** 부탁 · 지원 · 거래 서버 함수. 일은 core.ts가 한다 */
import { getFirestore } from 'firebase-admin/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { userCallable } from '../shared/callable';
import * as core from './core';

export const applyToRequest = userCallable(core.applyToRequest);
export const withdrawApplication = userCallable(core.withdrawApplication);
export const acceptApplication = userCallable(core.acceptApplication);
export const rejectApplication = userCallable(core.rejectApplication);
export const cancelRequest = userCallable(core.cancelRequest);
export const advanceTrade = userCallable(core.advanceTrade);

/** 마감이 지난 모집을 한 시간마다 정리한다. 한 번에 300건까지. */
export const expireRequests = onSchedule({ schedule: 'every 60 minutes', timeZone: 'Asia/Seoul' }, async () => {
  await core.expireOpenRequests(getFirestore());
});
