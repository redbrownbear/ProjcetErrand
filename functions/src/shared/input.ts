/** 앱이 보낸 값 검사 — 여러 모듈이 같이 쓰는 것만 */
import { HttpsError } from 'firebase-functions/v2/https';

/** 요청 본문을 필드 묶음으로. 객체가 아니면 빈 묶음 — 필요한 필드 검사에서 걸린다 */
export function fields(data: unknown): Record<string, unknown> {
  return typeof data === 'object' && data !== null ? (data as Record<string, unknown>) : {};
}

/** 문서 id(부탁 · 거래 · 사용자). 경로를 넘나들지 못하게 '/'를 막는다 */
export function docId(v: unknown, field: string): string {
  if (typeof v !== 'string' || v.length === 0 || v.length > 128 || v.includes('/')) {
    throw new HttpsError('invalid-argument', `${field} 값이 올바르지 않아요.`);
  }
  return v;
}

/** 내 폴더(`trades/{tradeId}/{uid}/파일`)에 올린 Storage 파일인가 — 남의 사진 경로를 끌어오지 못하게 */
export function ownPhotoPath(v: unknown, tradeId: string, uid: string): string {
  const prefix = `trades/${tradeId}/${uid}/`;
  if (typeof v !== 'string' || !v.startsWith(prefix) || v.length > 300 || v.slice(prefix.length).includes('/') || v.includes('..')) {
    throw new HttpsError('invalid-argument', '사진 경로가 올바르지 않아요.');
  }
  return v;
}
