/**
 * 앱이 부르는 함수(onCall). 로그인 확인과 App Check만 여기서 하고, 일은 core.ts가 한다.
 * 앱에서는 `FirebaseFunctions.instanceFor(region: 'asia-northeast3').httpsCallable('<이름>')`로 부른다.
 */
import { Firestore, getFirestore } from 'firebase-admin/firestore';
import { CallableRequest, HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { ENFORCE_APP_CHECK } from '../config';
import * as core from './core';

type Handler = (db: Firestore, uid: string, data: unknown) => Promise<unknown>;

function callable(handler: Handler) {
  return onCall({ enforceAppCheck: ENFORCE_APP_CHECK }, async (req: CallableRequest) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', '로그인이 필요해요.');
    return handler(getFirestore(), uid, req.data);
  });
}

export const applyToRequest = callable(core.applyToRequest);
export const withdrawApplication = callable(core.withdrawApplication);
export const acceptApplication = callable(core.acceptApplication);
export const rejectApplication = callable(core.rejectApplication);
export const cancelRequest = callable(core.cancelRequest);
export const advanceTrade = callable(core.advanceTrade);

/** 마감이 지난 모집을 한 시간마다 정리한다. 한 번에 300건까지. */
export const expireRequests = onSchedule({ schedule: 'every 60 minutes', timeZone: 'Asia/Seoul' }, async () => {
  await core.expireOpenRequests(getFirestore());
});
