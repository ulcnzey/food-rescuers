import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/auth_error_mapper.dart';
import '../../../../core/providers/supabase_providers.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../business/presentation/controllers/business_controller.dart';
import '../../data/offer_repository.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/offer_detail.dart';

final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return OfferRepository(ref.watch(supabaseProvider));
});

final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  return ImageUploadService(ref.watch(supabaseProvider));
});

/// Isletmenin kendi ilanlari.
final myOffersProvider = FutureProvider<List<Offer>>((ref) async {
  final business = await ref.watch(myBusinessProvider.future);
  if (business == null) return [];

  return ref.watch(offerRepositoryProvider).fetchMyOffers(business.name);
});

// ---------------------------------------------------------------- SORGULAR

/// nearbyOffersProvider icin parametre paketi.
/// Esitlik tanimli oldugu icin ayni sorgu tekrar cagrildiginda
/// Riverpod onbellekten donuyor, gereksiz istek atilmiyor.
class NearbyQuery {
  const NearbyQuery({
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 10000,
    this.foodType,
  });

  final double latitude;
  final double longitude;
  final int radiusMeters;
  final FoodType? foodType;

  @override
  bool operator ==(Object other) =>
      other is NearbyQuery &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.radiusMeters == radiusMeters &&
      other.foodType == foodType;

  @override
  int get hashCode => Object.hash(latitude, longitude, radiusMeters, foodType);
}

/// Yakindaki aktif ilanlar. Konum veya kategori degisince yenilenir.
final nearbyOffersProvider =
    FutureProvider.autoDispose.family<List<Offer>, NearbyQuery>(
  (ref, query) async {
    return ref.watch(offerRepositoryProvider).fetchNearby(
          latitude: query.latitude,
          longitude: query.longitude,
          radiusMeters: query.radiusMeters,
          foodType: query.foodType,
        );
  },
);

class OfferDetailQuery {
  const OfferDetailQuery({
    required this.offerId,
    this.latitude,
    this.longitude,
  });

  final String offerId;
  final double? latitude;
  final double? longitude;

  @override
  bool operator ==(Object other) =>
      other is OfferDetailQuery &&
      other.offerId == offerId &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(offerId, latitude, longitude);
}

/// Tek ilanin detayi.
final offerDetailProvider =
    FutureProvider.autoDispose.family<OfferDetail, OfferDetailQuery>(
  (ref, query) async {
    return ref.watch(offerRepositoryProvider).fetchDetail(
          offerId: query.offerId,
          latitude: query.latitude,
          longitude: query.longitude,
        );
  },
);

// ---------------------------------------------------------------- KONTROL

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

  /// Ilan olusturur. Gorsel verilmisse once Storage'a yukler,
  /// donen URL'i ilan kaydina baglar.
  Future<bool> createOffer({
    required String title,
    required FoodType foodType,
    required double price,
    required int quantity,
    required DateTime pickupStart,
    required DateTime pickupEnd,
    String? description,
    double? originalPrice,
    File? imageFile,
  }) async {
    state = const OfferUiState(isLoading: true);

    try {
      String? imageUrl;

      // Gorsel yuklenemezse ilan yine de olusturulur;
      // gorseli sonradan eklemek mumkun.
      if (imageFile != null) {
        final result = await _ref
            .read(imageUploadServiceProvider)
            .upload(file: imageFile, folder: 'offers');

        if (!result.isSuccess) {
          state = OfferUiState(errorMessage: result.error);
          return false;
        }

        imageUrl = result.url;
      }

      await _repo.createOffer(
        title: title.trim(),
        foodType: foodType,
        price: price,
        quantity: quantity,
        pickupStart: pickupStart,
        pickupEnd: pickupEnd,
        description: description?.trim(),
        originalPrice: originalPrice,
        imageUrl: imageUrl,
      );

      _ref.invalidate(myOffersProvider);
      state = const OfferUiState();
      return true;
    } catch (e) {
      state = OfferUiState(errorMessage: mapAuthError(e));
      return false;
    }
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