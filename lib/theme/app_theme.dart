import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary — Rose Gold (modern, feminine, sophisticated)
  static const bgColor = Color(0xFFFCF5F5); // 暖粉白
  static const primary = Color(0xFFF0708D); // 玫瑰金主色
  static const warmBrown = Color(0xFF5C4333); // 暖棕文字
  static const warmLight = Color(0xFFF5F2EF); // 暖白卡片
  static const primary50 = Color(0xFFFFF5F7);
  static const primary100 = Color(0xFFFFE0E6);
  static const primary200 = Color(0xFFFFB8C8);
  static const primary300 = Color(0xFFFC8BA2);
  static const primary400 = Color(0xFFF0708D);
  static const primary500 = Color(0xFFE85978);
  static const primary600 = Color(0xFFD43A5A);
  static const primary700 = Color(0xFFB82242);

  // Neutral — Warm Grey
  static const textMain = Color(0xFF2C2C2C); // 主标题深灰
  static const textSub = Color(0xFF8E8E93); // 副标题浅灰
  static const neutral50 = Color(0xFFFCFAFA);
  static const neutral100 = Color(0xFFF5F5F5);
  static const neutral200 = Color(0xFFEEEEEE);
  static const neutral300 = Color(0xFFD6D6D6);
  static const neutral400 = Color(0xFFAAAAAA);
  static const neutral500 = Color(0xFF8E8E93);
  static const neutral600 = Color(0xFF555555);
  static const neutral700 = Color(0xFF2D2D2D);
  static const neutral800 = Color(0xFF1A1A1A);

  // Semantic
  static const success = Color(0xFF34C759);
  static const warning = Color(0xFFFF9500);
  static const error = Color(0xFFFF3B30);

  // Gradients
  static const gradientRose = LinearGradient(
    colors: [Color(0xFFFFA8B6), Color(0xFFF0708D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFFF0708D).withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Design-system border-radius constants
///
/// See DESIGN.md §5 Border Radius.
class AppRadius {
  AppRadius._();

  /// Fully round — pills, buttons, FABs (999)
  static const pill = 99.0;

  /// Large containers — cards, modals, bottom sheets (20)
  static const card = 20.0;

  /// Medium containers — icon backgrounds, chips (12)
  static const iconBg = 12.0;

  /// Small surfaces — labels, small avatars, thumbnails (8)
  static const label = 8.0;
}

/// Spacing constants — use `gap()` for convenient SizedBox sizing.
///
/// See DESIGN.md §4 Spacing.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

extension SizedBoxGap on num {
  /// Creates a [SizedBox] with [width] and [height] set to this value.
  /// ```dart
  /// 12.gap()  // SizedBox(width: 12, height: 12)
  /// ```
  Widget gap() => SizedBox(width: toDouble(), height: toDouble());
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgColor,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primary100,
        secondary: AppColors.primary300,
        surface: AppColors.bgColor,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.2,
          letterSpacing: -0.3,
          color: AppColors.neutral800,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.25,
          letterSpacing: -0.2,
          color: AppColors.neutral800,
        ),
        headlineLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.3,
          letterSpacing: 0.2,
          color: AppColors.neutral800,
        ),
        headlineMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.35,
          letterSpacing: 0.3,
          color: AppColors.neutral800,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.6,
          letterSpacing: 0.3,
          color: AppColors.neutral700,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.6,
          letterSpacing: 0.2,
          color: AppColors.neutral600,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.5,
          letterSpacing: 0.3,
          color: AppColors.neutral400,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.2,
          letterSpacing: 0.5,
          color: AppColors.neutral700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: const Color(0xFF4A1A2A), // 深玫瑰色 — WCAG AA ≥ 4.5:1
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
          shadowColor: AppColors.primary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary200),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.neutral200, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.neutral200,
        thickness: 0.5,
      ),
    );
  }
}
