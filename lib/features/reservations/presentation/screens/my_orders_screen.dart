import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../offers/presentation/widgets/food_type_style.dart';
import '../../domain/entities/reservation.dart';
import '../controllers/reservation_controller.dart';
import '../widgets/qr_ticket.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key, this.onDiscover});

  final VoidCallback? onDiscover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(myReservationsProvider);

    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),

          error: (_, _) => EmptyState(
            art: EmptyStateArt.noResults,
            title: 'Siparişler yüklenemedi',
            message: 'Bağlantını kontrol edip tekrar deneyebilirsin.',
            actionLabel: 'Tekrar Dene',
            onAction: () => ref.invalidate(myReservationsProvider),
          ),

          data: (all) {
            if (all.isEmpty) {
              return EmptyState(
                title: 'Henüz siparişin yok',
                message: 'Bir fırsat rezerve ettiğinde siparişin ve QR kodun '
                    'burada görünecek.',
                actionLabel: 'Fırsatları Keşfet',
                onAction: onDiscover,
              );
            }

            final active = all.where((r) => r.isActive).toList();
            final past = all.where((r) => !r.isActive).toList();

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(myReservationsProvider),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Text('Siparişlerim', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.lg),

                  if (active.isNotEmpty) ...[
                    _SectionTitle(
                      title: 'Aktif',
                      count: active.length,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...active.asMap().entries.map(
                          (e) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.lg),
                            child: FadeSlideIn(
                              index: e.key,
                              child: _ActiveOrderCard(reservation: e.value),
                            ),
                          ),
                        ),
                  ],

                  if (past.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _SectionTitle(
                      title: 'Geçmiş',
                      count: past.length,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...past.asMap().entries.map(
                          (e) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: FadeSlideIn(
                              index: active.length + e.key,
                              child: _PastOrderTile(reservation: e.value),
                            ),
                          ),
                        ),
                  ],

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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.count,
    required this.color,
  });

  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(width: 4, height: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 6),
        Text(
          '($count)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Aktif siparis: QR bilet acilir halde gosterilir.
class _ActiveOrderCard extends ConsumerStatefulWidget {
  const _ActiveOrderCard({required this.reservation});

  final Reservation reservation;

  @override
  ConsumerState<_ActiveOrderCard> createState() => _ActiveOrderCardState();
}

class _ActiveOrderCardState extends ConsumerState<_ActiveOrderCard> {
  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
        title: const Text('Rezervasyonu iptal et'),
        content: const Text(
          'Bu ürün tekrar satışa açılacak ve başkası alabilir. '
          'İptal etmek istediğine emin misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await ref
        .read(reservationControllerProvider.notifier)
        .cancel(widget.reservation.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Rezervasyon iptal edildi' : 'İptal edilemedi'),
        backgroundColor: ok ? null : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.reservation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kalan sure uyarisi
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                '${r.timeLeftLabel} içinde teslim al',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        QrTicket(reservation: r),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            if (r.businessAddress != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Yol Tarifi'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ),
            if (r.businessAddress != null) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _cancel,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('İptal Et'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Gecmis siparis: kompakt satir.
class _PastOrderTile extends StatelessWidget {
  const _PastOrderTile({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = FoodTypeStyle.of(reservation.foodType);

    final statusColor = switch (reservation.status) {
      ReservationStatus.completed => AppColors.success,
      ReservationStatus.cancelled => AppColors.error,
      _ => theme.colorScheme.onSurfaceVariant,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(style.icon, size: 20, color: style.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.offerTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  reservation.businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  reservation.isExpiredNow
                      ? 'Süresi doldu'
                      : reservation.status.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                reservation.isFree
                    ? 'Ücretsiz'
                    : '${reservation.totalPrice.toStringAsFixed(0)}₺',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}