import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/auth_error_mapper.dart';
import '../../../../core/providers/supabase_providers.dart';
import '../../../offers/presentation/controllers/offer_controller.dart';
import '../../../reservations/presentation/controllers/reservation_controller.dart';
import '../../data/review_repository.dart';
import '../../domain/entities/review.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(supabaseProvider));
});

final businessReviewsProvider =
    FutureProvider.autoDispose.family<List<Review>, String>(
  (ref, businessId) async {
    return ref.watch(reviewRepositoryProvider).fetchForBusiness(businessId);
  },
);

final ratingBreakdownProvider =
    FutureProvider.autoDispose.family<RatingBreakdown, String>(
  (ref, businessId) async {
    return ref.watch(reviewRepositoryProvider).fetchBreakdown(businessId);
  },
);

class ReviewUiState {
  const ReviewUiState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  ReviewUiState copyWith({bool? isLoading, String? errorMessage}) {
    return ReviewUiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ReviewController extends StateNotifier<ReviewUiState> {
  ReviewController(this._repo, this._ref) : super(const ReviewUiState());

  final ReviewRepository _repo;
  final Ref _ref;

  Future<bool> submit({
    required String reservationId,
    required String businessId,
    required int rating,
    String? comment,
  }) async {
    state = const ReviewUiState(isLoading: true);
    try {
      await _repo.addReview(
        reservationId: reservationId,
        rating: rating,
        comment: comment?.trim().isEmpty == true ? null : comment?.trim(),
      );

      // Puan degisti: liste, dagilim ve ilan verileri tazelensin.
      _ref.invalidate(businessReviewsProvider(businessId));
      _ref.invalidate(ratingBreakdownProvider(businessId));
      _ref.invalidate(myReservationsProvider);
      _ref.invalidate(myOffersProvider);

      state = const ReviewUiState();
      return true;
    } catch (e) {
      state = ReviewUiState(errorMessage: mapAuthError(e));
      return false;
    }
  }

  Future<bool> reply({
    required String reviewId,
    required String businessId,
    required String text,
  }) async {
    state = const ReviewUiState(isLoading: true);
    try {
      await _repo.reply(reviewId: reviewId, text: text.trim());
      _ref.invalidate(businessReviewsProvider(businessId));

      state = const ReviewUiState();
      return true;
    } catch (e) {
      state = ReviewUiState(errorMessage: mapAuthError(e));
      return false;
    }
  }

  void clearError() => state = state.copyWith();
}

final reviewControllerProvider =
    StateNotifierProvider<ReviewController, ReviewUiState>((ref) {
  return ReviewController(ref.watch(reviewRepositoryProvider), ref);
});