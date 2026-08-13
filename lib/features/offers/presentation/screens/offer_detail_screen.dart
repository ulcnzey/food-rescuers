import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/providers/location_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

import '../../../reservations/presentation/controllers/reservation_controller.dart';
import '../../../reservations/presentation/screens/reservation_success_screen.dart';
import '../../domain/entities/offer_detail.dart';
import '../controllers/offer_controller.dart';
import '../widgets/food_type_style.dart';
import '../../../favorites/presentation/controllers/favorite_controller.dart';

class OfferDetailScreen extends ConsumerStatefulWidget {
  const OfferDetailScreen({super.key, required this.offerId});

  final String offerId;

  @override
  ConsumerState<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends ConsumerState<OfferDetailScreen> {
  int _quantity = 1;

  Future<void> _reserve(OfferDetail offer) async {
    final confirmed = await _showConfirmSheet(offer);
    if (confirmed != true || !mounted) return;

    final reservation =
        await ref.read(reservationControllerProvider.notifier).reserve(
              offerId: offer.id,
              quantity: _quantity,
            );

    if (!mounted) return;

    if (reservation == null) {
      final error = ref.read(reservationControllerProvider).errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Basarili: kutlama ekranina gec, detay ekranini gecmisten cikar.
    Navigator.of(context).pushReplacement(
      SmoothPageRoute<void>(
        page: ReservationSuccessScreen(reservation: reservation),
      ),
    );
  }

  Future<bool?> _showConfirmSheet(OfferDetail offer) {
    final theme = Theme.of(context);
    final total = offer.price * _quantity;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Rezervasyonu onayla', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),

              _SummaryRow(label: 'Ürün', value: offer.title),
              _SummaryRow(label: 'İşletme', value: offer.businessName),
              _SummaryRow(label: 'Adet', value: '$_quantity'),
              _SummaryRow(
                label: 'Alım saati',
                value: '${offer.dateLabel} ${offer.pickupWindowLabel}',
              ),

              const Divider(height: AppSpacing.xl),

              Row(
                children: [
                  Text('Ödenecek', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  Text(
                    offer.isFree ? 'Ücretsiz' : '${total.toStringAsFixed(0)} ₺',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: offer.isFree
                          ? AppColors.freeBadge
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      size: 20,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        offer.isFree
                            ? 'Bu bir bağış. Belirtilen saatte gidip QR kodunu göstermen yeterli.'
                            : 'Ödemeyi teslim alırken işletmeye yapacaksın.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Rezerve Et'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Vazgeç'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationControllerProvider).location;

    final query = OfferDetailQuery(
      offerId: widget.offerId,
      latitude: location?.latitude,
      longitude: location?.longitude,
    );

    final detailAsync = ref.watch(offerDetailProvider(query));

    return Scaffold(
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (_, _) => _ErrorView(
          onRetry: () => ref.invalidate(offerDetailProvider(query)),
        ),

        data: (offer) => _Content(
          offer: offer,
          quantity: _quantity,
          onQuantityChanged: (v) => setState(() => _quantity = v),
          onReserve: () => _reserve(offer),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- ICERIK

class _Content extends ConsumerWidget {
  const _Content({
    required this.offer,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onReserve,
  });

  final OfferDetail offer;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final style = FoodTypeStyle.of(offer.foodType);
    final state = ref.watch(reservationControllerProvider);
    final isFavorite = ref.watch(favoriteIdsProvider).contains(offer.businessId);

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // ---- Gorsel basligi
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: theme.colorScheme.surface,
              leading: _CircleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
              actions: [
                _CircleButton(
                  icon: isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? AppColors.error : Colors.black87,
                  onTap: () => ref
                      .read(favoriteIdsProvider.notifier)
                      .toggle(offer.businessId),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _HeroImage(offer: offer, style: style),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- Baslik + fiyat
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            offer.title,
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _PriceBlock(offer: offer),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // ---- Isletme satiri
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: style.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            offer.isIndividualProvider
                                ? Icons.volunteer_activism_rounded
                                : Icons.storefront_rounded,
                            size: 17,
                            color: style.color,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offer.businessName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (offer.isIndividualProvider)
                                Text(
                                  'Bireysel paylaşımcı',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.success,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (offer.businessRatingCount > 0) ...[
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            offer.businessRating.toStringAsFixed(1),
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            ' (${offer.businessRatingCount})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ---- Bilgi kutulari
                    Row(
                      children: [
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.schedule_rounded,
                            label: 'Alım saati',
                            value: offer.pickupWindowLabel,
                            sub: offer.dateLabel,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.place_outlined,
                            label: 'Mesafe',
                            value: offer.distanceLabel.isEmpty
                                ? '—'
                                : offer.distanceLabel,
                            sub: 'Yürüyerek',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ---- Stok gostergesi
                    _StockBar(offer: offer),

                    if (offer.description != null &&
                        offer.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Bu pakette ne var?',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        offer.description!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // ---- Adres
                    if (offer.businessAddress != null) ...[
                      Text(
                        'Nereden alacaksın?',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                offer.businessAddress!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // ---- Odeme bilgisi
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Uygulama üzerinden ödeme alınmaz. '
                              'Ürünü teslim alırken işletmeye ödersin.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Alt butonun altinda kalmamasi icin bosluk
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ---- Sabit alt cubuk
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomBar(
            offer: offer,
            quantity: quantity,
            isLoading: state.isLoading,
            onQuantityChanged: onQuantityChanged,
            onReserve: onReserve,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- PARCALAR

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.offer, required this.style});

  final OfferDetail offer;
  final FoodTypeStyle style;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (offer.imageUrl != null)
          Image.network(
            offer.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(),
            loadingBuilder: (c, child, p) => p == null ? child : _fallback(),
          )
        else
          _fallback(),

        // Ust kisimda butonlarin okunabilmesi icin karartma
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Colors.black38, Colors.transparent],
            ),
          ),
        ),

        Positioned(
          left: AppSpacing.md,
          bottom: AppSpacing.md,
          child: Row(
            children: [
              if (offer.isFree)
                const _Badge(text: 'ÜCRETSİZ', color: AppColors.freeBadge)
              else if (offer.discountPercent > 0)
                _Badge(
                  text: '%${offer.discountPercent} indirim',
                  color: AppColors.secondary,
                ),
              const SizedBox(width: 6),
              _Badge(
                text: '${offer.timeLeftLabel} kaldı',
                color: Colors.black.withValues(alpha: 0.6),
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallback() => Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  style.color.withValues(alpha: 0.35),
                  style.color.withValues(alpha: 0.12),
                ],
              ),
            ),
          ),
          Center(
            child: Icon(
              style.icon,
              size: 88,
              color: style.color.withValues(alpha: 0.5),
            ),
          ),
        ],
      );
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.color,
    this.icon,
  });

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.offer});

  final OfferDetail offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (offer.isFree) {
      return Text(
        'Ücretsiz',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: AppColors.freeBadge,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (offer.originalPrice > 0)
          Text(
            '${offer.originalPrice.toStringAsFixed(0)}₺',
            style: theme.textTheme.bodyMedium?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        Text(
          '${offer.price.toStringAsFixed(0)}₺',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            sub,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockBar extends StatelessWidget {
  const _StockBar({required this.offer});

  final OfferDetail offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final low = offer.quantityAvailable <= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              low ? 'Son ${offer.quantityAvailable} adet!' : 'Kalan adet',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: low ? AppColors.error : null,
              ),
            ),
            const Spacer(),
            Text(
              '${offer.quantityAvailable} / ${offer.quantityTotal}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: offer.stockRatio),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: theme.colorScheme.outline,
              color: low ? AppColors.error : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.offer,
    required this.quantity,
    required this.isLoading,
    required this.onQuantityChanged,
    required this.onReserve,
  });

  final OfferDetail offer;
  final int quantity;
  final bool isLoading;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final disabledReason = !offer.isAvailable
        ? (offer.quantityAvailable == 0 ? 'Tükendi' : 'Süresi doldu')
        : offer.alreadyReserved
            ? 'Zaten rezerve ettin'
            : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (disabledReason == null) ...[
              _StepButton(
                icon: Icons.remove_rounded,
                enabled: quantity > 1,
                onTap: () => onQuantityChanged(quantity - 1),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              _StepButton(
                icon: Icons.add_rounded,
                enabled: quantity < offer.quantityAvailable,
                onTap: () => onQuantityChanged(quantity + 1),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: FilledButton(
                onPressed:
                    (disabledReason != null || isLoading) ? null : onReserve,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(disabledReason ?? 'Rezerve Et'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: enabled
          ? AppColors.primary.withValues(alpha: 0.12)
          : theme.colorScheme.outline.withValues(alpha: 0.3),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(
            icon,
            size: 20,
            color:
                enabled ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.black87,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: BouncyTap(
        onTap: onTap,
        scale: 0.9,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              icon,
              key: ValueKey(icon),
              size: 20,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('İlan yüklenemedi', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}