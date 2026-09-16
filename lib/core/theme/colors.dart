import 'package:flutter/material.dart';

/// 기획 시안 v9(`gyumsa-home-v9/src/design.css`)의 색 토큰.
///
/// 시안의 `:root` 변수(`--ink --muted --line --surface --yellow --green`)를 그대로 옮기고,
/// CSS 곳곳에 리터럴로 흩어져 있던 값(내비게이션·필·버튼·출석·수익 카드 등)은
/// 이름을 붙여 아래에 모았다. 새 화면을 만들 때는 리터럴 색을 쓰지 말고 여기서 가져다 쓴다.
class AppColors {
  // ── 기본 토큰 (design.css :root) ─────────────────────────────────────────
  /// --ink
  static const ink = Color(0xFF202124);

  /// --muted
  static const sub = Color(0xFF7C8087);

  /// --line
  static const line = Color(0xFFECEEF1);

  /// --surface. 화면 배경이자 옅은 채움색.
  static const page = Color(0xFFF6F7F9);
  static const surface = page;

  /// 시안의 탭 패널 배경. 본문은 흰 바탕 위에 올라간다.
  static const card = Color(0xFFFFFFFF);

  /// --yellow
  static const yellow = Color(0xFFFADD53);

  /// --green
  static const green = Color(0xFF286C57);

  /// 아이콘·화살표처럼 존재감이 가장 옅은 요소
  static const faint = Color(0xFFAFB4BC);

  /// 본문 제목보다 한 단계 부드러운 먹색 (.task-title)
  static const inkSoft = Color(0xFF30343A);

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
  static const navActive = Color(0xFF272C34);

  /// 가운데 '부탁하기' 버튼 (.main-nav .create-nav>span)
  static const createYellow = Color(0xFFF2D455);

  /// .button.primary / .button.secondary
  static const btnPrimary = Color(0xFFF7DC67);
  static const btnPrimaryInk = Color(0xFF4E4425);
  static const btnSecondary = Color(0xFFF3F5F8);
  static const btnSecondaryInk = Color(0xFF707985);

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
