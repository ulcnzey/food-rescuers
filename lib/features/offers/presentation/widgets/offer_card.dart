import 'package:flutter/material.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/offer.dart';
import 'food_type_style.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.offer,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final Offer offer;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = FoodTypeStyle.of(offer.foodType);

    return BouncyTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: theme.colorScheme.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImageArea(
              offer: offer,
              style: style,
              isFavorite: isFavorite,
              onFavoriteToggle: onFavoriteToggle,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: style.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(style.icon, size: 15, color: style.color),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          offer.businessName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (offer.rating > 0) ...[
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          offer.rating.toStringAsFixed(1),
                          style: theme.textTheme.labelLarge,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    offer.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        offer.distanceLabel,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${offer.quantityAvailable} adet',
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      _PriceTag(offer: offer),
                    ],
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

/// Ustteki gorsel alani + rozetler
class _ImageArea extends StatelessWidget {
  const _ImageArea({
    required this.offer,
    required this.style,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  final Offer offer;
  final FoodTypeStyle style;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gercek fotograf varsa onu, yoksa kategori gradyani.
          if (offer.imageUrl != null)
            Image.network(
              offer.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _GradientFallback(style: style),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _GradientFallback(style: style),
            )
          else
            _GradientFallback(style: style),

          // Alt tarafta okunabilirlik icin karartma
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Colors.black26, Colors.transparent],
              ),
            ),
          ),

          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: Row(
              children: [
                if (offer.isFree)
                  const _Badge(text: 'ÜCRETSİZ', color: AppColors.freeBadge)
                else if (offer.discountPercent > 0)
                  _Badge(
                    text: '%${offer.discountPercent} indirim',
                    color: AppColors.secondary,
                  ),
                if (offer.isLastChance) ...[
                  const SizedBox(width: 6),
                  _Badge(
                    text: offer.quantityAvailable == 1
                        ? 'Son 1 adet'
                        : 'Son ${offer.quantityAvailable} adet',
                    color: AppColors.error,
                  ),
                ],
              ],
            ),
          ),

          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: _FavoriteButton(
              isFavorite: isFavorite,
              onTap: onFavoriteToggle,
            ),
          ),

          Positioned(
            bottom: AppSpacing.sm,
            left: AppSpacing.sm,
            child: _Badge(
              text: '${offer.timeLeftLabel} kaldı',
              color: Colors.black.withValues(alpha: 0.6),
              icon: Icons.schedule_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientFallback extends StatelessWidget {
  const _GradientFallback({required this.style});

  final FoodTypeStyle style;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                style.color.withValues(alpha: 0.30),
                style.color.withValues(alpha: 0.10),
              ],
            ),
          ),
        ),
        Center(
          child: Icon(
            style.icon,
            size: 52,
            color: style.color.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      scale: 0.85,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            key: ValueKey(isFavorite),
            size: 18,
            color: isFavorite ? AppColors.error : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (offer.isFree) {
      return Text(
        'Ücretsiz',
        style: theme.textTheme.titleMedium?.copyWith(
          color: AppColors.freeBadge,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (offer.originalPrice > 0) ...[
          Text(
            '${offer.originalPrice.toStringAsFixed(0)}₺',
            style: theme.textTheme.bodySmall?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 5),
        ],
        Text(
          '${offer.price.toStringAsFixed(0)}₺',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}