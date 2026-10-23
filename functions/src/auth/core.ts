/**
 * 카카오 · 네이버 로그인(소셜 로그인).
 *
 * 앱이 각 회사 SDK로 받은 액세스 토큰을 보내면, 서버가 그 회사 API로 토큰을 확인하고 사용자 번호를 받아
 * Firebase 커스텀 토큰을 만들어 준다. 앱은 그 토큰으로 signInWithCustomToken — 그 뒤로는 이메일 로그인과 같다.
 *
 * - uid: 'kakao:{회원번호}' · 'naver:{고유 식별자}'. 두 번호 모두 우리 앱(카카오 앱 · 네이버 애플리케이션)에 묶인 값이라
 *   다른 앱이 받은 토큰으로는 같은 uid가 나오지 않는다. 카카오는 토큰이 우리 앱 것인지(app_id)도 한 번 더 본다.
 * - 이메일은 Auth 계정에 넣지 않는다 — 같은 이메일로 만든 이메일 계정과 부딪히고, 로그인에 필요하지 않다.
 *   이름(닉네임)만 처음 만들 때 넣는다. 그 뒤 앱에서 바꾼 이름을 덮어쓰지 않는다.
 * - 약관 동의는 앱의 동의 화면(ConsentGateScreen)이 로그인 뒤에 받는다(필수 동의가 없는 계정).
 */
import { HttpsError } from 'firebase-functions/v2/https';

export type SocialProvider = 'kakao' | 'naver';

export interface SocialProfile {
  provider: SocialProvider;
  /** 그 회사가 준 사용자 번호(문자열) */
  id: string;
  nickname: string;
}

/** fetch를 바꿔 끼울 수 있게(테스트) */
export type Fetch = (url: string, init: { headers: Record<string, string> }) => Promise<{ status: number; json(): Promise<unknown> }>;

const NAME_MAX = 20;

export function parseRequest(data: unknown): { provider: SocialProvider; accessToken: string } {
  const d = (data ?? {}) as Record<string, unknown>;
  const provider = d.provider;
  const token = d.accessToken;
  if (provider !== 'kakao' && provider !== 'naver') throw new HttpsError('invalid-argument', '지원하지 않는 로그인 방식이에요.');
  if (typeof token !== 'string' || token.length < 10 || token.length > 2048) {
    throw new HttpsError('invalid-argument', '로그인 정보가 올바르지 않아요. 다시 시도해 주세요.');
  }
  return { provider, accessToken: token };
}

export const socialUid = (p: SocialProfile) => `${p.provider}:${p.id}`;

/** 닉네임 정리 — 비었으면 '카카오 이웃' 같은 기본 이름 */
export function cleanName(raw: unknown, provider: SocialProvider): string {
  const s = typeof raw === 'string' ? raw.replace(/\s+/g, ' ').trim() : '';
  if (!s) return provider === 'kakao' ? '카카오 이웃' : '네이버 이웃';
  return [...s].slice(0, NAME_MAX).join('');
}

const expired = () => new HttpsError('unauthenticated', '로그인이 만료됐어요. 다시 시도해 주세요.');
const unreachable = (who: string) => new HttpsError('unavailable', `${who} 서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.`);

async function getJson(fetch: Fetch, url: string, token: string, who: string): Promise<{ status: number; body: Record<string, unknown> }> {
  let res;
  try {
    res = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
  } catch {
    throw unreachable(who);
  }
  const body = ((await res.json().catch(() => ({}))) ?? {}) as Record<string, unknown>;
  return { status: res.status, body };
}

/**
 * 카카오: 토큰 정보(app_id 확인) → 사용자 정보.
 * [appId]는 카카오 디벨로퍼스 › 내 애플리케이션 › 앱 ID(숫자). 비어 있으면 로그인을 막는다(다른 앱 토큰을 받지 않으려고).
 */
export async function kakaoProfile(fetch: Fetch, token: string, appId: string): Promise<SocialProfile> {
  if (!appId) throw new HttpsError('failed-precondition', '카카오 로그인이 아직 준비되지 않았어요.');
  const info = await getJson(fetch, 'https://kapi.kakao.com/v1/user/access_token_info', token, '카카오');
  if (info.status === 401) throw expired();
  if (info.status !== 200) throw unreachable('카카오');
  if (String(info.body.app_id ?? '') !== appId) throw new HttpsError('permission-denied', '이 앱에서 받은 카카오 로그인이 아니에요.');
  const me = await getJson(fetch, 'https://kapi.kakao.com/v2/user/me', token, '카카오');
  if (me.status === 401) throw expired();
  if (me.status !== 200 || me.body.id == null) throw unreachable('카카오');
  const account = (me.body.kakao_account ?? {}) as Record<string, unknown>;
  const profile = (account.profile ?? {}) as Record<string, unknown>;
  const props = (me.body.properties ?? {}) as Record<string, unknown>;
  return { provider: 'kakao', id: String(me.body.id), nickname: cleanName(profile.nickname ?? props.nickname, 'kakao') };
}

/** 네이버: 회원 프로필 조회(resultcode '00'). id는 네이버 애플리케이션마다 다르게 발급된다 */
export async function naverProfile(fetch: Fetch, token: string): Promise<SocialProfile> {
  const me = await getJson(fetch, 'https://openapi.naver.com/v1/nid/me', token, '네이버');
  if (me.status === 401) throw expired();
  const r = (me.body.response ?? {}) as Record<string, unknown>;
  if (me.status !== 200 || me.body.resultcode !== '00' || typeof r.id !== 'string' || !r.id) throw unreachable('네이버');
  return { provider: 'naver', id: r.id, nickname: cleanName(r.nickname ?? r.name, 'naver') };
}

/** Auth 계정 쪽에 필요한 것만 — firebase-admin Auth를 바꿔 끼울 수 있게(테스트) */
export interface AuthLike {
  getUser(uid: string): Promise<{ disabled: boolean }>;
  createUser(p: { uid: string; displayName: string }): Promise<unknown>;
  createCustomToken(uid: string, claims?: object): Promise<string>;
}

/** 토큰 확인 → 계정이 없으면 만든다 → 커스텀 토큰. isNew면 앱이 첫 로그인 안내를 할 수 있다 */
export async function socialSignIn(
  auth: AuthLike,
  fetch: Fetch,
  data: unknown,
  env: { kakaoAppId: string },
): Promise<{ token: string; uid: string; isNew: boolean }> {
  const req = parseRequest(data);
  const profile = req.provider === 'kakao' ? await kakaoProfile(fetch, req.accessToken, env.kakaoAppId) : await naverProfile(fetch, req.accessToken);
  const uid = socialUid(profile);
  let isNew = false;
  try {
    const user = await auth.getUser(uid);
    if (user.disabled) throw new HttpsError('permission-denied', '사용이 제한된 계정이에요.');
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    if ((e as { code?: string }).code !== 'auth/user-not-found') throw e;
    await auth.createUser({ uid, displayName: profile.nickname });
    isNew = true;
  }
  const token = await auth.createCustomToken(uid, { provider: profile.provider });
  return { token, uid, isNew };
}
