import 'package:flutter/material.dart';

/// Uygulamanin tum renkleri burada tanimli.
/// Widget'larin icinde asla Color(0xFF...) yazilmaz.
class AppColors {
  AppColors._();

  // Ana renk: derin orman yesili
  static const Color primary = Color(0xFF0F4C42);
  static const Color primaryDark = Color(0xFF0A362F);
  static const Color primaryLight = Color(0xFFC5E4DA);

  // Ikincil: sicak amber
  static const Color secondary = Color(0xFFE89830);
  static const Color secondaryLight = Color(0xFFFDF0DC);

  // Durum renkleri
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE8A33D);
  static const Color error = Color(0xFFD4453B);
  static const Color info = Color(0xFF3B82C4);

  // Acik tema
  static const Color bgLight = Color(0xFFFDF9F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF15201C);
  static const Color textMutedLight = Color(0xFF6E7A75);
  static const Color borderLight = Color(0xFFEAE4DC);

  // Koyu tema
  static const Color bgDark = Color(0xFF0E1210);
  static const Color surfaceDark = Color(0xFF1A201D);
  static const Color textDark = Color(0xFFF3F6F3);
  static const Color textMutedDark = Color(0xFF9AA6A1);
  static const Color borderDark = Color(0xFF2B332F);

  // Ucretsiz ilan rozeti
  static const Color freeBadge = Color(0xFF2E9E5B);
}