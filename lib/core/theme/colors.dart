import 'package:flutter/material.dart';

/// 기획 시안의 색 토큰.
///
/// 기준은 최신 시안 `겸사겸사_v33.html`이다. `:root`의 `--ink --sub --line --soft --y --g --r --b --v`
/// 계열을 그대로 옮겼다. 화면 바탕은 옅은 회색(`--soft`)이고, 그 위에 흰 카드가 올라간다.
/// CSS 곳곳에 리터럴로 흩어져 있던 값(내비게이션·필·버튼·출석·수익 카드 등)은
/// 이름을 붙여 아래에 모았다. 새 화면을 만들 때는 리터럴 색을 쓰지 말고 여기서 가져다 쓴다.
///
/// 예전 시안의 이름(`inkSoft`, `btnPrimary` 등)은 기존 화면이 그대로 쓰고 있어서 남겨 두고,
/// 값만 v33 팔레트로 맞췄다.
class AppColors {
  // ── 기본 토큰 (:root) ────────────────────────────────────────────────────
  /// --ink
  static const ink = Color(0xFF191F28);

  /// --ink2. 본문 제목보다 한 단계 부드러운 먹색
  static const ink2 = Color(0xFF333D4B);

  /// --sub
  static const sub = Color(0xFF6B7684);

  /// --line
  static const line = Color(0xFFEEF0F3);

  /// --soft. 화면 바탕이자 옅은 채움색.
  static const page = Color(0xFFF2F4F6);
  static const surface = page;

  /// --soft2. 세그먼트 바탕·진행 막대 바탕
  static const soft2 = Color(0xFFE8EBEE);

  /// 탭 패널·화면 바탕
  static const panel = page;

  /// 카드 바탕. 본문은 회색 바탕 위의 흰 카드에 올라간다.
  static const card = Color(0xFFFFFFFF);

  /// --y
  static const yellow = Color(0xFFFFCD1F);

  /// --y-ink. 노란 면 위의 글자
  static const yellowInk = Color(0xFF8C6400);

  /// --g
  static const green = Color(0xFF18A874);

  /// --faint. 아이콘·화살표처럼 존재감이 가장 옅은 요소
  static const faint = Color(0xFFB0B8C1);

  /// 예전 이름. 지금은 [ink2]와 같다.
  static const inkSoft = ink2;

  // ── 파생 색 ───────────────────────────────────────────────────────────────
  static const yellowSoft = Color(0xFFFFF6D6); // --y-soft
  static const yellowLine = Color(0xFFF5E2A0);
  static const yellowDeep = Color(0xFFA07A12); // .h2-sub · .tkchip
  static const greenSoft = Color(0xFFE7F6F0); // --g-soft
  static const red = Color(0xFFF04452); // --r
  static const redSoft = Color(0xFFFDEDEE); // --r-soft
  static const blue = Color(0xFF3A7BF5); // --b
  static const blueSoft = Color(0xFFEAF2FE); // --b-soft
  static const purple = Color(0xFF7461F0); // --v
  static const purpleSoft = Color(0xFFF0EEFE); // --v-soft

  /// 히어로 제목의 강조색 (.h2-t b)
  static const heroAccent = Color(0xFFE08A00);

  /// 주황 계열 아이콘 타일 (.ct · .sr-ic · .bn-ic)
  static const orange = Color(0xFFE07A1F);
  static const orangeSoft = Color(0xFFFCF2E9);

  /// 짙은 바탕 — 토스트·출국 보드 (.toast, .osb-board)
  static const black = ink;

  // ── 컴포넌트 토큰 ─────────────────────────────────────────────────────────
  /// 하단 내비게이션 (.nav button)
  static const navIdle = faint;
  static const navActive = ink;

  /// 예전 가운데 '부탁하기' 버튼 색
  static const createYellow = yellow;

  /// 주 버튼 · 보조 버튼 (.h2-cta · .mw-a.main / .morebtn · .mw-a)
  static const btnPrimary = yellow;
  static const btnPrimaryInk = ink;
  static const btnSecondary = page;
  static const btnSecondaryInk = ink2;

