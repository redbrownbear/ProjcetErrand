/**
 * 신고 자동 분류 · 1차 자동 응대(개발 To-do A34).
 *
 * 신고가 접수되면(onReportCreate) 사유 · 내용으로 유형(category)과 긴급도(priority)를 붙이고,
 * 신고한 사람에게 유형에 맞는 1차 안내를 보낸다. 처리(경고 · 정지)는 하지 않는다 — 그건 운영자가 정한다.
 *
 * reports/{id} 에 서버가 더하는 값: category, priority(urgent | high | normal), signals(분류 근거), repeatCount, triagedAt
 *   repeatCount = 최근 7일 같은 사람을 신고한 서로 다른 사람 수(이번 신고 포함). 3명 이상이면 high 이상
 */
import { Firestore, Timestamp } from 'firebase-admin/firestore';

import { deliver, PushSender } from '../notify/deliver';
import { findBlocked, loadPolicy } from '../safety/policy';
import { C } from '../shared/paths';

export type ReportCategory = 'prohibited' | 'fraud' | 'noshow' | 'abuse' | 'offplatform' | 'other';
export type ReportPriority = 'urgent' | 'high' | 'normal';

/** 앱 신고 시트의 사유(report_sheet.dart)와 같은 문구 */
const REASONS: Record<string, ReportCategory> = {
  '금지 품목·불법 부탁': 'prohibited',
  '사기·결제 유도 의심': 'fraud',
  '노쇼·약속 불이행': 'noshow',
  '욕설·위협·불쾌한 행동': 'abuse',
  '연락처·외부 거래 유도': 'offplatform',
  '기타': 'other',
};

/** 사람이 다칠 수 있는 말 — 유형과 상관없이 가장 먼저 본다 */
const DANGER = ['협박', '위협', '죽이', '죽여', '때리', '때렸', '폭행', '스토킹', '따라와', '쫓아', '성희롱', '성추행', '몸캠', '미성년'];
const FRAUD = ['송금', '입금', '선입금', '계좌', '먹튀', '돈만', '환불 안', '사기'];
const OFFPLATFORM = ['카톡', '카카오톡', '텔레그램', '오픈채팅', '전화번호', '번호 알려'];
const NOSHOW = ['노쇼', '안 나왔', '안나왔', '잠수', '연락 두절', '연락이 안'];

export const REPEAT_DAYS = 7;
export const REPEAT_HIGH = 3;

const squash = (s: string) => s.replace(/\s+/g, '');
const hits = (text: string, words: string[]) => words.filter((w) => squash(text).includes(squash(w)));

export interface Triage {
  category: ReportCategory;
  priority: ReportPriority;
  signals: string[];
}

/** 사유 · 내용 · 같은 사람에게 온 신고 수로 분류한다. blockedWord = 내용에서 찾은 금지 품목 */
export function classify(reason: string, detail: string, repeatCount: number, blockedWord: string | null = null): Triage {
  let category = REASONS[reason] ?? 'other';
  const signals: string[] = [`사유: ${reason}`];
  const danger = hits(detail, DANGER);
  if (danger.length) signals.push(`위험한 말: ${danger.join(', ')}`);
  if (blockedWord) signals.push(`금지 품목: ${blockedWord}`);
  // '기타'로 온 신고는 내용으로 유형을 다시 본다
  if (category === 'other') {
    if (danger.length) category = 'abuse';
    else if (blockedWord) category = 'prohibited';
    else if (hits(detail, FRAUD).length) category = 'fraud';
    else if (hits(detail, OFFPLATFORM).length) category = 'offplatform';
    else if (hits(detail, NOSHOW).length) category = 'noshow';
    if (category !== 'other') signals.push(`내용으로 분류: ${CATEGORY_LABEL[category]}`);
  }
  if (repeatCount >= REPEAT_HIGH) signals.push(`최근 ${REPEAT_DAYS}일 ${repeatCount}명이 신고`);
  const priority: ReportPriority = danger.length
    ? 'urgent'
    : category === 'fraud' || category === 'prohibited' || category === 'abuse' || repeatCount >= REPEAT_HIGH
      ? 'high'
      : 'normal';
  return { category, priority, signals };
}

