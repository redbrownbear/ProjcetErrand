/** 카카오 · 네이버 로그인 서버 함수. 일은 core.ts가 한다. 로그인 전에 부르므로 req.auth가 없다 */
import { getAuth } from 'firebase-admin/auth';
import { onCall } from 'firebase-functions/v2/https';

import { ENFORCE_APP_CHECK } from '../config';
import * as core from './core';

export const socialSignIn = onCall({ enforceAppCheck: ENFORCE_APP_CHECK }, async (req) =>
  core.socialSignIn(getAuth(), fetch, req.data, { kakaoAppId: process.env.KAKAO_APP_ID ?? '' }),
);
