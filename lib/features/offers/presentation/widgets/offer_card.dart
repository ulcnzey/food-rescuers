import 'package:flutter/material.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/walking_time.dart';
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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Isletme adi + puan
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          offer.businessName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (offer.rating > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                offer.rating.toStringAsFixed(1),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Urun adi
                  Text(
                    offer.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Alt bilgi satiri: yuruyus, alim saati, fiyat
                  Row(
                    children: [
                      _MetaItem(
                        icon: Icons.directions_walk_rounded,
                        text: WalkingTime.isWalkable(offer.distanceKm)
                            ? WalkingTime.label(offer.distanceKm)
                            : offer.distanceLabel,
                      ),
                      _Dot(color: theme.colorScheme.outline),
                      _MetaItem(
                        icon: Icons.schedule_rounded,
                        text: offer.pickupWindowLabel,
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

/// Ustteki gorsel alani. Logo sol ust kosede, rozetler uzerinde.
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
      height: 150,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
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

          // Ust ve alt karartma: rozet ve logonun okunmasi icin
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black26,
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black26,
                ],
                stops: [0, 0.35, 0.65, 1],
              ),
            ),
          ),

          // ---- Sol ust: isletme logosu
          Positioned(
            left: AppSpacing.sm,
            top: AppSpacing.sm,
            child: _LogoBadge(logoUrl: offer.businessLogo, style: style),
          ),

          // ---- Sag ust: favori
          Positioned(
            right: AppSpacing.sm,
            top: AppSpacing.sm,
            child: _FavoriteButton(
              isFavorite: isFavorite,
              onTap: onFavoriteToggle,
            ),
          ),

          // ---- Sol alt: indirim / ucretsiz + son firsat
          Positioned(
            left: AppSpacing.sm,
            bottom: AppSpacing.sm,
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
                  const SizedBox(width: 5),
                  _Badge(
                    text: 'Son ${offer.quantityAvailable}',
                    color: AppColors.error,
                  ),
                ],
              ],
            ),
          ),

          // ---- Sag alt: kalan sure
          Positioned(
            right: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: _Badge(
              text: offer.timeLeftLabel,
              color: Colors.black.withValues(alpha: 0.6),
              icon: Icons.timer_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

/// Isletme logosu rozeti. Beyaz cerceveli, gorselin uzerinde durur.
class _LogoBadge extends StatelessWidget {
  const _LogoBadge({required this.logoUrl, required this.style});

  final String? logoUrl;
  final FoodTypeStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: logoUrl != null
            ? Image.network(
                logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => DecoratedBox(
        decoration: BoxDecoration(color: style.color.withValues(alpha: 0.15)),
        child: Center(child: Icon(style.icon, size: 20, color: style.color)),
      );
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
                style.color.withValues(alpha: 0.32),
                style.color.withValues(alpha: 0.12),
              ],
            ),
          ),
        ),
        Center(
          child: Icon(
            style.icon,
            size: 54,
            color: style.color.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
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
          color: Colors.white.withValues(alpha: 0.94),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 6,
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
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
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.freeBadge.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Text(
          'Ücretsiz',
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.freeBadge,
            fontWeight: FontWeight.w800,
          ),
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
          const SizedBox(width: 4),
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