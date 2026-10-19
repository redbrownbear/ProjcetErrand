/** 에뮬레이터 테스트 공용. `npm test`가 firebase emulators:exec 안에서 실행한다. */
import { getApps, initializeApp } from 'firebase-admin/app';
import { Firestore, getFirestore, Timestamp } from 'firebase-admin/firestore';

export const PROJECT = 'demo-gyeomsa';

export function adminDb(): Firestore {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('FIRESTORE_EMULATOR_HOST 없음 — npm test(에뮬레이터)로 실행하세요');
  if (!getApps().length) initializeApp({ projectId: PROJECT });
  return getFirestore();
}

export async function clearDb(): Promise<void> {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  await fetch(`http://${host}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, { method: 'DELETE' });
}

export async function seedRequest(db: Firestore, id: string, ownerUid: string, extra: Record<string, unknown> = {}) {
  const now = Timestamp.now();
  await db.collection('requests').doc(id).set({
    ownerUid,
    who: '요청자',
    mode: 'ask',
    cat: 'pickup',
    title: '편의점 택배 찾아 주세요',
    desc: '',
    price: 3000,
    status: 'open',
    applicantCount: 0,
    deadline: Timestamp.fromMillis(Date.now() + 3_600_000),
    createdAt: now,
    updatedAt: now,
    ...extra,
  });
}

/** HttpsError 코드로 거부됐는지 확인 */
export async function rejectsWith(p: Promise<unknown>, code: string): Promise<void> {
  try {
    await p;
  } catch (e) {
    const got = (e as { code?: string }).code;
    if (got !== code) throw new Error(`예상 코드 ${code}, 실제 ${got}: ${(e as Error).message}`);
    return;
  }
  throw new Error(`${code}로 거부돼야 하는데 성공했다`);
}
