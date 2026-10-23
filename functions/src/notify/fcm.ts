/** 실제 FCM 푸시. 테스트는 deliver()에 가짜 PushSender를 넣는다 */
import { getMessaging } from 'firebase-admin/messaging';

import { PushSender } from './deliver';

const INVALID = new Set(['messaging/registration-token-not-registered', 'messaging/invalid-registration-token']);

/** 보내고, 앱 삭제 · 만료로 못 쓰게 된 토큰을 돌려준다(deliver가 지운다) */
export const fcm: PushSender = async ({ tokens, title, body, data }) => {
  const res = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
    android: { priority: 'high' },
  });
  return res.responses.flatMap((r, i) => (!r.success && r.error && INVALID.has(r.error.code) ? [tokens[i]] : []));
};
