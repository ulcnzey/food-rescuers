import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/auth_error_mapper.dart';
import '../../../../core/providers/supabase_providers.dart';
import '../../data/auth_repository.dart';
import '../../domain/entities/profile.dart';
import '../../domain/enums/user_role.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseProvider));
});

/// Giris yapmis kullanicinin profili. Oturum degisince kendini yeniler.
final profileProvider = FutureProvider<Profile?>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).fetchProfile();
});

/// Ekranlarin izleyecegi islem durumu.
class AuthUiState {
  const AuthUiState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  AuthUiState copyWith({bool? isLoading, String? errorMessage}) {
    return AuthUiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthUiState> {
  AuthController(this._repo) : super(const AuthUiState());

  final AuthRepository _repo;

  /// Basarili olursa true doner. Ekran buna bakarak yonlendirir.
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return _run(() => _repo.signUp(
          email: email.trim(),
          password: password,
          fullName: fullName.trim(),
        ));
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    return _run(() => _repo.signIn(email: email.trim(), password: password));
  }

  Future<bool> selectRole(UserRole role) async {
    return _run(() => _repo.updateRole(role));
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthUiState();
  }

  void clearError() => state = state.copyWith();

  /// Yukleme + hata yonetimini tek yerde toplar.
  Future<bool> _run(Future<void> Function() action) async {
    state = const AuthUiState(isLoading: true);
    try {
      await action();
      state = const AuthUiState();
      return true;
    } catch (e) {
      state = AuthUiState(errorMessage: mapAuthError(e));
      return false;
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthUiState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});