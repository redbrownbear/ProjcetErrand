import { getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { ENFORCE_APP_CHECK } from '../config';
import { fcm } from '../notify/triggers';
import * as core from './core';

function callable(handler: (uid: string, data: unknown) => Promise<unknown>) {
  return onCall({ enforceAppCheck: ENFORCE_APP_CHECK }, async (req) => {
    if (!req.auth) throw new HttpsError('unauthenticated', '로그인이 필요해요.');
    return handler(req.auth.uid, req.data);
  });
}

export const createProposal = callable((uid, data) => core.createProposal(getFirestore(), uid, data));
export const joinProposal = callable((uid, data) => core.joinProposal(getFirestore(), uid, data, fcm));
export const leaveProposal = callable((uid, data) => core.leaveProposal(getFirestore(), uid, data, fcm));
export const raiseProposalMax = callable((uid, data) => core.raiseProposalMax(getFirestore(), uid, data, fcm));
export const decideProposal = callable((uid, data) => core.decideProposal(getFirestore(), uid, data, fcm));
export const askProposer = callable((uid, data) => core.askProposer(getFirestore(), uid, data, fcm));
export const answerProposerAsk = callable((uid, data) => core.answerProposerAsk(getFirestore(), uid, data, fcm));
