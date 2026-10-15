import 'package:flutter/material.dart';

/// 기획 시안의 색 토큰.
///
/// 기준은 최신 시안 `겸사겸사_v77.html`이다. v77은 화면 바탕을 옅은 회색(#F2F4F6)으로
/// 깔고 그 위에 흰 카드(모서리 18)를 10px 간격으로 쌓는다. 글자색은 #191F28 계열,
/// 강조는 노랑(#FFCD1F)과 해외용 파랑(#3A7BF5) 두 가지다.
/// 이전 시안에서 쓰던 이름은 그대로 두고 값만 v77로 옮겼다 — 예전 화면도 같은 색으로 맞춰진다.
/// 새 화면을 만들 때는 리터럴 색을 쓰지 말고 여기서 가져다 쓴다.
class AppColors {
  // ── 기본 토큰 ────────────────────────────────────────────────────────────
  /// 제목·본문 먹색
  static const ink = Color(0xFF191F28);

  /// 한 단계 부드러운 먹색 (버튼 글자, 본문 인용)
  static const inkSoft = Color(0xFF333D4B);

  /// 보조 글자
  static const sub = Color(0xFF6B7684);

  /// 아이콘·날짜처럼 존재감이 가장 옅은 요소
  static const faint = Color(0xFFB0B8C1);

  /// 목록 구분선
  static const line = Color(0xFFEEF0F3);

  /// 버튼·입력창 테두리 (inset 1px)
  static const outline = Color(0xFFE8EBEE);

  /// 화면 바탕이자 옅은 채움색 (#scroll · .morebtn · .pp-tool)
  static const page = Color(0xFFF2F4F6);
  static const surface = page;
  static const panel = page;

  /// 세그먼트 바탕 (.os-seg)
  static const segBg = Color(0xFFE8EBEE);

  /// 카드 바탕
  static const card = Color(0xFFFFFFFF);

  /// 겸사겸사 시그니처 노랑. CTA 버튼 (.h2-cta)
  static const yellow = Color(0xFFFFCD1F);

  /// 노랑 글자 (.h2-sub · .tkchip)
  static const yellowInk = Color(0xFFA07A12);

  /// 강조 단어 주황 (.h2-t b)
  static const orange = Color(0xFFE08A00);

  static const green = Color(0xFF18A874);
  static const greenDeep = Color(0xFF0B7A51);
  static const greenSoft = Color(0xFFE7F6F0);

  static const red = Color(0xFFF04452);
  static const redSoft = Color(0xFFFDEDEE);

  /// 해외 탭 파랑
  static const blue = Color(0xFF3A7BF5);
  static const blueSoft = Color(0xFFEEF4FF);

  /// 광고·제휴 보라 (.pp-row.ad)
  static const purple = Color(0xFF5B4BE0);
  static const purpleSoft = Color(0xFFEFEBFF);
  static const purpleLine = Color(0xFFD9D2FF);

  // ── 파생 색 ───────────────────────────────────────────────────────────────
  /// 응모권 칩 바탕 (.ld-hbtn · .tkchip)
  static const yellowSoft = Color(0xFFFFF8E4);

  /// 응모권 칩 테두리
  static const yellowLine = Color(0xFFE8DFC4);

  /// LIVE 제안 보드 (.pp-live)
  static const liveBg = Color(0xFFFFF6D6);
  static const liveLine = Color(0xFFF3E2A3);

  /// 히어로 카드 그라데이션 시작색 (.h2) — 국내 노랑 · 해외 파랑
  static const heroYellow = Color(0xFFFFFBEA);
  static const heroBlue = Color(0xFFEEF4FF);

  static const yellowDeep = Color(0xFF7A5A00);

  /// 짙은 바탕 (토스트 · 제안 버튼 · 출국 보드)
  static const black = Color(0xFF191F28);

  // ── 컴포넌트 토큰 ─────────────────────────────────────────────────────────
  /// 하단 내비게이션 (.nav)
  static const navIdle = Color(0xFFB0B8C1);
  static const navActive = Color(0xFF191F28);

  /// 국내/해외 큰 탭의 꺼진 글자 (.scp3 button)
  static const tabIdle = Color(0xFFB5B7BF);

  static const createYellow = yellow;

  /// .button.primary / .button.secondary
  static const btnPrimary = yellow;
  static const btnPrimaryInk = ink;
  static const btnSecondary = page;
  static const btnSecondaryInk = inkSoft;

  /// .pill / .pill.neutral
  static const pill = yellowSoft;
  static const pillInk = yellowInk;
  static const pillNeutral = page;
  static const pillNeutralInk = sub;

  /// 선택된 칩
  static const chipSelected = ink;
  static const chipSelectedWarm = ink;

  /// '지금 필요해요'
  static const urgent = red;

