import 'package:flutter/material.dart';

import 'colors.dart';

/// 기획 시안 v9의 타이포그래피·모서리 값.
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

  /// .tab-title h1 — 탭 최상단 제목 (부업 · 채팅 · 내 정보)
  static TextStyle get tabTitle => _t(28, w700, AppColors.ink, tracking: -0.036);

  /// .page-header h1 — 푸시된 화면의 제목
  static TextStyle get pageTitle => _t(18, w700, AppColors.ink, tracking: -0.03);

  /// .section-heading h2
  static TextStyle get section => _t(19, w700, AppColors.ink, tracking: -0.033);

  /// .nearby-heading h2 (홈 안쪽 소제목)
  static TextStyle get sectionSmall => _t(15, w600, AppColors.inkSoft, tracking: -0.02);

  /// .task-title
  static TextStyle get taskTitle => _t(16, w600, AppColors.inkSoft, tracking: -0.035, height: 1.45);

  /// .task-price
  static TextStyle get price => _t(18, w700, AppColors.inkSoft, tracking: -0.028);

  /// 본문
  static TextStyle get body => _t(14, w400, AppColors.ink);

  /// .task-meta, 부가 설명
  static TextStyle get meta => _t(12, w400, AppColors.sub, tracking: -0.02);

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
  static const surface = 23.0; // 큰 카드 · 시트
  static const card = 20.0; // 일반 카드 · 배너
  static const tile = 15.0; // 버튼 · 입력창
  static const emblem = 18.0; // 아이콘 타일
  static const chip = 12.0; // 목록 칩
  static const pill = 20.0; // 홈의 둥근 칩
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
    scaffoldBackgroundColor: Colors.white,
    splashFactory: InkSparkle.splashFactory,
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    textTheme: Typography.blackMountainView.apply(fontFamily: AppType.family, bodyColor: AppColors.ink, displayColor: AppColors.ink),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.ink, selectionHandleColor: AppColors.ink),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.page,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: AppType.meta,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.tile), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.tile), borderSide: BorderSide.none),
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
