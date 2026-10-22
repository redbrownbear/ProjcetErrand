/**
 * 금지 품목 · 건당 상한 (개발 To-do A20).
 *
 * 값은 Firestore `config/safety` 문서에서 읽고, 없거나 깨졌으면 아래 기본값을 쓴다.
 * 실제 금지 목록 · 금액은 법인 결정(C07 · C09)으로 정해지면 **코드 배포 없이** 그 문서만 고친다.
 *
 * ```
 * config/safety {
 *   blockedWords: string[]   // 띄어쓰기 · 대소문자를 무시하고 포함 여부로 본다
 *   maxItemPrice: number     // 국내 · 가는 김에 건당 물건값(원)
 *   maxItemPriceSea: number  // 해외 사다주기 건당 물건값(원)
 * }
 * ```
 *
 * 쓰는 곳: 부탁 글이 올라오거나 고쳐질 때(onRequestWrite → 숨김 + 알림), 가는 김에 신청(applyToRequest), 댓글(addComment).
 * 앱도 같은 기본값으로 올리기 전에 미리 막는다(lib/core/compliance/safety_policy.dart) — 최종 판단은 여기다.
 */
import { Firestore } from 'firebase-admin/firestore';

export interface SafetyPolicy {
  blockedWords: string[];
  maxItemPrice: number;
  maxItemPriceSea: number;
}

/**
 * 기본 금지어. '술' · '약'처럼 짧은 말은 '기술' · '예약'까지 걸려서 넣지 않고 물건 이름으로 적는다.
 * 법률 검토 L-050~056 · L-061: 주류 · 담배 · 의약품 · 복권 · 현금/카드 전달.
 */
export const DEFAULT_POLICY: SafetyPolicy = {
  blockedWords: [
    '소주', '맥주', '와인', '막걸리', '양주', '위스키', '보드카', '사케', '하이볼', '주류',
    '담배', '전자담배', '궐련', '액상', '니코틴',
    '의약품', '처방약', '처방전', '감기약', '해열제', '진통제', '수면제', '타이레놀', '마약', '대마',
    '복권', '로또', '현금전달', '현금배달', '카드전달',
  ],
  maxItemPrice: 50_000,
  maxItemPriceSea: 100_000,
};

const CACHE_MS = 5 * 60 * 1000;
let cache: { at: number; policy: SafetyPolicy } | null = null;

export function resetPolicyCache() {
  cache = null;
}

function words(v: unknown): string[] | null {
  if (!Array.isArray(v)) return null;
  const out = v.filter((w): w is string => typeof w === 'string' && w.trim().length >= 2).map((w) => w.trim());
  return out.length ? out : null;
}

function price(v: unknown): number | null {
  return typeof v === 'number' && Number.isInteger(v) && v > 0 ? v : null;
}

export async function loadPolicy(db: Firestore): Promise<SafetyPolicy> {
  if (cache && Date.now() - cache.at < CACHE_MS) return cache.policy;
  let policy = DEFAULT_POLICY;
  try {
    const d = (await db.collection('config').doc('safety').get()).data();
    if (d) {
      policy = {
        blockedWords: words(d.blockedWords) ?? DEFAULT_POLICY.blockedWords,
        maxItemPrice: price(d.maxItemPrice) ?? DEFAULT_POLICY.maxItemPrice,
        maxItemPriceSea: price(d.maxItemPriceSea) ?? DEFAULT_POLICY.maxItemPriceSea,
      };
    }
  } catch {
    // 설정을 못 읽어도 기본값으로 막는다
  }
  cache = { at: Date.now(), policy };
  return policy;
}

const squash = (s: string) => s.replace(/\s+/g, '').toLowerCase();

/** 글에 들어 있는 첫 금지어. 없으면 null */
export function findBlocked(text: string, policy: SafetyPolicy): string | null {
  const t = squash(text);
  if (!t) return null;
  for (const w of policy.blockedWords) {
    if (t.includes(squash(w))) return w;
  }
  return null;
}

export const blockedMessage = (word: string) => `'${word}'처럼 부탁할 수 없는 물건(주류 · 담배 · 의약품 · 복권 · 현금)이 들어 있어요.`;

/** 부탁 글 하나를 검사해 숨겨야 할 이유를 돌려준다. 문제없으면 null */
export function requestViolation(d: Record<string, unknown>, policy: SafetyPolicy): string | null {
  const text = ['title', 'desc'].map((k) => (typeof d[k] === 'string' ? (d[k] as string) : '')).join(' ');
  const word = findBlocked(text, policy);
  if (word) return blockedMessage(word);
  const sea = d.mode === 'sea';
  const max = sea ? policy.maxItemPriceSea : policy.maxItemPrice;
  const budget = d.budget;
  if (typeof budget === 'number' && budget > max) {
    return `물건값은 건당 ${max.toLocaleString('ko-KR')}원까지 부탁할 수 있어요.`;
  }
  return null;
}
