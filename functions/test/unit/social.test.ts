import assert from 'node:assert/strict';
import { describe, test } from 'node:test';

import { AuthLike, cleanName, Fetch, socialSignIn } from '../../src/auth/core';

/** 주소별로 정해 둔 응답을 돌려주는 가짜 fetch */
function fakeFetch(routes: Record<string, { status: number; body: unknown }>): Fetch {
  return async (url) => {
    const r = routes[url];
    if (!r) throw new Error(`unexpected ${url}`);
    return { status: r.status, json: async () => r.body };
  };
}

function fakeAuth(existing: Record<string, { disabled: boolean }> = {}) {
  const created: { uid: string; displayName: string }[] = [];
  const auth: AuthLike = {
    getUser: async (uid) => {
      if (existing[uid]) return existing[uid];
      throw Object.assign(new Error('no user'), { code: 'auth/user-not-found' });
    },
    createUser: async (p) => created.push(p),
    createCustomToken: async (uid, claims) => `token:${uid}:${JSON.stringify(claims)}`,
  };
  return { auth, created };
}

const kakaoOk = {
  'https://kapi.kakao.com/v1/user/access_token_info': { status: 200, body: { id: 42, app_id: 1234 } },
  'https://kapi.kakao.com/v2/user/me': { status: 200, body: { id: 42, kakao_account: { profile: { nickname: '  겸이  ' } } } },
};
const env = { kakaoAppId: '1234' };
const tok = 'a'.repeat(20);

describe('카카오 · 네이버 로그인', () => {
  test('카카오: 처음이면 계정을 만들고 uid는 kakao:{회원번호}', async () => {
    const { auth, created } = fakeAuth();
    const r = await socialSignIn(auth, fakeFetch(kakaoOk), { provider: 'kakao', accessToken: tok }, env);
    assert.equal(r.uid, 'kakao:42');
    assert.equal(r.isNew, true);
    assert.deepEqual(created, [{ uid: 'kakao:42', displayName: '겸이' }]);
    assert.equal(r.token, 'token:kakao:42:{"provider":"kakao"}');
  });

  test('카카오: 이미 있는 계정은 다시 만들지 않는다', async () => {
    const { auth, created } = fakeAuth({ 'kakao:42': { disabled: false } });
    const r = await socialSignIn(auth, fakeFetch(kakaoOk), { provider: 'kakao', accessToken: tok }, env);
    assert.equal(r.isNew, false);
    assert.equal(created.length, 0);
  });

  test('카카오: 다른 앱에서 받은 토큰 · 앱 ID 설정 없음은 거부', async () => {
    const other = { ...kakaoOk, 'https://kapi.kakao.com/v1/user/access_token_info': { status: 200, body: { id: 42, app_id: 9999 } } };
    await assert.rejects(socialSignIn(fakeAuth().auth, fakeFetch(other), { provider: 'kakao', accessToken: tok }, env), { code: 'permission-denied' });
    await assert.rejects(socialSignIn(fakeAuth().auth, fakeFetch(kakaoOk), { provider: 'kakao', accessToken: tok }, { kakaoAppId: '' }), {
      code: 'failed-precondition',
    });
  });

  test('카카오: 만료된 토큰은 unauthenticated', async () => {
    const bad = { 'https://kapi.kakao.com/v1/user/access_token_info': { status: 401, body: { code: -401 } } };
    await assert.rejects(socialSignIn(fakeAuth().auth, fakeFetch(bad), { provider: 'kakao', accessToken: tok }, env), { code: 'unauthenticated' });
  });

  test('네이버: resultcode 00이면 naver:{id}, 닉네임이 없으면 기본 이름', async () => {
    const { auth, created } = fakeAuth();
    const f = fakeFetch({ 'https://openapi.naver.com/v1/nid/me': { status: 200, body: { resultcode: '00', response: { id: 'abcDEF' } } } });
    const r = await socialSignIn(auth, f, { provider: 'naver', accessToken: tok }, env);
    assert.equal(r.uid, 'naver:abcDEF');
    assert.deepEqual(created, [{ uid: 'naver:abcDEF', displayName: '네이버 이웃' }]);
  });

  test('네이버: 실패 응답 · 만료', async () => {
    const fail = fakeFetch({ 'https://openapi.naver.com/v1/nid/me': { status: 200, body: { resultcode: '024', message: 'fail' } } });
    await assert.rejects(socialSignIn(fakeAuth().auth, fail, { provider: 'naver', accessToken: tok }, env), { code: 'unavailable' });
    const exp = fakeFetch({ 'https://openapi.naver.com/v1/nid/me': { status: 401, body: {} } });
    await assert.rejects(socialSignIn(fakeAuth().auth, exp, { provider: 'naver', accessToken: tok }, env), { code: 'unauthenticated' });
  });

  test('정지된 계정 · 잘못된 요청', async () => {
    const { auth } = fakeAuth({ 'kakao:42': { disabled: true } });
    await assert.rejects(socialSignIn(auth, fakeFetch(kakaoOk), { provider: 'kakao', accessToken: tok }, env), { code: 'permission-denied' });
    await assert.rejects(socialSignIn(auth, fakeFetch({}), { provider: 'google', accessToken: tok }, env), { code: 'invalid-argument' });
    await assert.rejects(socialSignIn(auth, fakeFetch({}), { provider: 'naver', accessToken: '' }, env), { code: 'invalid-argument' });
  });

  test('이름은 20자까지', () => {
    assert.equal(cleanName('가'.repeat(30), 'kakao').length, 20);
    assert.equal(cleanName(null, 'kakao'), '카카오 이웃');
  });
});
