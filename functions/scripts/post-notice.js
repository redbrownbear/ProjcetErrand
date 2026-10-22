/**
 * 공지 · 업데이트 올리기 / 내리기 (A33, Firestore `notices`)
 *
 * 사용법 (functions 폴더에서, 키는 set-admin.js와 같다):
 *   GOOGLE_APPLICATION_CREDENTIALS=<키 경로> node scripts/post-notice.js <notice|update|event> "<제목>" <본문 파일.txt> [--pin] [--at 2026-11-01T09:00]
 *   GOOGLE_APPLICATION_CREDENTIALS=<키 경로> node scripts/post-notice.js --hide <문서 id>
 *
 * --at 을 주면 그 시각(한국 시간)부터 앱에 보인다. 본문은 줄바꿈 그대로 보인다(서식 없음).
 * 콘솔에서 직접 넣어도 된다: title · body(문자열), kind, pinned(bool), hidden(bool), publishedAt(timestamp)
 */
const { readFileSync } = require('node:fs');
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

async function main() {
  const args = process.argv.slice(2);
  initializeApp({ credential: applicationDefault() });
  const col = getFirestore().collection('notices');
  if (args[0] === '--hide') {
    if (!args[1]) throw new Error('사용법: node scripts/post-notice.js --hide <문서 id>');
    await col.doc(args[1]).update({ hidden: true });
    console.log(`${args[1]} 내림`);
    return;
  }
  const [kind, title, file] = args;
  if (!['notice', 'update', 'event'].includes(kind) || !title || !file) {
    throw new Error('사용법: node scripts/post-notice.js <notice|update|event> "<제목>" <본문 파일.txt> [--pin] [--at 2026-11-01T09:00]');
  }
  const atIdx = args.indexOf('--at');
  const at = atIdx > 0 ? new Date(`${args[atIdx + 1]}:00+09:00`) : new Date();
  if (Number.isNaN(at.getTime())) throw new Error('--at 은 2026-11-01T09:00 모양으로');
  const ref = await col.add({
    kind,
    title: title.slice(0, 60),
    body: readFileSync(file, 'utf8').trim().slice(0, 5000),
    pinned: args.includes('--pin'),
    hidden: false,
    publishedAt: Timestamp.fromDate(at),
  });
  console.log(`올림: ${ref.id} (${at.toISOString()}부터 보임)`);
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
