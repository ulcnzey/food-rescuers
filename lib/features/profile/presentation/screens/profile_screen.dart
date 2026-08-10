import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../business/domain/entities/business.dart';
import '../../../business/presentation/controllers/business_controller.dart';
import '../../../business/presentation/screens/business_dashboard_screen.dart';
import '../../../business/presentation/screens/business_setup_screen.dart';
import '../../../reservations/presentation/controllers/reservation_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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

    // Once ekrani degistir, sonra oturumu kapat.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );

    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileProvider);
    final businessAsync = ref.watch(myBusinessProvider);
    final themeMode = ref.watch(themeControllerProvider);

    // Etki istatistikleri tamamlanan rezervasyonlardan hesaplanir.
    final stats = ref.watch(myImpactProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(profileProvider);
            ref.invalidate(myBusinessProvider);
            ref.invalidate(myImpactProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // ---- Kullanici basligi
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileAsync.valueOrNull?.fullName.isNotEmpty == true
                              ? profileAsync.value!.fullName
                              : 'Kullanıcı',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          (stats?.savedMeals ?? 0) > 0
                              ? '${stats!.savedMeals} öğün kurtardın'
                              : 'Gıda kurtarıcı',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ---- Etki kartlari (gercek veri)
              Row(
                children: [
                  Expanded(
                    child: _ImpactCard(
                      icon: Icons.volunteer_activism_rounded,
                      value: (stats?.savedMeals ?? 0).toDouble(),
                      label: 'Kurtarılan öğün',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ImpactCard(
                      icon: Icons.eco_rounded,
                      value: stats?.co2Kg ?? 0,
                      suffix: ' kg',
                      decimals: 1,
                      label: 'Önlenen CO₂',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _ImpactCard(
                icon: Icons.savings_outlined,
                value: stats?.savedMoney ?? 0,
                suffix: ' ₺',
                label: 'Toplam tasarruf',
                color: AppColors.secondary,
                wide: true,
              ),

              const SizedBox(height: AppSpacing.lg),

              // ---- Ilan verme / isletme paneli
              businessAsync.when(
                loading: () => const _LoadingTile(),
                error: (_, _) => const SizedBox.shrink(),
                data: (business) => business == null
                    ? _StartSellingCard(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BusinessSetupScreen(),
                            ),
                          );
                        },
                      )
                    : _MyBusinessTile(
                        business: business,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BusinessDashboardScreen(),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ---- Ayarlar
              Text(
                'Ayarlar',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),

              _SettingTile(
                icon: Icons.favorite_outline_rounded,
                title: 'Favorilerim',
                onTap: () => _soon(context),
              ),
              _SettingTile(
                icon: Icons.notifications_none_rounded,
                title: 'Bildirimler',
                onTap: () => _soon(context),
              ),
              _SettingTile(
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
              _SettingTile(
                icon: Icons.description_outlined,
                title: 'Yasal Bilgiler',
                onTap: () => _soon(context),
              ),

              const SizedBox(height: AppSpacing.lg),

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
                  'FoodRescuers v1.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bu özellik yakında eklenecek'),
        duration: Duration(seconds: 2),
      ),
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
            Text(
              'Görünüm',
              style: Theme.of(ctx)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
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

// ---------------------------------------------------------------- PARCALAR

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.suffix = '',
    this.decimals = 0,
    this.wide = false,
  });

  final IconData icon;
  final double value;
  final String label;
  final Color color;
  final String suffix;
  final int decimals;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sayac animasyonu: deger sifirdan hedefe dogru artar.
    final counter = CounterText(
      value: value,
      suffix: suffix,
      decimals: decimals,
      style: theme.textTheme.headlineSmall,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: wide
          ? Row(
              children: [
                _iconBox(color, icon),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    counter,
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _iconBox(color, icon),
                const SizedBox(height: AppSpacing.sm),
                counter,
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }

  static Widget _iconBox(Color color, IconData icon) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(icon, color: color, size: 18),
      );
}

class _StartSellingCard extends StatelessWidget {
  const _StartSellingCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_business_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İlan Vermeye Başla',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'İşletmen varsa satışa çıkar, bireysel isen bağışla.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyBusinessTile extends StatelessWidget {
  const _MyBusinessTile({required this.business, required this.onTap});

  final Business business;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent =
        business.isIndividual ? AppColors.success : AppColors.secondary;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                clipBehavior: Clip.antiAlias,
                child: business.logoUrl != null
                    ? Image.network(
                        business.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          business.isIndividual
                              ? Icons.volunteer_activism_rounded
                              : Icons.storefront_rounded,
                          color: accent,
                          size: 22,
                        ),
                      )
                    : Icon(
                        business.isIndividual
                            ? Icons.volunteer_activism_rounded
                            : Icons.storefront_rounded,
                        color: accent,
                        size: 22,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      business.providerType.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
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
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 22),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?trailing,
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, size: 20),
        ],
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: const Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}