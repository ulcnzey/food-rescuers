import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/illustrations/app_illustrations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../shell/presentation/screens/main_shell.dart';
import '../../domain/entities/reservation.dart';
import '../widgets/qr_ticket.dart';

/// Rezervasyon tamamlandiginda gosterilen kutlama ekrani.
class ReservationSuccessScreen extends ConsumerWidget {
  const ReservationSuccessScreen({super.key, required this.reservation});

  final Reservation reservation;

  void _goToOrders(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 2)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    const SuccessIllustration(size: 160),
                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Rezervasyonun hazır!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Belirtilen saatte işletmeye git ve bu QR kodu göster.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    FadeSlideIn(
                      index: 1,
                      child: QrTicket(reservation: reservation),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Hatirlatma
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.10),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Alım saatini kaçırırsan rezervasyonun otomatik '
                              'iptal olur ve ürün başkasına gider.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _goToOrders(context),
                      child: const Text('Siparişlerime Git'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MainShell()),
                        (route) => false,
                      );
                    },
                    child: const Text('Keşfetmeye Devam Et'),
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