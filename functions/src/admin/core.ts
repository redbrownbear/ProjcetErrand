/**
 * 운영자 작업(W5). 운영자는 Auth 사용자 정보에 role=admin(custom claim)이 있는 계정이다.
 * 지정은 functions/scripts/set-admin.js 로 한다.
 */
import { Firestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { deliver, PushSender } from '../notify/deliver';
import { docId, fields } from '../shared/input';

export const REPORT_RESOLUTIONS = ['dismissed', 'warned', 'suspended'] as const;
export type ReportResolution = (typeof REPORT_RESOLUTIONS)[number];

export function assertAdmin(token: Record<string, unknown> | undefined): void {
  if (token?.role !== 'admin') throw new HttpsError('permission-denied', '운영자만 할 수 있어요.');
}

/** 이용 정지·해제. 정지된 계정은 지원·수락 등 모든 거래 함수가 거부된다(errand/core.ts). */
export async function setSuspended(db: Firestore, adminUid: string, data: unknown) {
  const input = fields(data);
  const uid = docId(input.uid, 'uid');
  if (typeof input.suspended !== 'boolean') throw new HttpsError('invalid-argument', 'suspended 값이 필요해요.');
  const reason = typeof input.reason === 'string' ? input.reason.slice(0, 200) : null;
  const now = Timestamp.now();
  await db.collection('users').doc(uid).set(
    { suspended: input.suspended, suspendedAt: input.suspended ? now : null, suspendReason: input.suspended ? reason : null },
    { merge: true },
  );
  await db.collection('adminLog').add({ action: 'setSuspended', by: adminUid, uid, suspended: input.suspended, reason, at: now });
  return { uid, suspended: input.suspended };
}

const RESOLUTION_LABEL: Record<ReportResolution, string> = { dismissed: '문제 없음', warned: '경고', suspended: '이용 정지' };

/**
 * 신고 처리 결과 기록. 'suspended'면 대상 계정을 정지한다.
 * 'warned'면 대상에게 경고 알림, 신고한 사람에게는 처리됐다는 알림을 보낸다(처리 결과의 자세한 내용은 알리지 않는다).
 * 이미 처리한 신고를 다시 처리하면 결과를 고쳐 쓴다(알림은 처음 한 번만 — 같은 eventId).
 */
export async function resolveReport(db: Firestore, adminUid: string, data: unknown, push?: PushSender) {
  const input = fields(data);
  const reportId = docId(input.reportId, 'reportId');
  const resolution = input.resolution as ReportResolution;
  if (!REPORT_RESOLUTIONS.includes(resolution)) throw new HttpsError('invalid-argument', 'resolution 값이 올바르지 않아요.');
  const memo = typeof input.memo === 'string' ? input.memo.slice(0, 500) : null;
  const ref = db.collection('reports').doc(reportId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', '신고를 찾을 수 없어요.');
  const now = Timestamp.now();
  await ref.update({ status: 'resolved', resolution, memo, resolvedBy: adminUid, resolvedAt: now });
  const target = snap.get('targetUid');
  if (resolution === 'suspended' && typeof target === 'string' && target) {
    await setSuspended(db, adminUid, { uid: target, suspended: true, reason: `신고 ${reportId}` });
  }
  await db.collection('adminLog').add({ action: 'resolveReport', by: adminUid, reportId, resolution, at: now });

  if (push) {
    const requestId = typeof snap.get('requestId') === 'string' ? (snap.get('requestId') as string) : '';
    const reporter = snap.get('reporterUid');
    if (resolution === 'warned' && typeof target === 'string' && target) {
      await deliver(
        db,
        push,
        {
          to: target,
          kind: 'report.warned',
          title: '운영 정책 경고를 받았어요',
          body: '신고가 접수돼 확인했어요. 같은 일이 반복되면 이용이 정지될 수 있어요.',
          requestId,
        },
        `warned_${reportId}`,
      );
    }
    if (typeof reporter === 'string' && reporter) {
      await deliver(
        db,
        push,
        { to: reporter, kind: 'report.resolved', title: '신고를 확인했어요', body: '보내 주신 신고를 운영자가 확인하고 처리했어요. 고마워요.', requestId },
        `resolved_${reportId}`,
      );
    }
  }
  return { reportId, resolution, label: RESOLUTION_LABEL[resolution] };
}

/**
 * 운영자가 부탁 글을 내리거나(hidden) 되돌린다. 금지 품목 검사(safety/screen.ts)와 같은 status 'hidden'을 쓰고,
 * 운영자가 내린 글만 hiddenBy='admin'과 원래 상태(hiddenFrom)를 남겨 되돌릴 수 있다.
 * 되돌린 글은 onRequestWrite가 다시 검사한다(금지 품목이면 다시 내려간다).
 */
export async function setRequestHidden(db: Firestore, adminUid: string, data: unknown, push?: PushSender) {
  const input = fields(data);
  const requestId = docId(input.requestId, 'requestId');
  if (typeof input.hidden !== 'boolean') throw new HttpsError('invalid-argument', 'hidden 값이 필요해요.');
  const hide = input.hidden;
  const reason = typeof input.reason === 'string' && input.reason.trim() ? input.reason.trim().slice(0, 200) : '운영 정책에 맞지 않아';
  const ref = db.collection('requests').doc(requestId);
  const now = Timestamp.now();

  const result = await db.runTransaction(async (tx) => {
    const cur = await tx.get(ref);
    if (!cur.exists) throw new HttpsError('not-found', '부탁을 찾을 수 없어요.');
    const status = cur.get('status');
    if (hide) {
      if (status === 'hidden') return { changed: false, owner: cur.get('ownerUid'), title: cur.get('title') };
      tx.update(ref, { status: 'hidden', hiddenReason: reason, hiddenAt: now, hiddenBy: 'admin', hiddenFrom: status ?? 'open' });
    } else {
      if (status !== 'hidden') return { changed: false, owner: cur.get('ownerUid'), title: cur.get('title') };
      if (cur.get('hiddenBy') !== 'admin') throw new HttpsError('failed-precondition', '금지 품목 검사로 내려간 글은 되돌릴 수 없어요. 글쓴이가 고쳐 다시 올려야 해요.');
      const from = cur.get('hiddenFrom');
      tx.update(ref, {
        status: typeof from === 'string' && from ? from : 'open',
        hiddenReason: null,
        hiddenAt: null,
        hiddenBy: null,
        hiddenFrom: null,
      });
    }
    return { changed: true, owner: cur.get('ownerUid'), title: cur.get('title') };
  });

  if (result.changed) {
    await db.collection('adminLog').add({ action: 'setRequestHidden', by: adminUid, requestId, hidden: hide, reason: hide ? reason : null, at: now });
  }
  if (result.changed && hide && push && typeof result.owner === 'string' && result.owner) {
    const title = typeof result.title === 'string' && result.title ? result.title : '부탁';
    const short = title.length > 20 ? title.slice(0, 20) + '…' : title;
    await deliver(
      db,
      push,
      { to: result.owner, kind: 'request.hidden', title: `"${short}" 글을 내렸어요`, body: `${reason} 운영자가 글을 내렸어요.`, requestId },
      `adminhide_${requestId}_${now.toMillis()}`,
    );
  }
  return { requestId, hidden: hide, changed: result.changed };
}
