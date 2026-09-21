import 'package:flutter/material.dart';

/// 기획 시안의 색 토큰.
///
/// 기준은 최신 시안 `gyumsa-refined`이다. v9(`design.css`)의 `:root` 변수를
/// 시안이 다시 덮어쓴 값(`--yellow:#ffd95c --ink:#26302e --muted:#8b9294`
/// `--green:#318d74 --line:#eef0ec`, 바탕 `#f7f8f5`)으로 맞췄다.
/// CSS 곳곳에 리터럴로 흩어져 있던 값(내비게이션·필·버튼·출석·수익 카드 등)은
/// 이름을 붙여 아래에 모았다. 새 화면을 만들 때는 리터럴 색을 쓰지 말고 여기서 가져다 쓴다.
class AppColors {
  // ── 기본 토큰 (:root) ────────────────────────────────────────────────────
  /// --ink
  static const ink = Color(0xFF26302E);

  /// --muted
  static const sub = Color(0xFF8B9294);

  /// --line
  static const line = Color(0xFFEEF0EC);

  /// --surface. 화면 배경이자 옅은 채움색.
  static const page = Color(0xFFF7F8F5);
  static const surface = page;

  /// 탭 패널·화면 바탕 (.tab-panel, .screen-scroll)
  static const panel = Color(0xFFFAFBF8);

  /// 시안의 카드 바탕. 본문은 흰 바탕 위에 올라간다.
  static const card = Color(0xFFFFFFFF);

  /// --yellow
  static const yellow = Color(0xFFFFD95C);

  /// --green
  static const green = Color(0xFF318D74);

  /// 아이콘·화살표처럼 존재감이 가장 옅은 요소
  static const faint = Color(0xFFAFB4BC);

  /// 본문 제목보다 한 단계 부드러운 먹색 (.task-title)
  static const inkSoft = Color(0xFF3D4940);

  // ── 파생 색 ───────────────────────────────────────────────────────────────
  static const yellowSoft = Color(0xFFFFF7D9); // .active-banner
  static const yellowLine = Color(0xFFF0DFA4); // .active-banner border
  static const yellowDeep = Color(0xFF6D5720); // .attendance-v8 text
  static const greenSoft = Color(0xFFE7F1EC);
  static const red = Color(0xFFD25C43);
  static const redSoft = Color(0xFFFBEFEA);
  static const blue = Color(0xFF4D6F9E); // .overseas-primary
  static const blueSoft = Color(0xFFEFF4FC);
  static const purple = Color(0xFF7E6A86);
  static const purpleSoft = Color(0xFFF3EEF4);

  /// 수익 카드·토스트에 쓰는 짙은 바탕 (.explore .income-compact, .toast)
  static const black = Color(0xFF252629);

  // ── 컴포넌트 토큰 ─────────────────────────────────────────────────────────
  /// 하단 내비게이션 (.main-nav-item)
  static const navIdle = Color(0xFF73767C);
  static const navActive = Color(0xFF328B72);

  /// 가운데 '부탁하기' 버튼 (.main-nav .create-nav>span)
  static const createYellow = Color(0xFFFFD963);

  /// .button.primary / .button.secondary
  static const btnPrimary = Color(0xFFFFE07A);
  static const btnPrimaryInk = Color(0xFF463E2C);
  static const btnSecondary = Color(0xFFF0F4ED);
  static const btnSecondaryInk = Color(0xFF566D5D);

  /// .pill / .pill.neutral
  static const pill = Color(0xFFF3DC75);
  static const pillInk = Color(0xFF554A23);
  static const pillNeutral = Color(0xFFF3F4F6);
  static const pillNeutralInk = Color(0xFF71757D);

  /// 선택된 칩 (.chip.selected — 목록), (.quick-task-categories .selected — 홈)
  static const chipSelected = Color(0xFF2A2D33);
  static const chipSelectedWarm = Color(0xFF30342A);

  /// '지금 필요해요' (.urgent)
  static const urgent = Color(0xFF9B6A45);

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
  static const taskIconFallback = (bg: Color(0xFFF4F5F7), fg: Color(0xFF6F7581));
  static const taskIcon = <String, ({Color bg, Color fg})>{
    'buy': (bg: Color(0xFFF8F1E5), fg: Color(0xFF8D7448)),
    'photo': (bg: Color(0xFFEDF1F7), fg: Color(0xFF667892)),
    'pickup': (bg: Color(0xFFF2EFEB), fg: Color(0xFF817667)),
    'line': (bg: Color(0xFFF3EEF4), fg: Color(0xFF886E8B)),
    'pet': (bg: Color(0xFFEDF3EE), fg: Color(0xFF617D68)),
    'ticket': (bg: Color(0xFFF6F1E8), fg: Color(0xFF8A7A4E)),
    'move': (bg: Color(0xFFEEF1F5), fg: Color(0xFF6C7684)),
    'clean': (bg: Color(0xFFEDF3F2), fg: Color(0xFF5F7C79)),
    'proxy': (bg: Color(0xFFF4F1E9), fg: Color(0xFF857A5A)),
  };
}
