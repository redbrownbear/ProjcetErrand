/**
 * 채팅 속 연락처·계좌·외부 링크 가리기 (F-028 · 우회 거래 방지).
 *
 * 앱 밖에서 거래하면 신고·분쟁 처리와 기록이 사라진다. 그래서 메시지를 저장하기 전에 서버가 가린다.
 * 완벽한 차단이 목적이 아니라, 흔한 형태를 막고 '가려졌다'는 사실을 보여 주는 게 목적이다.
 */

const RULES: { name: string; re: RegExp }[] = [
  // 오픈채팅·메신저·외부 링크
  { name: 'link', re: /\b(?:https?:\/\/|www\.)\S+/gi },
  { name: 'link', re: /\bopen\.kakao\.com\/\S+/gi },
  { name: 'link', re: /\b[\w.-]+\.(?:com|net|kr|co\.kr|me|io|ly|gl)\/\S*/gi },
  // 이메일
  { name: 'email', re: /[\w.+-]+@[\w-]+\.[\w.-]+/g },
  // 휴대폰·전화: 010-1234-5678, 01012345678, 010 1234 5678, +82 10-…, 02-123-4567
  { name: 'phone', re: /(?:\+?82[-\s.]?)?0?1[016789][-\s.]?\d{3,4}[-\s.]?\d{4}/g },
  { name: 'phone', re: /\b0\d{1,2}[-\s.]\d{3,4}[-\s.]\d{4}\b/g },
  // 계좌번호: 숫자와 '-'로 이루어진 10~16자리
  { name: 'account', re: /\b\d{2,6}(?:[-\s]\d{2,6}){1,4}\b|\b\d{10,16}\b/g },
];

const digits = (s: string) => s.replace(/\D/g, '').length;

export function maskContact(input: string): { text: string; masked: boolean } {
  let text = input;
  let masked = false;
  for (const { name, re } of RULES) {
    text = text.replace(re, (m) => {
      // 숫자 규칙은 숫자가 충분히 길 때만 가린다(금액·시간·수량 같은 짧은 숫자는 그대로)
      if ((name === 'account' || name === 'phone') && digits(m) < 9) return m;
      masked = true;
      return name === 'link' ? '[링크 가림]' : name === 'email' ? '[이메일 가림]' : name === 'phone' ? '[전화번호 가림]' : '[계좌번호 가림]';
    });
  }
  return { text, masked };
}
