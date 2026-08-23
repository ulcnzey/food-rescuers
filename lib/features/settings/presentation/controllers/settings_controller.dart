import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/auth_error_mapper.dart';
import '../../../../core/providers/supabase_providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/settings_repository.dart';
import '../../domain/entities/static_page.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(supabaseProvider));
});

final staticPageProvider =
    FutureProvider.autoDispose.family<StaticPage?, String>(
  (ref, slug) async => ref.watch(settingsRepositoryProvider).fetchPage(slug),
);

final faqProvider = FutureProvider.autoDispose<List<FaqItem>>((ref) async {
  return ref.watch(settingsRepositoryProvider).fetchFaq();
});

final monthlyImpactProvider =
    FutureProvider<List<MonthlyImpact>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(settingsRepositoryProvider).fetchMonthlyImpact();
});

class SettingsController extends StateNotifier<bool> {
  SettingsController(this._repo, this._ref) : super(false);

  final SettingsRepository _repo;
  final Ref _ref;

  Future<bool> updateAvatar(int avatarId) async {
    state = true;
    try {
      await _repo.updateAvatar(avatarId);
      _ref.invalidate(profileProvider);
      return true;
    } catch (_) {
      return false;
    } finally {
      state = false;
    }
  }

  Future<bool> updateFullName(String fullName) async {
    state = true;
    try {
      await _repo.updateFullName(fullName);
      _ref.invalidate(profileProvider);
      return true;
    } catch (_) {
      return false;
    } finally {
      state = false;
    }
  }

  /// Destek talebi olusturur. Hata mesaji doner, basarili ise null.
  Future<String?> submitTicket({
    required String type,
    required String subject,
    required String message,
    String? email,
  }) async {
    state = true;
    try {
      await _repo.createTicket(
        type: type,
        subject: subject.trim(),
        message: message.trim(),
        email: email?.trim(),
      );
      return null;
    } catch (e) {
      return mapAuthError(e);
    } finally {
      state = false;
    }
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, bool>((ref) {
  return SettingsController(ref.watch(settingsRepositoryProvider), ref);
});