/**
 * Firestore 컬렉션 이름을 한곳에. 서버 코드는 문자열 대신 `C.<이름>`을 쓴다 — 오타가 컴파일에서 걸리고,
 * 어떤 컬렉션이 있는지 여기서 한눈에 보인다. 읽기 · 쓰기 권한은 `firebase/firestore.rules`, 앱 쪽 읽기는 `lib/features/<기능>/repositories/`.
 *
 * 이름을 바꾸면 이미 깔린 앱이 옛 이름을 읽으므로 **바꾸지 말고 새로 더한다**.
 */
export const C = {
  // ── 최상위 ──
  /** 사용자 프로필 · 동의 · 포인트 잔액(서버 전용 필드는 규칙이 막는다) */
  users: 'users',
  /** 공개 부탁 글(대략적인 동네만). 정확한 위치는 하위 private/detail */
  requests: 'requests',
  /** 수락 뒤 거래 — 단계 · 마지막 메시지 · 안 읽은 수 */
  trades: 'trades',
  /** 제안하기(A15) */
  proposals: 'proposals',
  /** 신고 — 앱이 만들고, 분류 · 처리는 서버 · 운영자 */
  reports: 'reports',
  /** 공개 완료 기록(A23) — 동네 · 종류 · 시각만 */
  activity: 'activity',
  /** 서버 설정 — safety · matching · points. 콘솔에서 고치면 배포 없이 바로 반영 */
  config: 'config',
  /** 공지(A33) — scripts/post-notice.js */
  notices: 'notices',
  /** 운영자 작업 기록 */
  adminLog: 'adminLog',

  // ── requests/{id} 아래 ──
  applications: 'applications',
  comments: 'comments',
  private: 'private',

  // ── trades/{id} 아래 ──
  messages: 'messages',
  photos: 'photos',

  // ── proposals/{id} 아래 ──
  joins: 'joins',
  asks: 'asks',

  // ── users/{uid} 아래 ──
  notifications: 'notifications',
  fcmTokens: 'fcmTokens',
  blocks: 'blocks',
  routes: 'routes',
  matches: 'matches',
  meta: 'meta',
  pointLedger: 'pointLedger',
  coupons: 'coupons',
} as const;
