/**
 * 올라온 부탁 글 검사(A20). 앱이 부탁 글을 직접 쓰므로(보안 규칙) 저장된 뒤 트리거가 본다.
 * 금지 품목이 있거나 물건값이 상한을 넘으면 글을 숨기고(status 'hidden') 글쓴이에게 이유를 알린다.
 * 숨긴 글은 공개 목록(status 'open')에서 빠지고, 글쓴이가 고칠 수도 없다(규칙: open일 때만 수정) — 다시 올려야 한다.
 */
import { Firestore, Timestamp } from 'firebase-admin/firestore';

import { deliver, PushSender } from '../notify/deliver';
import { loadPolicy, requestViolation } from './policy';

type Doc = Record<string, unknown> | undefined;

const WATCHED = ['title', 'desc', 'budget', 'mode'];

export async function screenRequest(db: Firestore, requestId: string, before: Doc, after: Doc, push?: PushSender): Promise<string | null> {
  if (!after || after.status !== 'open') return null;
  if (before && before.status === 'open' && WATCHED.every((k) => before[k] === after[k])) return null;
  const reason = requestViolation(after, await loadPolicy(db));
  if (!reason) return null;

  const ref = db.collection('requests').doc(requestId);
  const hidden = await db.runTransaction(async (tx) => {
    const cur = await tx.get(ref);
    if (!cur.exists || cur.get('status') !== 'open') return false;
    tx.update(ref, { status: 'hidden', hiddenReason: reason, hiddenAt: Timestamp.now() });
    return true;
  });
  if (!hidden) return null;

  const owner = typeof after.ownerUid === 'string' ? after.ownerUid : '';
  const title = typeof after.title === 'string' && after.title ? after.title : '부탁';
  const short = title.length > 20 ? title.slice(0, 20) + '…' : title;
  if (owner && push) {
    await deliver(
      db,
      push,
      { to: owner, kind: 'request.hidden', title: `"${short}" 글을 내렸어요`, body: `${reason} 내용을 고쳐 다시 올려 주세요.`, requestId },
      `hidden_${requestId}`,
    );
  }
  return reason;
}
