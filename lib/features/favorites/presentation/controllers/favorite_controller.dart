import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../data/favorite_repository.dart';
import '../../domain/entities/favorite_business.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(ref.watch(supabaseProvider));
});

/// Favori isletme kimlikleri. Kartlarda kalp durumunu belirler.
class FavoriteIdsController extends StateNotifier<Set<String>> {
  FavoriteIdsController(this._repo) : super({}) {
    load();
  }

  final FavoriteRepository _repo;

  Future<void> load() async {
    try {
      state = await _repo.fetchIds();
    } catch (_) {
      // Favori listesi alinamazsa uygulama calismaya devam etsin.
    }
  }

  /// Iyimser guncelleme: once arayuz degisir, sonra sunucu.
  /// Hata olursa eski duruma donulur.
  Future<void> toggle(String businessId) async {
    final wasFavorite = state.contains(businessId);

    state = wasFavorite
        ? ({...state}..remove(businessId))
        : {...state, businessId};

    try {
      await _repo.toggle(businessId);
    } catch (_) {
      state = wasFavorite
          ? {...state, businessId}
          : ({...state}..remove(businessId));
    }
  }

  bool isFavorite(String businessId) => state.contains(businessId);
}

final favoriteIdsProvider =
    StateNotifierProvider<FavoriteIdsController, Set<String>>((ref) {
  ref.watch(authStateProvider);
  return FavoriteIdsController(ref.watch(favoriteRepositoryProvider));
});

/// Favoriler ekrani icin tam liste.
final myFavoritesProvider = FutureProvider<List<FavoriteBusiness>>((ref) async {
  // Kalp durumu degisince liste de tazelensin.
  ref.watch(favoriteIdsProvider);
  return ref.watch(favoriteRepositoryProvider).fetchAll();
});