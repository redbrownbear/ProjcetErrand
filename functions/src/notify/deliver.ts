/**
 * 알림 한 건 보내기: 받는 사람의 알림함(users/{uid}/notifications/{eventId})에 기록하고 FCM으로 푸시한다.
 *
 * 트리거는 같은 변경을 두 번 이상 전달할 수 있다. 알림 문서를 create()로 만들어
 * 이미 있으면(같은 eventId) 아무것도 하지 않는다 → 같은 알림이 두 번 가지 않는다.
 */
import { Firestore, Timestamp } from 'firebase-admin/firestore';

import { NotifyEvent } from './events';

export interface PushMessage {
  tokens: string[];
  title: string;
  body: string;
  data: Record<string, string>;
}

/** 실패한 토큰 목록을 돌려준다(앱 삭제·토큰 만료). 테스트에서는 가짜를 넣는다. */
export type PushSender = (msg: PushMessage) => Promise<string[]>;

/**
 * [opts.store]가 false면 알림함에 남기지 않고 푸시만 보낸다(채팅). 이때는 중복 방지가 없으니 호출하는 쪽이 한 번만 부른다.
 */
export async function deliver(
  db: Firestore,
  send: PushSender,
  ev: NotifyEvent,
  eventId: string,
  opts: { store?: boolean } = {},
): Promise<boolean> {
  if (!ev.to) return false;
  const user = db.collection('users').doc(ev.to);
  if (opts.store !== false) {
    try {
      await user.collection('notifications').doc(eventId).create({
        kind: ev.kind,
        title: ev.title,
        body: ev.body,
        requestId: ev.requestId,
        tradeId: ev.tradeId ?? null,
        tripId: ev.tripId ?? null,
        createdAt: Timestamp.now(),
        readAt: null,
      });
    } catch (e) {
      if ((e as { code?: number }).code === 6) return false; // ALREADY_EXISTS — 이미 보낸 알림
      throw e;
    }
  }

  const tokens = (await user.collection('fcmTokens').get()).docs.map((d) => d.id);
  if (!tokens.length) return true;
  const bad = await send({
    tokens,
    title: ev.title,
    body: ev.body,
    data: { kind: ev.kind, requestId: ev.requestId, ...(ev.tradeId ? { tradeId: ev.tradeId } : {}), ...(ev.tripId ? { tripId: ev.tripId } : {}) },
  });
  await Promise.all(bad.map((t) => user.collection('fcmTokens').doc(t).delete()));
  return true;
}
