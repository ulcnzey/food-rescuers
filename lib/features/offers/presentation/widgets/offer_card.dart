import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/offer.dart';
import 'food_type_style.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer, this.onTap});

  final Offer offer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = FoodTypeStyle.of(offer.foodType);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ImageArea(offer: offer, style: style),
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
                        Icon(Icons.star_rounded,
                            size: 16, color: AppColors.secondary),
                        const SizedBox(width: 2),
                        Text(
                          offer.rating.toStringAsFixed(1),
                          style: theme.textTheme.labelLarge,
                        ),
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
                        Icon(Icons.place_outlined,
                            size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(offer.distanceLabel,
                            style: theme.textTheme.bodySmall),
                        const SizedBox(width: AppSpacing.md),
                        Icon(Icons.inventory_2_outlined,
                            size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text('${offer.quantityAvailable} adet',
                            style: theme.textTheme.bodySmall),
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
      ),
    );
  }
}

/// Ustteki renkli gorsel alani + rozetler
class _ImageArea extends StatelessWidget {
  const _ImageArea({required this.offer, required this.style});

  final Offer offer;
  final FoodTypeStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      width: double.infinity,
      child: Stack(
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
            child: Icon(style.icon,
                size: 52, color: style.color.withValues(alpha: 0.55)),
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
                  const _Badge(text: 'Son fırsat', color: AppColors.error),
                ],
              ],
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: _CircleIcon(
              icon: Icons.favorite_border_rounded,
              onTap: () {},
            ),
          ),
          Positioned(
            bottom: AppSpacing.sm,
            left: AppSpacing.sm,
            child: _Badge(
              text: '${offer.timeLeftLabel} kaldı',
              color: Colors.black.withValues(alpha: 0.55),
              icon: Icons.schedule_rounded,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.favorite_border_rounded,
              size: 18, color: Colors.black87),
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
        Text(
          '${offer.originalPrice.toStringAsFixed(0)}₺',
          style: theme.textTheme.bodySmall?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 5),
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