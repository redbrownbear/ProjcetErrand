/** 포인트(B09) 서버 함수. 일은 core.ts가 한다. */
import { getFirestore } from 'firebase-admin/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { userCallable } from '../shared/callable';
import * as core from './core';

export const earnPoints = userCallable((db, uid, data) => core.earnPoints(db, uid, data));
export const redeemPoints = userCallable((db, uid, data) => core.redeemPoints(db, uid, data));
export const useCoupon = userCallable((db, uid, data) => core.useCoupon(db, uid, data));

/** 유효기간이 지난 적립분 소멸. 매일 새벽 4시(한국). config/points.expireDays가 0이면 하지 않는다 */
export const expirePoints = onSchedule({ schedule: '0 4 * * *', timeZone: 'Asia/Seoul' }, async () => {
  await core.expirePoints(getFirestore());
});
