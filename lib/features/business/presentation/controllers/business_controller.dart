import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/auth_error_mapper.dart';
import '../../../../core/providers/supabase_providers.dart';
import '../../../offers/presentation/controllers/offer_controller.dart';
import '../../data/business_repository.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/business_stats.dart';

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepository(ref.watch(supabaseProvider));
});

/// Giris yapmis kullanicinin isletmesi. Yoksa null doner.
final myBusinessProvider = FutureProvider<Business?>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(businessRepositoryProvider).fetchMyBusiness();
});

/// Isletme panelinin gunluk ozeti.
final businessStatsProvider = FutureProvider<BusinessStats>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(businessRepositoryProvider).fetchStats();
});

/// Kullanici ilan verebiliyor mu (isletmesi var mi).
final canSellProvider = Provider<bool>((ref) {
  return ref.watch(myBusinessProvider).valueOrNull != null;
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

      _ref.invalidate(myBusinessProvider);
      _ref.invalidate(businessStatsProvider);

      state = const BusinessUiState();
      return true;
    } catch (e) {
      state = BusinessUiState(errorMessage: mapAuthError(e));
      return false;
    }
  }

  /// Isletme bilgilerini gunceller. Yeni logo dosyasi verilmisse
  /// once Storage'a yuklenir, donen URL kayda islenir.
  Future<bool> updateBusiness({
    String? name,
    BusinessCategory? category,
    String? description,
    String? address,
    String? phone,
    String? opensAt,
    String? closesAt,
    List<int>? openDays,
    File? logoFile,
    double? latitude,
    double? longitude,
  }) async {
    state = const BusinessUiState(isLoading: true);

    try {
      String? logoUrl;

      if (logoFile != null) {
        final result = await _ref
            .read(imageUploadServiceProvider)
            .upload(file: logoFile, folder: 'logos');

        if (!result.isSuccess) {
          state = BusinessUiState(errorMessage: result.error);
          return false;
        }
        logoUrl = result.url;
      }

      await _repo.updateMyBusiness(
        name: name?.trim(),
        category: category,
        description: description?.trim(),
        address: address?.trim(),
        phone: phone?.trim(),
        opensAt: opensAt,
        closesAt: closesAt,
        openDays: openDays,
        logoUrl: logoUrl,
        latitude: latitude,
        longitude: longitude,
      );

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