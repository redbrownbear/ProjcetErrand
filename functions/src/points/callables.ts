/** 포인트(B09) 서버 함수. 일은 core.ts가 한다. */
import { getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { ENFORCE_APP_CHECK } from '../config';
import * as core from './core';

function callable(handler: (uid: string, data: unknown) => Promise<unknown>) {
  return onCall({ enforceAppCheck: ENFORCE_APP_CHECK }, async (req) => {
    if (!req.auth) throw new HttpsError('unauthenticated', '로그인이 필요해요.');
    return handler(req.auth.uid, req.data);
  });
}

export const earnPoints = callable((uid, data) => core.earnPoints(getFirestore(), uid, data));
export const redeemPoints = callable((uid, data) => core.redeemPoints(getFirestore(), uid, data));
export const useCoupon = callable((uid, data) => core.useCoupon(getFirestore(), uid, data));

/** 유효기간이 지난 적립분 소멸. 매일 새벽 4시(한국). config/points.expireDays가 0이면 하지 않는다 */
export const expirePoints = onSchedule({ schedule: '0 4 * * *', timeZone: 'Asia/Seoul' }, async () => {
  await core.expirePoints(getFirestore());
});
