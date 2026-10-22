/**
 * 지원서·거래 문서가 바뀌면 알림을 보낸다(W4). 문구는 events.ts, 전달은 deliver.ts.
 */
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';

import { computeRouteCells } from '../route/core';
import { matchRequest } from '../route/match';
import { screenRequest } from '../safety/screen';
import { deliver, PushSender } from './deliver';
import { applicationEvents, NotifyEvent, tradeEvents } from './events';

const INVALID = new Set(['messaging/registration-token-not-registered', 'messaging/invalid-registration-token']);

export const fcm: PushSender = async ({ tokens, title, body, data }) => {
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

/** 부탁 글이 올라오거나 고쳐지면 금지 품목 · 물건값 상한을 본다(A20) */
export const onRequestWrite = onDocumentWritten('requests/{requestId}', async (event) => {
  await screenRequest(getFirestore(), event.params.requestId, event.data?.before.data(), event.data?.after.data(), fcm);
});

/** 정기 동선이 생기거나 바뀌면 매칭용 격자를 계산한다(W6 · A02) */
export const onRouteWrite = onDocumentWritten('users/{uid}/routes/{routeId}', async (event) => {
  await computeRouteCells(getFirestore(), event.params.uid, event.params.routeId, event.data?.before.data(), event.data?.after.data());
});

/** 부탁의 정확한 위치가 처음 저장되면 동선과 맞춰 추천 · 알림(W7 · A13). 한 번만 계산한다 */
export const onRequestPlaced = onDocumentCreated('requests/{requestId}/private/detail', async (event) => {
  const d = event.data?.data();
  if (typeof d?.lat !== 'number' || typeof d?.lng !== 'number') return;
  await matchRequest(getFirestore(), event.params.requestId, d.lat, d.lng, fcm);
});
