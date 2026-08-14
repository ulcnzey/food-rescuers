import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Salt okunur yildiz gostergesi.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.color = AppColors.secondary,
  });

  final double rating;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= i + 1;
        final half = !filled && rating > i;

        return Icon(
          half
              ? Icons.star_half_rounded
              : (filled ? Icons.star_rounded : Icons.star_outline_rounded),
          size: size,
          color: (filled || half)
              ? color
              : Theme.of(context).colorScheme.outline,
        );
      }),
    );
  }
}

/// Dokunarak puan verilen yildizlar.
class StarInput extends StatelessWidget {
  const StarInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 44,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  static const _labels = [
    '',
    'Çok kötü',
    'Kötü',
    'İdare eder',
    'İyi',
    'Harika!',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final star = i + 1;
            final active = value >= star;

            return GestureDetector(
              onTap: () => onChanged(star),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedScale(
                  scale: active ? 1.0 : 0.88,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    active ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: size,
                    color: active
                        ? AppColors.secondary
                        : theme.colorScheme.outline,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _labels[value],
            key: ValueKey(value),
            style: theme.textTheme.titleSmall?.copyWith(
              color: value == 0
                  ? theme.colorScheme.onSurfaceVariant
                  : AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartlarda kullanilan kompakt puan rozeti: ★ 4.4 (12)
class RatingBadge extends StatelessWidget {
  const RatingBadge({
    super.key,
    required this.rating,
    this.count,
    this.compact = false,
  });

  final double rating;
  final int? count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (rating <= 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: compact ? 12 : 14,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
              fontSize: compact ? 11 : 12,
            ),
          ),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 2),
            Text(
              '($count)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.secondary.withValues(alpha: 0.75),
                fontSize: compact ? 10 : 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}