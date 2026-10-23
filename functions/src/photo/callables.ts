import { fcm } from '../notify/fcm';
import { userCallable } from '../shared/callable';
import * as core from './core';

export const addTradePhoto = userCallable((db, uid, data) => core.addTradePhoto(db, uid, data, fcm));
