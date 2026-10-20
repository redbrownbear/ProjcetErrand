/**
 * 지원서·거래 문서가 바뀌었을 때 "누구에게 어떤 알림을 보낼지"를 정한다.
 * Firestore·FCM을 모르는 순수 함수라 단위 테스트로 확인한다(test/unit/events.test.ts).
 *
 * 1차 알림은 거래에 필요한 것만 보낸다(설계 W4). 마케팅성 알림은 없다.
 */

export type NotifyKind =
  | 'application.new'
  | 'application.withdrawn'
  | 'application.accepted'
  | 'application.rejected'
  | 'trade.started'
  | 'trade.revise'
  | 'trade.confirmRequested'
  | 'trade.completed'
  | 'trade.cancelled'
  | 'chat.message'
  | 'request.comment';

export interface NotifyEvent {
  to: string;
  kind: NotifyKind;
  title: string;
  body: string;
  requestId: string;
  tradeId?: string;
}

type Doc = Record<string, unknown> | undefined;

const str = (d: Doc, k: string, fallback = ''): string => (typeof d?.[k] === 'string' ? (d[k] as string) : fallback);
const quote = (title: string) => (title ? `"${title.length > 20 ? title.slice(0, 20) + '…' : title}"` : '부탁');

/** requests/{requestId}/applications/{helperUid} 변경 */
export function applicationEvents(requestId: string, before: Doc, after: Doc): NotifyEvent[] {
  if (!after) return [];
  const prev = str(before, 'status');
  const next = str(after, 'status');
  if (prev === next) return [];
  const helper = str(after, 'helperUid');
  const requester = str(after, 'requesterUid');
  const title = quote(str(after, 'requestTitle'));
  const name = str(after, 'helperName', '이웃');
  // '가는 김에 · 제가 가요' 글에 온 신청은 지원이 아니라 부탁이다(신청자가 부탁하는 쪽)
  const giving = str(after, 'requestMode') === 'going';
  const w = giving ? '부탁' : '지원';

  switch (next) {
    case 'pending':
      return requester
        ? [{ to: requester, kind: 'application.new', title: `새 ${w}이 왔어요`, body: giving ? `${name}님이 ${title} 글에 부탁을 보냈어요` : `${name}님이 ${title}에 지원했어요`, requestId }]
        : [];
    case 'withdrawn':
      return requester && prev === 'pending'
        ? [{ to: requester, kind: 'application.withdrawn', title: `${w}이 취소됐어요`, body: `${name}님이 ${title} ${w}을 취소했어요`, requestId }]
        : [];
    case 'accepted':
      return [
        {
          to: helper,
          kind: 'application.accepted',
          title: `${w}이 수락됐어요`,
          body: giving ? `${title} 글쓴이가 부탁을 맡아 줘요. 채팅으로 이야기해 보세요` : `${title} 부탁을 시작할 수 있어요`,
          requestId,
          tradeId: str(after, 'tradeId') || undefined,
        },
      ];
    case 'rejected':
      return prev === 'pending'
        ? [{ to: helper, kind: 'application.rejected', title: `${w} 결과를 알려 드려요`, body: `${title} ${giving ? '글의 부탁' : '부탁'}은 이번에 함께하지 못하게 됐어요`, requestId }]
        : [];
    default:
      return []; // cancelled(수락 뒤 취소)는 거래 쪽 알림이 보낸다
  }
}

/** trades/{tradeId} 변경. 거래가 생길 때(matched)는 지원 수락 알림이 대신한다. */
export function tradeEvents(tradeId: string, before: Doc, after: Doc): NotifyEvent[] {
  if (!before || !after) return [];
  const prev = str(before, 'status');
  const next = str(after, 'status');
  if (prev === next) return [];
  const requester = str(after, 'requesterUid');
  const helper = str(after, 'helperUid');
  const requestId = str(after, 'requestId');
  const title = quote(str(after, 'title'));
  const base = { requestId, tradeId };

  if (next === 'working' && prev === 'matched') {
    return [{ ...base, to: requester, kind: 'trade.started', title: '부탁이 시작됐어요', body: `수행자가 ${title} 부탁을 시작했어요` }];
  }
  if (next === 'working' && prev === 'confirmation') {
    return [{ ...base, to: helper, kind: 'trade.revise', title: '보완 요청이 왔어요', body: `요청자가 ${title} 결과의 보완을 요청했어요` }];
  }
  if (next === 'confirmation') {
    return [{ ...base, to: requester, kind: 'trade.confirmRequested', title: '완료 확인을 기다려요', body: `${title} 결과를 확인하고 완료를 눌러 주세요` }];
  }
  if (next === 'completed') {
    return [{ ...base, to: helper, kind: 'trade.completed', title: '완료가 확인됐어요', body: `${title} 부탁이 끝났어요. 수고하셨어요` }];
  }
  if (next === 'cancelled') {
    const by = str(after, 'cancelledBy');
    const to = by === 'helper' ? requester : helper;
    const who = by === 'helper' ? '수행자' : '요청자';
    return [{ ...base, to, kind: 'trade.cancelled', title: '거래가 취소됐어요', body: `${who}가 ${title} 거래를 시작 전에 취소했어요` }];
  }
  return [];
}
