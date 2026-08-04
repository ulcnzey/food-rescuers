import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase hatalarini kullanicinin anlayacagi Turkce mesajlara cevirir.
String mapAuthError(Object error) {
  if (error is AuthException) {
    final msg = error.message.toLowerCase();

    if (msg.contains('invalid login credentials')) {
      return 'E-posta veya şifre hatalı.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already been registered')) {
      return 'Bu e-posta ile zaten bir hesap var.';
    }
    if (msg.contains('email not confirmed')) {
      return 'E-posta adresinizi doğrulamanız gerekiyor.';
    }
    if (msg.contains('password should be at least')) {
      return 'Şifre en az 6 karakter olmalı.';
    }
    if (msg.contains('invalid email')) {
      return 'Geçerli bir e-posta adresi girin.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Çok fazla deneme yaptınız. Biraz bekleyip tekrar deneyin.';
    }
    return 'Giriş yapılamadı. Lütfen tekrar deneyin.';
  }

  if (error is PostgrestException) {
    return 'Sunucu hatası oluştu. Lütfen tekrar deneyin.';
  }

  if (error is SocketException) {
    return 'İnternet bağlantısı yok.';
  }

  return 'Beklenmeyen bir hata oluştu.';
}