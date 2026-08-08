import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/auth_error_mapper.dart';
import '../../../../core/providers/supabase_providers.dart';
import '../../../../core/services/location_service.dart';
import '../../data/business_repository.dart';
import '../../domain/entities/business.dart';

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepository(ref.watch(supabaseProvider));
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});

/// Giris yapmis kullanicinin isletmesi. Yoksa null doner.
final myBusinessProvider = FutureProvider<Business?>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(businessRepositoryProvider).fetchMyBusiness();
});

/// Kullanici ilan verebiliyor mu (isletmesi var mi).
final canSellProvider = Provider<bool>((ref) {
  final business = ref.watch(myBusinessProvider);
  return business.valueOrNull != null;
});

class BusinessUiState {
  const BusinessUiState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  BusinessUiState copyWith({bool? isLoading, String? errorMessage}) {
    return BusinessUiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class BusinessController extends StateNotifier<BusinessUiState> {
  BusinessController(this._repo, this._ref) : super(const BusinessUiState());

  final BusinessRepository _repo;
  final Ref _ref;

  Future<bool> createBusiness({
    required String name,
    required BusinessCategory category,
    required double latitude,
    required double longitude,
    required List<int> openDays,
    ProviderType providerType = ProviderType.business,
    String? description,
    String? address,
    String? phone,
    String? opensAt,
    String? closesAt,
    String? logoUrl,
  }) async {
    state = const BusinessUiState(isLoading: true);
    try {
      await _repo.createBusiness(
        name: name.trim(),
        category: category,
        latitude: latitude,
        longitude: longitude,
        openDays: openDays,
        providerType: providerType,
        description: description?.trim(),
        address: address?.trim(),
        phone: phone?.trim(),
        opensAt: opensAt,
        closesAt: closesAt,
        logoUrl: logoUrl,
      );

      // Isletme olustu, onbellegi tazele.
      _ref.invalidate(myBusinessProvider);

      state = const BusinessUiState();
      return true;
    } catch (e) {
      state = BusinessUiState(errorMessage: mapAuthError(e));
      return false;
    }
  }

  void clearError() => state = state.copyWith();
}

final businessControllerProvider =
    StateNotifierProvider<BusinessController, BusinessUiState>((ref) {
  return BusinessController(ref.watch(businessRepositoryProvider), ref);
});