/** 제안하기(A15 · A29 · A30) 서버 함수. 일은 core.ts가 한다 */
import { fcm } from '../notify/fcm';
import { userCallable } from '../shared/callable';
import * as core from './core';

export const createProposal = userCallable((db, uid, data) => core.createProposal(db, uid, data));
export const joinProposal = userCallable((db, uid, data) => core.joinProposal(db, uid, data, fcm));
export const leaveProposal = userCallable((db, uid, data) => core.leaveProposal(db, uid, data, fcm));
export const raiseProposalMax = userCallable((db, uid, data) => core.raiseProposalMax(db, uid, data, fcm));
export const decideProposal = userCallable((db, uid, data) => core.decideProposal(db, uid, data, fcm));
export const askProposer = userCallable((db, uid, data) => core.askProposer(db, uid, data, fcm));
export const answerProposerAsk = userCallable((db, uid, data) => core.answerProposerAsk(db, uid, data, fcm));
