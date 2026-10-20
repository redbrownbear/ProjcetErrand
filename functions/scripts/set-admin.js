/**
 * 운영자 지정·해제 (Auth custom claim role=admin)
 *
 * 사용법 (functions 폴더에서):
 *   1) Firebase 콘솔 › 프로젝트 설정 › 서비스 계정 › 새 비공개 키 생성 → 저장소 밖에 저장
 *   2) GOOGLE_APPLICATION_CREDENTIALS=/c/keys/projecterrand.json node scripts/set-admin.js <이메일> [off]
 *
 * 지정된 사람은 다시 로그인해야 권한이 적용된다. 키 파일은 절대 저장소에 넣지 않는다.
 */
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

async function main() {
  const [email, off] = process.argv.slice(2);
  if (!email) throw new Error('사용법: node scripts/set-admin.js <이메일> [off]');
  initializeApp({ credential: applicationDefault() });
  const user = await getAuth().getUserByEmail(email);
  const claims = { ...(user.customClaims || {}) };
  if (off === 'off') delete claims.role;
  else claims.role = 'admin';
  await getAuth().setCustomUserClaims(user.uid, claims);
  console.log(`${email} (${user.uid}) → ${off === 'off' ? '운영자 해제' : '운영자 지정'}. 다시 로그인하면 적용돼요.`);
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
