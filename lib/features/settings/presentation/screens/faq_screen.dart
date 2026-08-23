import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/static_page.dart';
import '../controllers/settings_controller.dart';

class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(faqProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sıkça Sorulan Sorular')),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),

          error: (_, _) => EmptyState(
            art: EmptyStateArt.noResults,
            title: 'Sorular yüklenemedi',
            message: 'Bağlantını kontrol edip tekrar deneyebilirsin.',
            actionLabel: 'Tekrar Dene',
            onAction: () => ref.invalidate(faqProvider),
          ),

          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                art: EmptyStateArt.noResults,
                title: 'Henüz soru yok',
                message: 'Yakında burada sık sorulan sorular olacak.',
              );
            }

            // Kategoriye gore grupla
            final grouped = <String, List<FaqItem>>{};
            for (final item in items) {
              grouped.putIfAbsent(item.category, () => []).add(item);
            }

            var index = 0;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          entry.value.first.categoryLabel,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  ...entry.value.map((item) {
                    final w = Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: FadeSlideIn(
                        index: index,
                        delayStep: const Duration(milliseconds: 35),
                        child: _FaqTile(item: item),
                      ),
                    );
                    index++;
                    return w;
                  }),
                ],
                const SizedBox(height: AppSpacing.xxl),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.item});

  final FaqItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Genisleyen panelin varsayilan ayirici cizgisini kaldiriyoruz.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: AppColors.primary,
          collapsedIconColor: theme.colorScheme.onSurfaceVariant,
          title: Text(
            item.question,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          children: [
            Text(
              item.answer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}