export const CATEGORY_LABEL: Record<ReportCategory, string> = {
  prohibited: '금지 품목',
  fraud: '사기 의심',
  noshow: '노쇼 · 약속',
  abuse: '욕설 · 위협',
  offplatform: '외부 거래 유도',
  other: '기타',
};

/** 신고한 사람에게 보내는 1차 안내. 앱이 하지 않는 일(결제 보관 · 환불 · 처리 시한)은 약속하지 않는다 */
export function firstReply(t: Triage): { title: string; body: string } {
  const tail = ' 운영자가 확인하면 다시 알려 드릴게요.';
  if (t.priority === 'urgent') {
    return { title: '신고를 받았어요 · 먼저 안전을 챙기세요', body: '위험을 느끼면 바로 112에 신고하세요. 상대를 차단하면 더는 연락이 오지 않아요.' + tail };
  }
  const body: Record<ReportCategory, string> = {
    prohibited: '금지 품목은 사거나 전달하지 마세요. 글은 운영자가 확인해서 내릴 수 있어요.',
    fraud: '앱 밖 송금이나 선입금 요구엔 응하지 마세요. 겸사겸사엔 앱 안 결제가 없어서 만나서 물건을 확인하고 주고받아요.',
    noshow: '채팅 · 사진 기록은 지우지 말고 남겨 두세요. 시작 전인 거래는 진행 중인 부탁에서 취소할 수 있어요.',
    abuse: '불쾌한 일을 겪게 해 미안해요. 상대를 차단하면 더는 연락이 오지 않아요.',
    offplatform: '외부 메신저나 개인 연락처로 옮기자는 요청엔 응하지 않는 게 안전해요. 채팅의 전화번호 · 계좌번호는 자동으로 가려져요.',
    other: '보내 주신 내용을 운영자가 살펴볼게요.',
  };
  return { title: '신고를 받았어요', body: body[t.category] + tail };
}

/** 새 신고 한 건을 분류하고 1차 안내를 보낸다. 이미 분류한 신고는 건너뛴다 */
export async function triageReport(db: Firestore, reportId: string, push?: PushSender, now = Date.now()) {
  const ref = db.collection(C.reports).doc(reportId);
  const snap = await ref.get();
  if (!snap.exists || snap.get('triagedAt')) return null;
  const reason = typeof snap.get('reason') === 'string' ? (snap.get('reason') as string) : '기타';
  const detail = typeof snap.get('detail') === 'string' ? (snap.get('detail') as string) : '';
  const target = snap.get('targetUid');
  const reporter = snap.get('reporterUid');

  let repeatCount = 1;
  if (typeof target === 'string' && target) {
    const since = now - REPEAT_DAYS * 86_400_000;
    const recent = await db.collection(C.reports).where('targetUid', '==', target).limit(200).get();
    const who = new Set<string>();
    for (const d of recent.docs) {
      const at = d.get('createdAt');
      if (at instanceof Timestamp && at.toMillis() < since) continue;
      const r = d.get('reporterUid');
      if (typeof r === 'string') who.add(r);
    }
    if (typeof reporter === 'string') who.add(reporter);
    repeatCount = who.size;
  }

  const blocked = detail ? findBlocked(detail, await loadPolicy(db)) : null;
  const t = classify(reason, detail, repeatCount, blocked);
  await ref.update({ ...t, repeatCount, triagedAt: Timestamp.fromMillis(now) });

  if (push && typeof reporter === 'string' && reporter) {
    const requestId = typeof snap.get('requestId') === 'string' ? (snap.get('requestId') as string) : '';
    await deliver(db, push, { to: reporter, kind: 'report.received', ...firstReply(t), requestId }, `received_${reportId}`);
  }
  return { ...t, repeatCount };
}
