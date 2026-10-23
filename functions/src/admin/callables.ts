import { fcm } from '../notify/fcm';
import { Handler, userCallable } from '../shared/callable';
import * as core from './core';

const adminCallable = (handler: Handler) => userCallable(handler, core.assertAdmin);

export const adminSetSuspended = adminCallable(core.setSuspended);
export const adminResolveReport = adminCallable((db, uid, data) => core.resolveReport(db, uid, data, fcm));
export const adminSetRequestHidden = adminCallable((db, uid, data) => core.setRequestHidden(db, uid, data, fcm));