  /// 출석 줄 (.attendance-v8)
  static const attendSoft = Color(0xFFFCF7E5);

  // ── 출석 달력 카드 (.g3-attendance) ──────────────────────────────────────
  /// 달력 바탕 (.g3-calendar)
  static const calBg = Color(0xFFF5F8EE);
  static const calTitle = Color(0xFF547744);
  static const calHead = Color(0xFF93A484);
  static const calDay = Color(0xFF6C7D63);
  static const calFuture = Color(0xFFB9C3B2);
  static const calTodayBg = Color(0xFFFFE7A1);
  static const calTodayInk = Color(0xFF866A29);
  static const calDoneBg = Color(0xFFE5F2DE);
  static const calDoneLine = Color(0xFF62A27B);
  static const calDoneInk = Color(0xFF3B815B);

  /// 출석 카드 문구 (.g3-att-copy)
  static const attendTitle = Color(0xFF344D3E);
  static const attendEyebrow = Color(0xFF879A7D);
  static const attendMeta = Color(0xFFA1AC9C);
  static const attendPoint = Color(0xFF599771);

  /// 출석 목표 타일 (.g3-att-missions) — mint · peach 두 가지
  static const goalMintBg = Color(0xFFEDF6ED);
  static const goalMintBar = Color(0xFF7CAF7D);
  static const goalMintTrack = Color(0xFFDEEBD7);
  static const goalMintInk = Color(0xFF64976E);
  static const goalMintSub = Color(0xFF91A184);
  static const goalPeachBg = Color(0xFFFFF4E5);
  static const goalPeachBar = Color(0xFFE5BD76);
  static const goalPeachTrack = Color(0xFFF6E5C9);
  static const goalPeachInk = Color(0xFFC29456);
  static const goalPeachSub = Color(0xFFBDA47E);

  /// 출석 보상 기준 안내 (.g3-att-rules)
  static const attendRule = Color(0xFF9BAA94);

  // ── 홈 인사말 (.g3-greeting) ─────────────────────────────────────────────
  static const greetingSub = Color(0xFF80918C);
  static const greetingPoint = Color(0xFF429778);

  // ── 겸사겸사 소식 (.g4-news) — 톤 세 가지 ────────────────────────────────
  static const newsBlueBg = Color(0xFFEDF4FA);
  static const newsBlueInk = Color(0xFF426578);
  static const newsPeachBg = Color(0xFFFFF0E2);
  static const newsPeachInk = Color(0xFF8F6847);
  static const newsMintBg = Color(0xFFE6F2E9);
  static const newsMintInk = Color(0xFF456F58);

  /// 광고 소식에 붙는 '광고' 표시 (.ad-label)
  static const adLabel = Color(0xFF41694B);
  static const adLabelLine = Color(0xFFA4C5AD);

  /// 수익 카드 강조색 (.explore .income-compact progress)
  static const gold = Color(0xFFF2CF55);

  /// 수익 카드 내부의 옅은 면 (progress bar 바탕)
  static const onDarkFill = Color(0xFF474749);
  static const onDarkSub = Color(0xFFAEB1B8);
  static const onDarkFaint = Color(0xFF9DA1A9);

  /// 섹션과 섹션 사이를 끊는 두꺼운 구분선 (.compact-missions border)
  static const band = Color(0xFFF6F6F2);

  /// 부탁 종류 아이콘 타일 (.task-icon-*). 없는 종류는 [taskIconFallback].
  static const taskIconFallback = (bg: Color(0xFFF2F4F6), fg: Color(0xFF6B7684));
  static const taskIcon = <String, ({Color bg, Color fg})>{
    'buy': (bg: Color(0xFFFFF4DC), fg: Color(0xFFE08A00)),
    'photo': (bg: Color(0xFFFDEDEE), fg: Color(0xFFF04452)),
    'pickup': (bg: Color(0xFFEAEFFD), fg: Color(0xFF2F63E8)),
    'line': (bg: Color(0xFFF1EEFF), fg: Color(0xFF5B4BE0)),
    'pet': (bg: Color(0xFFFFF1E6), fg: Color(0xFFE5772E)),
    'ticket': (bg: Color(0xFFF1EEFF), fg: Color(0xFF5B4BE0)),
    'move': (bg: Color(0xFFEAEFFD), fg: Color(0xFF2F63E8)),
    'clean': (bg: Color(0xFFE6F6EE), fg: Color(0xFF0FA36B)),
    'proxy': (bg: Color(0xFFFFF4DC), fg: Color(0xFFE08A00)),
    'used': (bg: Color(0xFFE6F6EE), fg: Color(0xFF0B7A51)),
  };

  /// 자주 하는 부탁 타일 (.cats .ct) — 한 가지 살구색
  static const catTileBg = Color(0xFFFCF2E9);
  static const catTileFg = Color(0xFFE5772E);
}