  /// .pill / .pill.neutral
  static const pill = yellowSoft;
  static const pillInk = yellowInk;
  static const pillNeutral = page;
  static const pillNeutralInk = sub;

  /// 선택된 칩 (.chip.on)
  static const chipSelected = ink;
  static const chipSelectedWarm = ink;

  /// '급해요' (.bd.urg)
  static const urgent = red;

  /// 출석 줄
  static const attendSoft = yellowSoft;

  // ── 출석 달력 카드 ───────────────────────────────────────────────────────
  static const calBg = page;
  static const calTitle = ink;
  static const calHead = sub;
  static const calDay = ink2;
  static const calFuture = faint;
  static const calTodayBg = yellow;
  static const calTodayInk = ink;
  static const calDoneBg = greenSoft;
  static const calDoneLine = green;
  static const calDoneInk = green;

  /// 출석 카드 문구
  static const attendTitle = ink;
  static const attendEyebrow = sub;
  static const attendMeta = faint;
  static const attendPoint = green;

  /// 출석 목표 타일 — mint · peach 두 가지
  static const goalMintBg = greenSoft;
  static const goalMintBar = green;
  static const goalMintTrack = soft2;
  static const goalMintInk = green;
  static const goalMintSub = sub;
  static const goalPeachBg = yellowSoft;
  static const goalPeachBar = yellow;
  static const goalPeachTrack = soft2;
  static const goalPeachInk = yellowInk;
  static const goalPeachSub = sub;

  /// 출석 보상 기준 안내
  static const attendRule = faint;

  // ── 홈 인사말 ────────────────────────────────────────────────────────────
  static const greetingSub = sub;
  static const greetingPoint = heroAccent;

  // ── 겸사겸사 소식 — 톤 세 가지 ───────────────────────────────────────────
  static const newsBlueBg = blueSoft;
  static const newsBlueInk = blue;
  static const newsPeachBg = Color(0xFFFFF4EA);
  static const newsPeachInk = Color(0xFFB8651A);
  static const newsMintBg = greenSoft;
  static const newsMintInk = green;

  /// 광고 표시 (.adtag · .bn-tx em i)
  static const adLabel = sub;
  static const adLabelLine = line;

  /// 수익 강조색
  static const gold = yellow;

  /// 짙은 바탕 위의 옅은 면·글자
  static const onDarkFill = Color(0x1AFFFFFF);
  static const onDarkSub = Color(0x99FFFFFF);
  static const onDarkFaint = Color(0x80FFFFFF);

  /// 섹션과 섹션 사이를 끊는 두꺼운 구분선
  static const band = page;

  /// 부탁 종류 아이콘 타일 (`.tile` 인라인 색). 없는 종류는 [taskIconFallback].
  static const taskIconFallback = (bg: Color(0xFFF3F3F0), fg: Color(0xFF5E5E63));
  static const taskIcon = <String, ({Color bg, Color fg})>{
    'buy': (bg: Color(0xFFF3F0E6), fg: Color(0xFF8A6400)),
    'photo': (bg: Color(0xFFFCECED), fg: Color(0xFFE0404D)),
    'pickup': (bg: Color(0xFFEAEFFD), fg: Color(0xFF2F63E8)),
    'line': (bg: Color(0xFFF1EEFF), fg: Color(0xFF5B4BE0)),
    'pet': (bg: Color(0xFFFBF1E8), fg: Color(0xFFDA7419)),
    'ticket': (bg: Color(0xFFFDEBFA), fg: Color(0xFFB93AA0)),
    'move': (bg: Color(0xFFEEF2F6), fg: Color(0xFF4A5A70)),
    'clean': (bg: Color(0xFFE7F6F0), fg: Color(0xFF0FA36B)),
    'proxy': (bg: Color(0xFFE8F7F7), fg: Color(0xFF128A8A)),
  };
}
