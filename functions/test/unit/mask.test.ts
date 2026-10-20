import assert from 'node:assert/strict';
import { test } from 'node:test';

import { maskContact } from '../../src/chat/mask';

const m = (s: string) => maskContact(s);

test('휴대폰 번호 여러 형태를 가린다', () => {
  for (const s of ['010-1234-5678', '01012345678', '010 1234 5678', '+82 10-1234-5678', '010.1234.5678']) {
    const r = m(`연락 주세요 ${s} 감사`);
    assert.equal(r.masked, true, s);
    assert.match(r.text, /\[전화번호 가림\]/, s);
    assert.doesNotMatch(r.text, /5678/, s);
  }
});

test('계좌번호·이메일·오픈채팅·링크를 가린다', () => {
  assert.match(m('국민 123456-01-234567 로 보내 주세요').text, /\[계좌번호 가림\]/);
  assert.match(m('3333012345678 카뱅').text, /\[계좌번호 가림\]/);
  assert.match(m('me@gmail.com 으로').text, /\[이메일 가림\]/);
  assert.match(m('https://open.kakao.com/o/abc123 들어오세요').text, /\[링크 가림\]/);
  assert.match(m('open.kakao.com/o/abc').text, /\[링크 가림\]/);
  assert.match(m('www.example.com 참고').text, /\[링크 가림\]/);
});

test('금액·시간·수량 같은 짧은 숫자는 그대로', () => {
  for (const s of ['사례비 3,000원', '7시 30분에 갈게요', '2개 살게요', '18:30 역삼역 2번 출구', '우유 1L 2,980원', '10월 20일']) {
    const r = m(s);
    assert.equal(r.masked, false, s);
    assert.equal(r.text, s);
  }
});
