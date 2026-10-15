import 'package:flutter/material.dart';

import 'colors.dart';

/// 기획 시안의 타이포그래피·모서리 값. (v77 기준으로 다시 맞춤)
///
/// 시안은 Pretendard에 letter-spacing을 `-0.025em` 안팎으로 조여서 쓴다.
/// CSS의 `em` 단위는 글자 크기에 비례하므로, Flutter에서는 각 스타일마다
/// `fontSize * 비율`을 letterSpacing에 직접 넣는다.
class AppType {
  static const family = 'Pretendard';

  /// 시안의 font-weight 값을 Flutter가 가진 100 단위로 내림 맞춤.
  /// (720·730·740 → w700, 650 → w600, 550 → w500)
  static const w400 = FontWeight.w400;
  static const w500 = FontWeight.w500;
  static const w600 = FontWeight.w600;
  static const w700 = FontWeight.w700;

  static TextStyle _t(double size, FontWeight weight, Color color, {double tracking = -0.025, double? height}) =>
      TextStyle(fontSize: size, fontWeight: weight, color: color, letterSpacing: size * tracking, height: height);

  /// 탭 최상단 제목 (커뮤니티 · 채팅 · 마이) — v77 헤더 왼쪽 글자
  static TextStyle get tabTitle => _t(22, w700, AppColors.ink, tracking: -0.03);

  /// 국내/해외 큰 탭 (.scp3 button)
  static TextStyle get bigTab => _t(23, w700, AppColors.ink, tracking: -0.05);

  /// 히어로 제목 (.h2-t)
  static TextStyle get hero => _t(22, w700, AppColors.ink, tracking: -0.045, height: 1.35);

  /// .page-header h1 — 푸시된 화면의 제목
  static TextStyle get pageTitle => _t(18, w700, AppColors.ink, tracking: -0.03);

  /// 카드 제목 (.sec .sh .t)
  static TextStyle get section => _t(15.5, w700, AppColors.ink, tracking: -0.03);

  /// .nearby-heading h2 (홈 안쪽 소제목)
  static TextStyle get sectionSmall => _t(15, w600, AppColors.inkSoft, tracking: -0.02);

  /// 목록 제목 (.row .tt)
  static TextStyle get taskTitle => _t(14, w600, AppColors.ink, tracking: -0.01, height: 1.5);

  /// 목록 금액 (.row .v)
  static TextStyle get price => _t(15, w700, AppColors.ink, tracking: -0.03);

  /// 본문
  static TextStyle get body => _t(14, w400, AppColors.ink);

  /// 부가 설명 (.mt)
  static TextStyle get meta => _t(12, w500, AppColors.sub, tracking: -0.01);

  /// 더 작은 주석
  static TextStyle get caption => _t(11, w400, AppColors.sub, tracking: -0.015);

  /// .button
  static TextStyle get button => _t(14, w600, AppColors.ink, tracking: -0.02);
}

/// 모서리 반경.
///
/// 최신 시안(`gyumsa-refined`)은 v9보다 한 단계씩 더 둥글다.
/// (카드 20~23px · 버튼/입력창 15px · 아이콘 타일 18px)
class AppRadius {
  static const surface = 20.0; // 히어로 · LIVE 보드 · 시트
  static const card = 18.0; // 흰 카드 (.sec)
  static const tile = 14.0; // 버튼 · 입력창
  static const emblem = 15.0; // 아이콘 타일 (.ct)
  static const chip = 10.0; // 필터 칩
  static const pill = 18.0; // 둥근 칩
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.ink,
    onPrimary: Colors.white,
    secondary: AppColors.yellow,
    onSecondary: AppColors.ink,
    surface: Colors.white,
    onSurface: AppColors.ink,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: AppType.family,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.page,
    splashFactory: InkSparkle.splashFactory,
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    textTheme: Typography.blackMountainView.apply(fontFamily: AppType.family, bodyColor: AppColors.ink, displayColor: AppColors.ink),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.ink, selectionHandleColor: AppColors.ink),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: AppType.meta,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.tile), borderSide: const BorderSide(color: AppColors.outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.tile), borderSide: const BorderSide(color: AppColors.outline)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.4),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.btnPrimary,
        foregroundColor: AppColors.btnPrimaryInk,
        minimumSize: const Size.fromHeight(50),
        textStyle: AppType.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.tile)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.btnSecondary,
        foregroundColor: AppColors.btnSecondaryInk,
        side: BorderSide.none,
        minimumSize: const Size.fromHeight(50),
        textStyle: AppType.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.tile)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.sub, textStyle: AppType.meta),
    ),
  );
}
