import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../offers/presentation/screens/offer_detail_screen.dart';
import '../../domain/entities/app_notification.dart';
import '../controllers/notification_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final hasUnread =
        async.valueOrNull?.any((n) => !n.isRead) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () => ref
                  .read(notificationControllerProvider.notifier)
                  .markAllRead(),
              child: const Text('Tümünü okundu işaretle'),
            ),
        ],
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),

          error: (_, _) => EmptyState(
            art: EmptyStateArt.noResults,
            title: 'Bildirimler yüklenemedi',
            message: 'Bağlantını kontrol edip tekrar deneyebilirsin.',
            actionLabel: 'Tekrar Dene',
            onAction: () => ref.invalidate(notificationsProvider),
          ),

          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                title: 'Henüz bildirimin yok',
                message: 'Rezervasyon yaptığında ve favori işletmelerin '
                    'yeni ilan verdiğinde burada göreceksin.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(notificationsProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: list.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => FadeSlideIn(
                  index: i,
                  delayStep: const Duration(milliseconds: 40),
                  child: _NotificationTile(item: list[i]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item});

  final AppNotification item;

  Color _accent() => switch (item.type) {
        NotificationType.reservationCreated => AppColors.primary,
        NotificationType.newReservation => AppColors.secondary,
        NotificationType.reservationCompleted => AppColors.success,
        NotificationType.newOffer => AppColors.info,
        NotificationType.other => AppColors.primary,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = _accent();

    return BouncyTap(
      onTap: () {
        if (!item.isRead) {
          ref.read(notificationControllerProvider.notifier).markRead(item.id);
        }

        final offerId = item.offerId;
        if (offerId != null) {
          Navigator.of(context).push(
            SmoothPageRoute<void>(
              page: OfferDetailScreen(offerId: offerId),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          // Okunmamis bildirimler hafif renkli zeminle one cikar.
          color: item.isRead
              ? theme.colorScheme.surface
              : accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: item.isRead
                ? theme.colorScheme.outline
                : accent.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(item.type.icon, color: accent, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: item.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.timeAgo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}