/**
 * 지원서·거래 문서가 바뀌면 알림을 보낸다(W4). 문구는 events.ts, 전달은 deliver.ts.
 */
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';

import { deliver } from './deliver';
import { fcm } from './fcm';
import { applicationEvents, NotifyEvent, tradeEvents } from './events';

function stamp(d: Record<string, unknown> | undefined): number {
  const at = d?.updatedAt;
  return at instanceof Timestamp ? at.toMillis() : 0;
}

async function send(events: NotifyEvent[], docId: string, at: number) {
  const db = getFirestore();
  for (const ev of events) {
    await deliver(db, fcm, ev, `${ev.kind}_${docId}_${at}`);
  }
}

export const onApplicationWrite = onDocumentWritten('requests/{requestId}/applications/{helperUid}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  const id = `${event.params.requestId}-${event.params.helperUid}`;
  await send(applicationEvents(event.params.requestId, before, after), id, stamp(after));
});

export const onTradeWrite = onDocumentWritten('trades/{tradeId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  await send(tradeEvents(event.params.tradeId, before, after), event.params.tradeId, stamp(after));
});
