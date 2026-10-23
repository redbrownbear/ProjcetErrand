/** 거래 · 댓글 · 제안 함수가 공통으로 보는 사용자 상태(정지 · 차단) */
import { DocumentSnapshot, Firestore, Transaction } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

export const userRef = (db: Firestore, uid: string) => db.collection('users').doc(uid);

/** 정지된 계정이면 거부. [who]는 문구의 주어('내' · '상대방') */
export function assertNotSuspended(user: DocumentSnapshot, who = '내'): void {
  if (user.get('suspended') === true) throw new HttpsError('permission-denied', `${who} 계정은 지금 이용이 제한돼 있어요.`);
}

/** 사용자 문서를 읽고 정지 여부를 본다. 닉네임 등 다른 값도 쓰려고 문서를 돌려준다 */
export async function activeUser(tx: Transaction, db: Firestore, uid: string, who = '내'): Promise<DocumentSnapshot> {
  const snap = await tx.get(userRef(db, uid));
  assertNotSuspended(snap, who);
  return snap;
}

/** 둘 중 한 사람이라도 상대를 차단했으면 거부 */
export async function assertNotBlocked(
  tx: Transaction,
  db: Firestore,
  a: string,
  b: string,
  message = '차단 관계인 사용자와는 거래할 수 없어요.',
): Promise<void> {
  const block = (owner: string, target: string) => userRef(db, owner).collection('blocks').doc(target);
  const [ab, ba] = await Promise.all([tx.get(block(a, b)), tx.get(block(b, a))]);
  if (ab.exists || ba.exists) throw new HttpsError('permission-denied', message);
}

/** 닉네임(20자). 없으면 '이웃' */
export function nicknameOf(user: DocumentSnapshot): string {
  const n = user.get('nickname');
  return typeof n === 'string' && n.trim() ? n.trim().slice(0, 20) : '이웃';
}
