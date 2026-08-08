import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase hatalarini kullanicinin anlayacagi Turkce mesajlara cevirir.
/// Ham hata metni hicbir zaman kullaniciya gosterilmez.
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
    final msg = error.message.toUpperCase();

    // ---- Isletme
    if (msg.contains('NOT_A_BUSINESS_ACCOUNT')) {
      return 'Bu işlem için işletme hesabı gerekiyor.';
    }
    if (msg.contains('BUSINESS_ALREADY_EXISTS')) {
      return 'Bu hesaba ait bir işletme zaten kayıtlı.';
    }
    if (msg.contains('NO_BUSINESS')) {
      return 'Önce işletme bilgilerinizi tamamlamalısınız.';
    }

    // ---- Ilan
    if (msg.contains('INDIVIDUAL_MUST_BE_FREE')) {
      return 'Bireysel paylaşımcılar yalnızca ücretsiz ilan verebilir.';
    }
    if (msg.contains('INVALID_PICKUP_WINDOW')) {
      return 'Bitiş saati başlangıç saatinden sonra olmalı.';
    }
    if (msg.contains('PICKUP_IN_PAST')) {
      return 'Alım saati geçmiş bir zaman olamaz.';
    }
    if (msg.contains('OFFER_NOT_FOUND')) {
      return 'İlan bulunamadı.';
    }
    if (msg.contains('OFFER_EXPIRED')) {
      return 'Bu ilanın süresi dolmuş.';
    }
    if (msg.contains('OFFER_NOT_ACTIVE')) {
      return 'Bu ilan artık aktif değil.';
    }

    // ---- Rezervasyon
    if (msg.contains('INSUFFICIENT_STOCK')) {
      return 'Bu üründen yeterli adet kalmamış.';
    }
    if (msg.contains('RESERVATION_NOT_FOUND')) {
      return 'Rezervasyon bulunamadı.';
    }
    if (msg.contains('ALREADY_USED')) {
      return 'Bu QR kod daha önce kullanılmış.';
    }
    if (msg.contains('NOT_OFFER_OWNER')) {
      return 'Bu rezervasyon size ait bir ilana değil.';
    }

    // ---- Oturum
    if (msg.contains('NOT_AUTHENTICATED')) {
      return 'Oturumunuz sonlanmış. Lütfen tekrar giriş yapın.';
    }

    // Benzersizlik ihlali
    if (error.code == '23505') {
      return 'Bu kayıt zaten mevcut.';
    }

    return 'Sunucu hatası oluştu. Lütfen tekrar deneyin.';
  }

  if (error is SocketException) {
    return 'İnternet bağlantısı yok.';
  }

  return 'Beklenmeyen bir hata oluştu.';
}