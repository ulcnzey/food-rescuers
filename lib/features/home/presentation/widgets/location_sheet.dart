import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/location_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../business/presentation/screens/location_picker_screen.dart';
import '../controllers/home_controller.dart';

/// Konum secme alt sayfasini acar.
Future<void> showLocationSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _LocationSheet(),
  );
}

class _LocationSheet extends ConsumerWidget {
  const _LocationSheet();

  /// Haritadan yeni konum secer, istege bagli olarak kaydeder.
  Future<void> _pickAndUse(BuildContext context, WidgetRef ref) async {
    final current = ref.read(locationControllerProvider).location;

    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: current?.latitude,
          initialLng: current?.longitude,
        ),
      ),
    );

    if (picked == null || !context.mounted) return;

    ref.read(locationControllerProvider.notifier).setManual(
          picked.latitude,
          picked.longitude,
          picked.address,
        );

    Navigator.of(context).pop();

    // Kaydetmek isteyip istemedigini sor.
    if (!context.mounted) return;
    await _askToSave(context, ref, picked);
  }

  Future<void> _askToSave(
    BuildContext context,
    WidgetRef ref,
    PickedLocation picked,
  ) async {
    final controller = TextEditingController();

    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bu konumu kaydet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              picked.address,
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Ev, İş, Okul...'),
              onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: ['Ev', 'İş', 'Okul'].map((s) {
                return ActionChip(
                  label: Text(s),
                  onPressed: () => Navigator.of(ctx).pop(s),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Şimdi değil'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    // Diyalog kapanma animasyonu bitmeden dispose edilirse
    // widget agaci silinmis controller'a erisir.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());

    if (label == null || label.isEmpty || !context.mounted) return;

    final ok = await ref.read(locationSaveControllerProvider.notifier).save(
          label: label,
          latitude: picked.latitude,
          longitude: picked.longitude,
          address: picked.address,
        );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '$label olarak kaydedildi' : 'Kaydedilemedi'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final saved = ref.watch(savedLocationsProvider);
    final current = ref.watch(locationControllerProvider);

    // Kayitli adres secili degilse "mevcut konum" vurgulanir.
    final usingCurrent = !(current.location?.isSaved ?? false);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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

            Text('Teslim alma konumu', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Yakınındaki ilanlar bu konuma göre listelenir.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ---- Mevcut konum
            _LocationTile(
              icon: Icons.my_location_rounded,
              title: 'Mevcut konumum',
              subtitle: usingCurrent
                  ? (current.location?.label ?? 'GPS ile bul')
                  : 'GPS ile bul',
              isSelected: usingCurrent,
              onTap: () async {
                Navigator.of(context).pop();
                await ref
                    .read(locationControllerProvider.notifier)
                    .resolveCurrent();
              },
            ),

            const SizedBox(height: AppSpacing.sm),

            // ---- Kayitli konumlar
            saved.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (list) {
                if (list.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                      ),
                      child: Text(
                        'Kayıtlı adreslerin',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    ...list.map(
                      (loc) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _LocationTile(
                          icon: loc.icon,
                          title: loc.label,
                          subtitle: loc.address ?? 'Kayıtlı konum',
                          isSelected: !usingCurrent &&
                              current.location?.label == loc.label,
                          onTap: () {
                            // Kayitli adreste kullanicinin verdigi ad korunur.
                            ref
                                .read(locationControllerProvider.notifier)
                                .setSavedLocation(
                                  latitude: loc.latitude,
                                  longitude: loc.longitude,
                                  label: loc.label,
                                  address: loc.address,
                                );
                            Navigator.of(context).pop();
                          },
                          onDelete: () => ref
                              .read(locationSaveControllerProvider.notifier)
                              .delete(loc.id),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // ---- Haritadan sec
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pickAndUse(context, ref),
                icon: const Icon(Icons.map_outlined, size: 20),
                label: const Text('Haritadan konum seç'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isSelected = false,
    this.onDelete,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isSelected;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.08)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : theme.colorScheme.outline,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}