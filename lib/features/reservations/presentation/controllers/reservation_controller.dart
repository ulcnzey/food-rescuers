import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/auth_error_mapper.dart';
import '../../../../core/providers/supabase_providers.dart';
import '../../data/reservation_repository.dart';
import '../../domain/entities/reservation.dart';

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepository(ref.watch(supabaseProvider));
});

final myReservationsProvider = FutureProvider<List<Reservation>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(reservationRepositoryProvider).fetchMine();
});

final myImpactProvider = FutureProvider<ImpactStats>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(reservationRepositoryProvider).fetchImpact();
});

class ReservationUiState {
  const ReservationUiState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  ReservationUiState copyWith({bool? isLoading, String? errorMessage}) {
    return ReservationUiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ReservationController extends StateNotifier<ReservationUiState> {
  ReservationController(this._repo, this._ref)
      : super(const ReservationUiState());

  final ReservationRepository _repo;
  final Ref _ref;

  /// Basarili olursa olusan rezervasyonu doner, aksi halde null.
  Future<Reservation?> reserve({
    required String offerId,
    int quantity = 1,
  }) async {
    state = const ReservationUiState(isLoading: true);
    try {
      final result = await _repo.reserve(offerId: offerId, quantity: quantity);
      _invalidate();
      state = const ReservationUiState();
      return result;
    } catch (e) {
      state = ReservationUiState(errorMessage: mapAuthError(e));
      return null;
    }
  }

  Future<bool> cancel(String reservationId) async {
    return _run(() => _repo.cancel(reservationId));
  }

  Future<bool> completeByQr(String qrToken) async {
    return _run(() => _repo.completeByQr(qrToken));
  }

  void clearError() => state = state.copyWith();

  void _invalidate() {
    _ref.invalidate(myReservationsProvider);
    _ref.invalidate(myImpactProvider);
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = const ReservationUiState(isLoading: true);
    try {
      await action();
      _invalidate();
      state = const ReservationUiState();
      return true;
    } catch (e) {
      state = ReservationUiState(errorMessage: mapAuthError(e));
      return false;
    }
  }
}

final reservationControllerProvider =
    StateNotifierProvider<ReservationController, ReservationUiState>((ref) {
  return ReservationController(ref.watch(reservationRepositoryProvider), ref);
});