import { getFirestore } from 'firebase-admin/firestore';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';

import { fcm } from '../notify/fcm';
import { triageReport } from './triage';

/** 신고가 접수되면 유형 · 긴급도를 붙이고 신고한 사람에게 1차 안내(A34). 처리는 운영자가 한다 */
export const onReportCreate = onDocumentCreated('reports/{reportId}', async (event) => {
  await triageReport(getFirestore(), event.params.reportId, fcm);
});
