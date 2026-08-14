import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/illustrations/app_illustrations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../offers/presentation/widgets/food_type_style.dart';
import '../../../reservations/domain/entities/reservation.dart';
import '../controllers/review_controller.dart';
import '../widgets/star_rating.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  const WriteReviewScreen({super.key, required this.reservation});

  final Reservation reservation;

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _done = false;

  /// Puana gore onerilen hazir yorumlar.
  static const _quickTags = {
    5: ['Taze ve lezzetliydi', 'Bol miktarda', 'Güler yüzlü', 'Hızlı teslim'],
    4: ['Güzeldi', 'Uygun fiyat', 'Temiz paketleme'],
    3: ['İdare ederdi', 'Beklediğim gibi değildi'],
    2: ['Az miktardaydı', 'Beklettiler'],
    1: ['Tazelik sorunu', 'İlanla uyuşmuyordu'],
  };

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final current = _commentController.text.trim();
    setState(() {
      _commentController.text =
          current.isEmpty ? tag : '$current, ${tag.toLowerCase()}';
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final ok = await ref.read(reviewControllerProvider.notifier).submit(
          reservationId: widget.reservation.id,
          businessId: widget.reservation.businessId,
          rating: _rating,
          comment: _commentController.text,
        );

    if (!mounted || !ok) return;

    setState(() => _done = true);

    // Tesekkur ekranini kisa sure goster, sonra kapat.
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(reviewControllerProvider);
    final r = widget.reservation;
    final style = FoodTypeStyle.of(r.foodType);

    if (_done) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 160,
                height: 160,
                child: SuccessIllustration(size: 160),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Teşekkürler!', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Değerlendirmen diğer kullanıcılara yardımcı olacak.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Değerlendir'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // ---- Isletme karti
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        child: r.offerImageUrl != null
                            ? Image.network(
                                r.offerImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _fallback(style),
                              )
                            : _fallback(style),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.businessName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            r.offerTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'Deneyimin nasıldı?',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),

              StarInput(
                value: _rating,
                onChanged: (v) => setState(() => _rating = v),
              ),

              if (_rating > 0) ...[
                const SizedBox(height: AppSpacing.xl),

                // ---- Hizli etiketler
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: (_quickTags[_rating] ?? []).map((tag) {
                    return ActionChip(
                      label: Text(tag),
                      onPressed: () => _addTag(tag),
                      backgroundColor: theme.colorScheme.surface,
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.lg),

                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Yorumunu yaz (isteğe bağlı)...',
                  ),
                ),
              ],

              if (state.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.colorScheme.outline)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_rating == 0 || state.isLoading) ? null : _submit,
              child: state.isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Değerlendirmeyi Gönder'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallback(FoodTypeStyle style) => DecoratedBox(
        decoration: BoxDecoration(color: style.color.withValues(alpha: 0.15)),
        child: Center(child: Icon(style.icon, size: 24, color: style.color)),
      );
}