import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../data/home_repository.dart';
import '../../domain/entities/banner_item.dart';
import '../../domain/entities/saved_location.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(supabaseProvider));
});

/// Kullanici tarafi bannerlari.
final bannersProvider = FutureProvider<List<BannerItem>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchBanners();
});

/// Isletme paneli bannerlari.
final businessBannersProvider = FutureProvider<List<BannerItem>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchBusinessBanners();
});

final savedLocationsProvider =
    FutureProvider<List<SavedLocation>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(homeRepositoryProvider).fetchLocations();
});

class LocationSaveController extends StateNotifier<bool> {
  LocationSaveController(this._repo, this._ref) : super(false);

  final HomeRepository _repo;
  final Ref _ref;

  Future<bool> save({
    required String label,
    required double latitude,
    required double longitude,
    String? address,
    bool isDefault = false,
  }) async {
    state = true;
    try {
      await _repo.saveLocation(
        label: label.trim(),
        latitude: latitude,
        longitude: longitude,
        address: address,
        isDefault: isDefault,
      );
      _ref.invalidate(savedLocationsProvider);
      return true;
    } catch (_) {
      return false;
    } finally {
      state = false;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repo.deleteLocation(id);
      _ref.invalidate(savedLocationsProvider);
    } catch (_) {
      // Silme basarisiz olsa da akisi bozmuyoruz.
    }
  }
}

final locationSaveControllerProvider =
    StateNotifierProvider<LocationSaveController, bool>((ref) {
  return LocationSaveController(ref.watch(homeRepositoryProvider), ref);
});