import 'package:flutter/material.dart';

import 'colors.dart';

/// 기획 시안 v33의 타이포그래피·모서리 값.
///
/// 시안은 letter-spacing을 `-0.03em` 안팎으로 조여서 쓴다.
/// CSS의 `em` 단위는 글자 크기에 비례하므로, Flutter에서는 각 스타일마다
/// `fontSize * 비율`을 letterSpacing에 직접 넣는다.
///
/// 시안의 서체는 Noto Sans KR(800·900까지 사용)이지만, 앱은 이미 번들한
/// Pretendard(400~700)를 그대로 쓴다. 800·900은 가장 가까운 [w700]으로 맞춘다.
class AppType {
  static const family = 'Pretendard';

  /// 시안의 font-weight 값을 Flutter가 가진 100 단위로 맞춤.
  /// (800·900 → w700 — 번들한 Pretendard가 Bold까지다)
  static const w400 = FontWeight.w400;
  static const w500 = FontWeight.w500;
  static const w600 = FontWeight.w600;
  static const w700 = FontWeight.w700;

  static TextStyle _t(double size, FontWeight weight, Color color, {double tracking = -0.025, double? height}) =>
      TextStyle(fontSize: size, fontWeight: weight, color: color, letterSpacing: size * tracking, height: height);

  /// .hdr .ttl — 탭 최상단 제목 (미션·공구 · 해외 · 채팅 · 마이)
  static TextStyle get tabTitle => _t(21, w700, AppColors.ink, tracking: -0.02);

  /// 푸시된 화면의 제목
  static TextStyle get pageTitle => _t(17, w700, AppColors.ink, tracking: -0.03);

  /// 큰 섹션 제목
  static TextStyle get section => _t(18, w700, AppColors.ink, tracking: -0.03);

  /// .sh .t — 카드 안 섹션 제목
  static TextStyle get sectionSmall => _t(15.5, w700, AppColors.ink, tracking: -0.03);

  /// .row .tt
  static TextStyle get taskTitle => _t(14, w600, AppColors.ink, tracking: -0.02, height: 1.5);

  /// .row .v
  static TextStyle get price => _t(15, w700, AppColors.ink, tracking: -0.03);

  /// 본문
  static TextStyle get body => _t(14, w400, AppColors.ink);

  /// .task-meta, 부가 설명
  static TextStyle get meta => _t(12, w400, AppColors.sub, tracking: -0.02);

  /// 더 작은 주석
  static TextStyle get caption => _t(11, w400, AppColors.sub, tracking: -0.015);

  /// .button
  static TextStyle get button => _t(14, w600, AppColors.ink, tracking: -0.02);
}

/// 모서리 반경. (v33: 섹션 카드 18 · 히어로 20 · 버튼 13~15 · 아이콘 타일 12)
class AppRadius {
  static const surface = 20.0; // 히어로 · 시트 · 큰 카드
  static const card = 18.0; // 섹션 카드 (.sec)
  static const tile = 14.0; // 버튼 · 입력창 · 세그먼트
  static const emblem = 12.0; // 아이콘 타일 (.tile)
  static const chip = 20.0; // 목록 칩 (.chip)
  static const pill = 20.0; // 둥근 칩
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
    textTheme: Typography.blackMountainView.apply(
      fontFamily: AppType.family,
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
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
