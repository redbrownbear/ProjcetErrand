import { Firestore, getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { ENFORCE_APP_CHECK } from '../config';
import * as core from './core';

function adminCallable(handler: (db: Firestore, uid: string, data: unknown) => Promise<unknown>) {
  return onCall({ enforceAppCheck: ENFORCE_APP_CHECK }, async (req) => {
    if (!req.auth) throw new HttpsError('unauthenticated', '로그인이 필요해요.');
    core.assertAdmin(req.auth.token as Record<string, unknown>);
    return handler(getFirestore(), req.auth.uid, req.data);
  });
}

export const adminSetSuspended = adminCallable(core.setSuspended);
export const adminResolveReport = adminCallable(core.resolveReport);
