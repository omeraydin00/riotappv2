import 'package:material_ui/material_ui.dart';

// Uygulamanın tek teması: koyu lacivert zemin, altın vurgu
class AppColors {
  static const background = Color(0xFF0A1428);
  static const surface = Color(0xFF101C33);
  static const surfaceHigh = Color(0xFF16264A);
  static const border = Color(0xFF243656);
  static const gold = Color(0xFFC8AA6E);
  static const goldDim = Color(0xFF785A28);
  static const cream = Color(0xFFF0E6D2);
  static const muted = Color(0xFF8E97A8);
  static const correct = Color(0xFF2EB872);
  static const wrong = Color(0xFFE84057);
  static const teal = Color(0xFF0AC8B9);
}

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.gold,
    onPrimary: AppColors.background,
    secondary: AppColors.teal,
    onSecondary: AppColors.background,
    surface: AppColors.surface,
    onSurface: AppColors.cream,
    error: AppColors.wrong,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
  );

  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.cream,
      displayColor: AppColors.cream,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.cream,
        letterSpacing: 0.3,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.background,
        minimumSize: const Size.fromHeight(52),
        shape: buttonShape,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gold,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.goldDim),
        shape: buttonShape,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.gold,
      linearTrackColor: AppColors.border,
      circularTrackColor: Colors.transparent,
    ),
  );
}
