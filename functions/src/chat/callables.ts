import { fcm } from '../notify/fcm';
import { userCallable } from '../shared/callable';
import * as core from './core';

export const sendMessage = userCallable((db, uid, data) => core.sendMessage(db, uid, data, fcm));
export const markChatRead = userCallable(core.markChatRead);
