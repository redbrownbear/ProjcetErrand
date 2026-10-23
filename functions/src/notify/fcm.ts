/** 실제 FCM 푸시. 테스트는 deliver()에 가짜 PushSender를 넣는다 */
import { getMessaging } from 'firebase-admin/messaging';

import { PushSender } from './deliver';

const INVALID = new Set(['messaging/registration-token-not-registered', 'messaging/invalid-registration-token']);

/** 보내고, 앱 삭제 · 만료로 못 쓰게 된 토큰을 돌려준다(deliver가 지운다) */
export const fcm: PushSender = async ({ tokens, title, body, data }) => {
  // 로컬 에뮬레이터에서는 실제 FCM으로 보내지 않는다(자격 증명이 없고, 알림함 기록만으로 흐름을 확인할 수 있다)
  if (process.env.FUNCTIONS_EMULATOR === 'true') {
    console.log(`[푸시 생략 · 에뮬레이터] ${title} — ${body}`);
    return [];
  }
  const res = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
    android: { priority: 'high' },
  });
  return res.responses.flatMap((r, i) => (!r.success && r.error && INVALID.has(r.error.code) ? [tokens[i]] : []));
};
