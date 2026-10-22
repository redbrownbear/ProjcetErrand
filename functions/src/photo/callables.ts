import { getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { ENFORCE_APP_CHECK } from '../config';
import { fcm } from '../notify/triggers';
import * as core from './core';

export const addTradePhoto = onCall({ enforceAppCheck: ENFORCE_APP_CHECK }, async (req) => {
  if (!req.auth) throw new HttpsError('unauthenticated', '로그인이 필요해요.');
  return core.addTradePhoto(getFirestore(), req.auth.uid, req.data, fcm);
});
