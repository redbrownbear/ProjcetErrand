/**
 * 지원서·거래 문서가 바뀌면 알림을 보낸다(W4). 문구는 events.ts, 전달은 deliver.ts.
 */
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';

import { deliver, PushSender } from './deliver';
import { applicationEvents, NotifyEvent, tradeEvents } from './events';

const INVALID = new Set(['messaging/registration-token-not-registered', 'messaging/invalid-registration-token']);

const fcm: PushSender = async ({ tokens, title, body, data }) => {
  const res = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
    android: { priority: 'high' },
  });
  return res.responses.flatMap((r, i) => (!r.success && r.error && INVALID.has(r.error.code) ? [tokens[i]] : []));
};

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
