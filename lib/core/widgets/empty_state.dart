import 'package:flutter/material.dart';

import '../illustrations/app_illustrations.dart';
import '../illustrations/empty_basket_illustration.dart';
import '../theme/app_spacing.dart';

/// Kullanilabilir illustrasyon turleri.
enum EmptyStateArt { basket, noResults, success, storefront }

/// Bos liste, sonuc yok ve basari durumlari icin standart gorunum.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.art = EmptyStateArt.basket,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String message;
  final EmptyStateArt art;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            switch (art) {
              EmptyStateArt.basket => const EmptyBasketIllustration(size: 200),
              EmptyStateArt.noResults => const NoResultsIllustration(size: 200),
              EmptyStateArt.success => const SuccessIllustration(size: 200),
              EmptyStateArt.storefront =>
                const StorefrontIllustration(size: 200),
            },
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 240,
                child: FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}