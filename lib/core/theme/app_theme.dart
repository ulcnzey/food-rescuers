import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer:
          isLight ? AppColors.primaryLight : AppColors.primaryDark,
      onPrimaryContainer:
          isLight ? AppColors.primaryDark : AppColors.primaryLight,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryLight,
      onSecondaryContainer: AppColors.primaryDark,
      error: AppColors.error,
      onError: Colors.white,
      surface: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
      onSurface: isLight ? AppColors.textLight : AppColors.textDark,
      onSurfaceVariant:
          isLight ? AppColors.textMutedLight : AppColors.textMutedDark,
      outline: isLight ? AppColors.borderLight : AppColors.borderDark,
    );

    final baseTextTheme =
        isLight ? ThemeData.light().textTheme : ThemeData.dark().textTheme;

    final base = GoogleFonts.interTextTheme(baseTextTheme).apply(
      bodyColor: isLight ? AppColors.textLight : AppColors.textDark,
      displayColor: isLight ? AppColors.textLight : AppColors.textDark,
    );

    // Buyuk basliklar cok kalin ve harf araligi sikisik.
    // Bu, modern gida uygulamalarinin karakteristik tipografisi.
    final textTheme = base.copyWith(
      displayLarge: base.displayLarge
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.5),
      displayMedium: base.displayMedium
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.2),
      displaySmall: base.displaySmall
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.0),
      headlineLarge: base.headlineLarge
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.0),
      headlineMedium: base.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8),
      headlineSmall: base.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      titleLarge: base.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.5),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.5),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isLight ? AppColors.bgLight : AppColors.bgDark,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? AppColors.bgLight : AppColors.bgDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          side: BorderSide(color: scheme.outline),
        ),
      ),

      // Tam yuvarlak, yuksek butonlar.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: scheme.outline, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 18,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        side: BorderSide(color: scheme.outline),
        labelStyle: textTheme.labelLarge,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 1,
        space: 1,
      ),
    );
  }
}