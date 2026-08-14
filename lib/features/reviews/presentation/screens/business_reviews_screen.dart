import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../business/presentation/controllers/business_controller.dart';
import '../../domain/entities/review.dart';
import '../controllers/review_controller.dart';
import '../widgets/star_rating.dart';

class BusinessReviewsScreen extends ConsumerWidget {
  const BusinessReviewsScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(businessReviewsProvider(businessId));
    final breakdown = ref.watch(ratingBreakdownProvider(businessId));

    // Isletme sahibi kendi yorumlarina cevap yazabilir.
    final myBusiness = ref.watch(myBusinessProvider).valueOrNull;
    final isOwner = myBusiness?.id == businessId;

    return Scaffold(
      appBar: AppBar(title: Text(businessName)),
      body: SafeArea(
        child: reviews.when(
          loading: () => const Center(child: CircularProgressIndicator()),

          error: (_, _) => EmptyState(
            art: EmptyStateArt.noResults,
            title: 'Yorumlar yüklenemedi',
            message: 'Bağlantını kontrol edip tekrar deneyebilirsin.',
            actionLabel: 'Tekrar Dene',
            onAction: () => ref.invalidate(businessReviewsProvider(businessId)),
          ),

          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                art: EmptyStateArt.noResults,
                title: 'Henüz değerlendirme yok',
                message: 'Bu işletmeden ilk siparişini alan sen ol, '
                    'deneyimini paylaş.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(businessReviewsProvider(businessId));
                ref.invalidate(ratingBreakdownProvider(businessId));
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  breakdown.when(
                    loading: () => const SizedBox(height: 140),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (b) => _SummaryCard(breakdown: b),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  ...list.asMap().entries.map(
                        (e) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: FadeSlideIn(
                            index: e.key,
                            delayStep: const Duration(milliseconds: 40),
                            child: _ReviewTile(
                              review: e.value,
                              businessId: businessId,
                              canReply: isOwner && !e.value.hasReply,
                            ),
                          ),
                        ),
                      ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- PARCALAR

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.breakdown});

  final RatingBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ortalama
          Column(
            children: [
              CounterText(
                value: breakdown.average,
                decimals: 1,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 4),
              StarRating(rating: breakdown.average, size: 16),
              const SizedBox(height: 4),
              Text(
                '${breakdown.total} değerlendirme',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(width: AppSpacing.lg),

          // Dagilim cubuklari
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final ratio = breakdown.ratioOf(star);
                final count = breakdown.counts[star] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        child: Text(
                          '$star',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: ratio),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, _) =>
                                LinearProgressIndicator(
                              value: v,
                              minHeight: 6,
                              backgroundColor: theme.colorScheme.outline,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 22,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends ConsumerStatefulWidget {
  const _ReviewTile({
    required this.review,
    required this.businessId,
    required this.canReply,
  });

  final Review review;
  final String businessId;
  final bool canReply;

  @override
  ConsumerState<_ReviewTile> createState() => _ReviewTileState();
}

class _ReviewTileState extends ConsumerState<_ReviewTile> {
  final _replyController = TextEditingController();
  bool _replying = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    final ok = await ref.read(reviewControllerProvider.notifier).reply(
          reviewId: widget.review.id,
          businessId: widget.businessId,
          text: _replyController.text,
        );

    if (!mounted) return;

    if (ok) {
      setState(() => _replying = false);
      _replyController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.review;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    r.maskedName.isNotEmpty ? r.maskedName[0] : '?',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.maskedName,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      r.timeAgo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StarRating(rating: r.rating.toDouble(), size: 15),
            ],
          ),

          if (r.comment != null && r.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(r.comment!, style: theme.textTheme.bodyMedium),
          ],

          // ---- Isletme cevabi
          if (r.hasReply) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'İşletme yanıtı',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(r.reply!, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],

          // ---- Cevap yazma (sadece isletme sahibi)
          if (widget.canReply) ...[
            const SizedBox(height: AppSpacing.sm),
            if (!_replying)
              TextButton.icon(
                onPressed: () => setState(() => _replying = true),
                icon: const Icon(Icons.reply_rounded, size: 16),
                label: const Text('Yanıtla'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              )
            else
              Column(
                children: [
                  TextField(
                    controller: _replyController,
                    maxLines: 2,
                    maxLength: 250,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Müşterine yanıt yaz...',
                      isDense: true,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _replying = false),
                        child: const Text('Vazgeç'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton(
                        onPressed: _sendReply,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(90, 40),
                        ),
                        child: const Text('Gönder'),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}