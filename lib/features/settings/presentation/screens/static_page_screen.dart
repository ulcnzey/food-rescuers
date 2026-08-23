import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../controllers/settings_controller.dart';
import '../widgets/markdown_text.dart';

class StaticPageScreen extends ConsumerWidget {
  const StaticPageScreen({
    super.key,
    required this.slug,
    required this.fallbackTitle,
  });

  final String slug;
  final String fallbackTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(staticPageProvider(slug));

    return Scaffold(
      appBar: AppBar(
        title: Text(async.valueOrNull?.title ?? fallbackTitle),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),

          error: (_, _) => EmptyState(
            art: EmptyStateArt.noResults,
            title: 'İçerik yüklenemedi',
            message: 'Bağlantını kontrol edip tekrar deneyebilirsin.',
            actionLabel: 'Tekrar Dene',
            onAction: () => ref.invalidate(staticPageProvider(slug)),
          ),

          data: (page) {
            if (page == null) {
              return const EmptyState(
                art: EmptyStateArt.noResults,
                title: 'İçerik bulunamadı',
                message: 'Bu sayfa henüz hazırlanmamış.',
              );
            }

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                MarkdownText(content: page.content),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Son güncelleme: '
                  '${page.updatedAt.day.toString().padLeft(2, '0')}.'
                  '${page.updatedAt.month.toString().padLeft(2, '0')}.'
                  '${page.updatedAt.year}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            );
          },
        ),
      ),
    );
  }
}