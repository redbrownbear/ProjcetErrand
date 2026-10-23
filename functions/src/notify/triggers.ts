/**
 * 지원서·거래 문서가 바뀌면 알림을 보낸다(W4). 문구는 events.ts, 전달은 deliver.ts.
 */
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';

import { triageReport } from '../admin/triage';
import { computeRouteCells } from '../route/core';
import { matchRequest } from '../route/match';
import { screenRequest } from '../safety/screen';
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

/** 신고가 접수되면 유형 · 긴급도를 붙이고 신고한 사람에게 1차 안내(A34). 처리는 운영자가 한다 */
export const onReportCreate = onDocumentCreated('reports/{reportId}', async (event) => {
  await triageReport(getFirestore(), event.params.reportId, fcm);
});
