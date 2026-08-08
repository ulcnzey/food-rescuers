import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/reservation.dart';

/// Musteriye gosterilen QR bilet.
/// Kagit bilet gorunumu icin kenarlarda kertik ve kesik cizgi var.
class QrTicket extends StatelessWidget {
  const QrTicket({super.key, required this.reservation, this.compact = false});

  final Reservation reservation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUsable = reservation.isActive;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ---- Ust kisim: QR
          Padding(
            padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
            child: Column(
              children: [
                Text(
                  reservation.businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  reservation.offerTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),

                // QR kod. Kullanilamaz durumdaysa soluklastirilir.
                Opacity(
                  opacity: isUsable ? 1 : 0.25,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: QrImageView(
                      data: reservation.qrToken,
                      version: QrVersions.auto,
                      size: compact ? 130 : 190,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.circle,
                        color: AppColors.primaryDark,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.circle,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),

                if (!isUsable) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: Text(
                      reservation.isExpiredNow
                          ? 'Süresi doldu'
                          : reservation.status.displayName,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: AppColors.error),
                    ),
                  ),
                ],

                SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),

                // ---- Yedek dogrulama kodu
                Text(
                  'Doğrulama kodu',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _spaced(reservation.pickupCode),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    letterSpacing: 4,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),

          // ---- Kertikli ayirici
          const _NotchedDivider(),

          // ---- Alt kisim: detaylar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: _Detail(
                    label: 'Alım',
                    value: reservation.pickupWindowLabel,
                    sub: reservation.dateLabel,
                  ),
                ),
                Expanded(
                  child: _Detail(
                    label: 'Adet',
                    value: '${reservation.quantity}',
                    sub: 'paket',
                  ),
                ),
                Expanded(
                  child: _Detail(
                    label: 'Tutar',
                    value: reservation.isFree
                        ? 'Ücretsiz'
                        : '${reservation.totalPrice.toStringAsFixed(0)}₺',
                    sub: reservation.isFree ? 'bağış' : 'teslimde',
                    highlight: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "123456" -> "123 456"
  static String _spaced(String code) {
    if (code.length != 6) return code;
    return '${code.substring(0, 3)} ${code.substring(3)}';
  }
}

/// Iki yanindan kertikli, ortasi kesik cizgili ayirici.
/// Kagit bilet hissi verir.
class _NotchedDivider extends StatelessWidget {
  const _NotchedDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;

    return SizedBox(
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Kesik cizgi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(
              builder: (context, c) {
                const dash = 6.0;
                const gap = 5.0;
                final count = (c.maxWidth / (dash + gap)).floor();

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    count,
                    (_) => Container(
                      width: dash,
                      height: 1.5,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                );
              },
            ),
          ),
          // Sol kertik
          Positioned(
            left: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            ),
          ),
          // Sag kertik
          Positioned(
            right: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.label,
    required this.value,
    required this.sub,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String sub;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: highlight ? AppColors.primary : null,
          ),
        ),
        Text(
          sub,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}