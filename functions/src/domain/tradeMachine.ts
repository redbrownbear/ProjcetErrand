/**
 * 거래 상태 머신 — 앱의 `Trade._transitions`(lib/features/errand/models/trade.dart)를 서버로 옮기고
 * "누가 누를 수 있는가"를 더했다.
 *
 * 지원 대기(pending)는 거래가 아니라 지원서(applications)의 상태라 여기서 빠진다.
 * 거래는 요청자가 지원을 수락한 순간 `matched`로 태어난다.
 *
 *   matched ──start(수행자)──▶ working ──finish(수행자)──▶ confirmation ──confirm(요청자)──▶ completed
 *      │                                                     │
 *      └──cancel(양쪽, 시작 전만)──▶ cancelled                └──revise(요청자)──▶ working
 *
 * 금전 상태(결제·정산)는 일부러 넣지 않는다. 결제가 붙으면 payments/ 를 따로 둔다.
 */

export type TradeStatus = 'matched' | 'working' | 'confirmation' | 'completed' | 'cancelled';
export type TradeAction = 'start' | 'finish' | 'confirm' | 'revise' | 'cancel';
export type TradeRole = 'requester' | 'helper';

interface Edge {
  to: TradeStatus;
  by: readonly TradeRole[];
}

const EDGES: Record<TradeStatus, Partial<Record<TradeAction, Edge>>> = {
  matched: {
    start: { to: 'working', by: ['helper'] },
    cancel: { to: 'cancelled', by: ['helper', 'requester'] },
  },
  working: {
    finish: { to: 'confirmation', by: ['helper'] },
  },
  confirmation: {
    confirm: { to: 'completed', by: ['requester'] },
    revise: { to: 'working', by: ['requester'] },
  },
  completed: {},
  cancelled: {},
};

export const TRADE_ACTIONS: readonly TradeAction[] = ['start', 'finish', 'confirm', 'revise', 'cancel'];

export function isTradeAction(v: unknown): v is TradeAction {
  return typeof v === 'string' && (TRADE_ACTIONS as readonly string[]).includes(v);
}

export function isFinished(s: TradeStatus): boolean {
  return s === 'completed' || s === 'cancelled';
}

export type AdvanceResult =
  | { ok: true; next: TradeStatus }
  | { ok: false; reason: 'not-allowed-now' | 'wrong-role' };

/** 현재 상태에서 [role]이 [action]을 하면 어디로 가는가. 허용되지 않으면 이유를 돌려준다. */
export function advance(current: TradeStatus, action: TradeAction, role: TradeRole): AdvanceResult {
  const edge = EDGES[current]?.[action];
  if (!edge) return { ok: false, reason: 'not-allowed-now' };
  if (!edge.by.includes(role)) return { ok: false, reason: 'wrong-role' };
  return { ok: true, next: edge.to };
}
