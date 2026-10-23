/** 한국 시간 계산. 서버는 UTC로 돌아서, 날짜 · 시각은 여기를 거쳐 한국 기준으로 본다 */
export const KST_MS = 9 * 3600_000;

/** 한국 날짜 'YYYY-MM-DD' */
export const kstDay = (ms: number) => new Date(ms + KST_MS).toISOString().slice(0, 10);
