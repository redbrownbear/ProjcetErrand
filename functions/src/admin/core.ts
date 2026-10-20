/**
 * 운영자 작업(W5). 운영자는 Auth 사용자 정보에 role=admin(custom claim)이 있는 계정이다.
 * 지정은 functions/scripts/set-admin.js 로 한다.
 */
import { Firestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

export const REPORT_RESOLUTIONS = ['dismissed', 'warned', 'suspended'] as const;
export type ReportResolution = (typeof REPORT_RESOLUTIONS)[number];

export function assertAdmin(token: Record<string, unknown> | undefined): void {
  if (token?.role !== 'admin') throw new HttpsError('permission-denied', '운영자만 할 수 있어요.');
}

function id(v: unknown, field: string): string {
  if (typeof v !== 'string' || !v || v.length > 128 || v.includes('/')) throw new HttpsError('invalid-argument', `${field} 값이 올바르지 않아요.`);
  return v;
}

/** 이용 정지·해제. 정지된 계정은 지원·수락 등 모든 거래 함수가 거부된다(errand/core.ts). */
export async function setSuspended(db: Firestore, adminUid: string, data: unknown) {
  const input = (data ?? {}) as Record<string, unknown>;
  const uid = id(input.uid, 'uid');
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

/** 신고 처리 결과 기록. 'suspended'면 대상 계정을 정지한다. */
export async function resolveReport(db: Firestore, adminUid: string, data: unknown) {
  const input = (data ?? {}) as Record<string, unknown>;
  const reportId = id(input.reportId, 'reportId');
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
  return { reportId, resolution };
}
