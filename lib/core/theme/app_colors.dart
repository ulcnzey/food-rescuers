import 'package:flutter/material.dart';

/// Uygulamanin tum renkleri burada tanimli.
/// Widget'larin icinde asla Color(0xFF...) yazilmaz.
class AppColors {
  AppColors._();

  // Ana renk: koyu yesil
  static const Color primary = Color(0xFF1B7F5C);
  static const Color primaryDark = Color(0xFF135C43);
  static const Color primaryLight = Color(0xFFB8DFCE);

  // Ikincil renk: sicak amber
  static const Color secondary = Color(0xFFF2A93B);
  static const Color secondaryLight = Color(0xFFFDEBCF);

  // Durum renkleri
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE8A33D);
  static const Color error = Color(0xFFD4453B);
  static const Color info = Color(0xFF3B82C4);

  // Acik tema
  static const Color bgLight = Color(0xFFFAF8F4);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF16201B);
  static const Color textMutedLight = Color(0xFF6B7873);
  static const Color borderLight = Color(0xFFE4E0D8);

  // Koyu tema
  static const Color bgDark = Color(0xFF121410);
  static const Color surfaceDark = Color(0xFF1C1F1B);
  static const Color textDark = Color(0xFFF2F4F0);
  static const Color textMutedDark = Color(0xFF9AA39D);
  static const Color borderDark = Color(0xFF2E332C);

  // Ucretsiz ilan rozeti
  static const Color freeBadge = Color(0xFF2E9E5B);
}