import { getFirestore } from 'firebase-admin/firestore';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';

import { fcm } from '../notify/fcm';
import { screenRequest } from './screen';

/** 부탁 글이 올라오거나 고쳐지면 금지 품목 · 물건값 상한을 본다(A20) */
export const onRequestWrite = onDocumentWritten('requests/{requestId}', async (event) => {
  await screenRequest(getFirestore(), event.params.requestId, event.data?.before.data(), event.data?.after.data(), fcm);
});
