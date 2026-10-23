import { fcm } from '../notify/fcm';
import { userCallable } from '../shared/callable';
import * as core from './core';

export const addComment = userCallable((db, uid, data) => core.addComment(db, uid, data, fcm));
