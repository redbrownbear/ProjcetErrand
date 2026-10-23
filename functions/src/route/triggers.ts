import { getFirestore } from 'firebase-admin/firestore';
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';

import { fcm } from '../notify/fcm';
import { computeRouteCells } from './core';
import { matchRequest } from './match';

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
