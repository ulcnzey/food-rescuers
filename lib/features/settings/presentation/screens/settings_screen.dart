import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'faq_screen.dart';
import 'static_page_screen.dart';
import 'support_screen.dart';
import '../../../notifications/presentation/controllers/notification_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: AppColors.error),
        title: const Text('Çıkış yapmak istiyor musun?'),
        content: const Text(
          'Hesabından çıkacaksın. Tekrar giriş yapman gerekecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );

    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const _GroupTitle('Uygulama'),
                        Consumer(
              builder: (context, ref, _) {
                final pref =
                    ref.watch(notificationPreferenceProvider).valueOrNull;
                final enabled = pref?.enabled ?? false;

                return _Tile(
                  icon: enabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  title: 'Bildirimler',
                  trailing: Switch(
                    value: enabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) async {
                      final controller =
                          ref.read(notificationPermissionProvider);
                      if (v) {
                        await controller.allow();
                      } else {
                        await controller.deny();
                      }
                    },
                  ),
                  onTap: () {},
                );
              },
            ),
            _Tile(
              icon: Icons.brightness_6_outlined,
              title: 'Görünüm',
              trailing: Text(
                switch (themeMode) {
                  ThemeMode.light => 'Açık',
                  ThemeMode.dark => 'Koyu',
                  ThemeMode.system => 'Sistem',
                },
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () => _showThemeSheet(context, ref, themeMode),
            ),

            const SizedBox(height: AppSpacing.lg),
            const _GroupTitle('Yasal'),
            _Tile(
              icon: Icons.info_outline_rounded,
              title: 'Hakkımızda',
              onTap: () => _openPage(context, 'about', 'Hakkımızda'),
            ),
            _Tile(
              icon: Icons.description_outlined,
              title: 'Kullanım Koşulları',
              onTap: () => _openPage(context, 'terms', 'Kullanım Koşulları'),
            ),
            _Tile(
              icon: Icons.lock_outline_rounded,
              title: 'Gizlilik Politikası',
              onTap: () =>
                  _openPage(context, 'privacy', 'Gizlilik Politikası'),
            ),

            const SizedBox(height: AppSpacing.lg),
            const _GroupTitle('Destek'),
            _Tile(
              icon: Icons.help_outline_rounded,
              title: 'Sıkça Sorulan Sorular',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FaqScreen()),
              ),
            ),
            _Tile(
              icon: Icons.mail_outline_rounded,
              title: 'İletişim',
              onTap: () => _openSupport(context, SupportType.contact),
            ),
            _Tile(
              icon: Icons.bug_report_outlined,
              title: 'Sorun Bildir',
              onTap: () => _openSupport(context, SupportType.bug),
            ),
            _Tile(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Öneri Gönder',
              onTap: () => _openSupport(context, SupportType.suggestion),
            ),

            const SizedBox(height: AppSpacing.xl),

            OutlinedButton.icon(
              onPressed: () => _signOut(context, ref),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Çıkış Yap'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.5),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                'FoodRescuers v1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _openPage(BuildContext context, String slug, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StaticPageScreen(slug: slug, fallbackTitle: title),
      ),
    );
  }

  void _openSupport(BuildContext context, SupportType type) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SupportScreen(initialType: type)),
    );
  }

  void _showThemeSheet(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text('Görünüm', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final mode in ThemeMode.values)
              ListTile(
                leading: Icon(
                  mode == current
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: mode == current
                      ? AppColors.primary
                      : Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
                title: Text(switch (mode) {
                  ThemeMode.light => 'Açık',
                  ThemeMode.dark => 'Koyu',
                  ThemeMode.system => 'Sistem ayarını kullan',
                }),
                onTap: () {
                  ref.read(themeControllerProvider.notifier).setMode(mode);
                  Navigator.of(ctx).pop();
                },
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 4),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            child: Row(
              children: [
                Icon(icon, size: 21, color: theme.colorScheme.onSurface),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
                ?trailing,
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}