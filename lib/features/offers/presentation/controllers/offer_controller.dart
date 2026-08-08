import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/auth_error_mapper.dart';
import '../../../../core/providers/supabase_providers.dart';
import '../../../business/presentation/controllers/business_controller.dart';
import '../../data/offer_repository.dart';
import '../../domain/entities/offer.dart';

final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return OfferRepository(ref.watch(supabaseProvider));
});

/// Isletmenin kendi ilanlari.
final myOffersProvider = FutureProvider<List<Offer>>((ref) async {
  final business = await ref.watch(myBusinessProvider.future);
  if (business == null) return [];

  return ref.watch(offerRepositoryProvider).fetchMyOffers(business.name);
});

class OfferUiState {
  const OfferUiState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  OfferUiState copyWith({bool? isLoading, String? errorMessage}) {
    return OfferUiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class OfferController extends StateNotifier<OfferUiState> {
  OfferController(this._repo, this._ref) : super(const OfferUiState());

  final OfferRepository _repo;
  final Ref _ref;

  Future<bool> createOffer({
    required String title,
    required FoodType foodType,
    required double price,
    required int quantity,
    required DateTime pickupStart,
    required DateTime pickupEnd,
    String? description,
    double? originalPrice,
  }) async {
    return _run(() => _repo.createOffer(
          title: title.trim(),
          foodType: foodType,
          price: price,
          quantity: quantity,
          pickupStart: pickupStart,
          pickupEnd: pickupEnd,
          description: description?.trim(),
          originalPrice: originalPrice,
        ));
  }

  Future<bool> cancelOffer(String offerId) async {
    return _run(() => _repo.cancelOffer(offerId));
  }

  void clearError() => state = state.copyWith();

  Future<bool> _run(Future<void> Function() action) async {
    state = const OfferUiState(isLoading: true);
    try {
      await action();
      _ref.invalidate(myOffersProvider);
      state = const OfferUiState();
      return true;
    } catch (e) {
      state = OfferUiState(errorMessage: mapAuthError(e));
      return false;
    }
  }
}

final offerControllerProvider =
    StateNotifierProvider<OfferController, OfferUiState>((ref) {
  return OfferController(ref.watch(offerRepositoryProvider), ref);
});