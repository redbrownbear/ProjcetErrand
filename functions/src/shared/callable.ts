/**
 * 앱이 부르는 함수(onCall)의 공통 껍데기. 로그인 확인과 App Check만 여기서 하고, 일은 각 모듈의 core.ts가 한다.
 * 앱에서는 `FirebaseFunctions.instanceFor(region: 'asia-northeast3').httpsCallable('<이름>')`로 부른다.
 */
import { Firestore, getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { ENFORCE_APP_CHECK } from '../config';

export type Handler = (db: Firestore, uid: string, data: unknown) => Promise<unknown>;

/** 로그인한 사용자만. [check]는 토큰을 더 볼 때(운영자 등) — 통과하지 못하면 던진다 */
export function userCallable(handler: Handler, check?: (token: Record<string, unknown>) => void) {
  return onCall({ enforceAppCheck: ENFORCE_APP_CHECK }, async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', '로그인이 필요해요.');
    check?.(req.auth!.token as Record<string, unknown>);
    return handler(getFirestore(), uid, req.data);
  });
}
