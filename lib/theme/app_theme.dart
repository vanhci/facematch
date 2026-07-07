import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // YanMo palette — warm rose/pink tones
  static const bgColor = Color(0xFFFCEEE9);
  static const bgGradientMid = Color(0xFFFDF6F3);
  static const bgGradientBot = Color(0xFFFBF0EC);
  static const primary = Color(0xFFE8899A); // rose
  static const primaryDark = Color(0xFFB98374); // warm brown
  static const primary50 = Color(0xFFFFF5F7);
  static const primary100 = Color(0xFFFCE4E8);
  static const primary200 = Color(0xFFF9C9D0);
  static const primary300 = Color(0xFFE8899A);
  static const primary400 = Color(0xFFDA7A8A);
  static const primary500 = Color(0xFFC06978);
  static const primary600 = Color(0xFFA65866);
  static const primary700 = Color(0xFF8C4754);
  static const textMain = Color(0xFF4A3B38);
  static const textSub = Color(0xFFC79E90);
  static const textMuted = Color(0xFFD6B6AA);
  static const neutral50 = Color(0xFFFCFAFA);
  static const neutral100 = Color(0xFFF9F0ED);
  static const neutral200 = Color(0xFFF0E3DE);
  static const neutral300 = Color(0xFFE0D0CA);
  static const neutral400 = Color(0xFFC79E90);
  static const neutral500 = Color(0xFFB0887A);
  static const neutral600 = Color(0xFF8A6A5E);
  static const neutral700 = Color(0xFF6B5248);
  static const neutral800 = Color(0xFF4A3B38);
  static const success = Color(0xFF34C759);
  static const warning = Color(0xFFFF9500);
  static const error = Color(0xFFFF3B30);
  static const cardBorder = Color(0xFFFFFFFF);
  static const navActiveBg = Color(0xFFF9DCE0);
  static const iconRose = Color(0xFFE0A79A);
  static const iconDark = Color(0xFFB07C63);
  static const iconPetal = Color(0xFFE8A0A8);
  static const iconSparkle = Color(0xFFE7B7A6);
  static const brownText = Color(0xFFB98374);
  static const brownLight = Color(0xFFC79E90);
  static const brownDark = Color(0xFF4A3B38);
  static const errorRed = Color(0xFFFF3B30);
  static const shadowPink = Color(0xFFF4A6AD);

  static const cardRadius = 24.0;
  static const iconRadius = 22.0;
  static const buttonRadius = 27.0;
  static const clipRadius = 21.0;
  static const navRadius = 28.0;

  static const gradientRose = LinearGradient(
    colors: [Color(0xFFFCA8AE), Color(0xFFF7C8CE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}

class AppRadius {
  AppRadius._();
  static const pill = 99.0;
  static const card = 24.0;
  static const iconBg = 12.0;
  static const label = 8.0;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

extension NumGap on num {
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
      fontFamily: 'PingFang SC',
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
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
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: Colors.white, width: 3),
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
