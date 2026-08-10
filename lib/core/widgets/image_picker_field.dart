import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Gorsel secme alani. Secili gorsel varsa onizleme,
/// yoksa bos durum gosterir.
class ImagePickerField extends StatelessWidget {
  const ImagePickerField({
    super.key,
    required this.onPick,
    this.localFile,
    this.remoteUrl,
    this.isUploading = false,
    this.onRemove,
    this.height = 180,
    this.label = 'Ürün Görseli',
    this.hint = 'Müşteriler ürünü görselle daha kolay seçiyor',
    this.circular = false,
  });

  /// fromCamera true ise kamera, false ise galeri.
  final Future<void> Function(bool fromCamera) onPick;

  final File? localFile;
  final String? remoteUrl;
  final bool isUploading;
  final VoidCallback? onRemove;
  final double height;
  final String label;
  final String hint;
  final bool circular;

  bool get _hasImage => localFile != null || remoteUrl != null;

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.of(ctx).pop();
                onPick(true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeriden seç'),
              onTap: () {
                Navigator.of(ctx).pop();
                onPick(false);
              },
            ),
            if (_hasImage && onRemove != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Görseli kaldır',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onRemove!();
                },
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = circular
        ? BorderRadius.circular(height)
        : BorderRadius.circular(AppSpacing.radiusLg);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        GestureDetector(
          onTap: isUploading ? null : () => _showSourceSheet(context),
          child: Container(
            width: circular ? height : double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: radius,
              border: Border.all(
                color: _hasImage
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : theme.colorScheme.outline,
                width: _hasImage ? 1.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (localFile != null)
                  Image.file(localFile!, fit: BoxFit.cover)
                else if (remoteUrl != null)
                  Image.network(
                    remoteUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _empty(theme),
                  )
                else
                  _empty(theme),

                if (isUploading)
                  ColoredBox(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),

                if (_hasImage && !isUploading)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Değiştir',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (hint.isNotEmpty && !_hasImage) ...[
          const SizedBox(height: 6),
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _empty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          if (!circular) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Görsel ekle',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}