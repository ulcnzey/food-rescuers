/// Ortam degiskenleri. Degerler --dart-define ile disaridan gelir.
/// Anahtarlar koda gomulmez, boylece git gecmisine sizmaz.
class Env {
  Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Uygulama acilirken cagrilir. Eksik anahtar varsa erken hata verir.
  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL veya SUPABASE_ANON_KEY tanimli degil. '
        'Uygulamayi run_dev.bat ile calistirin.',
      );
    }
  }
}