import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../business/domain/entities/business.dart';
import '../../../business/presentation/controllers/business_controller.dart';
import '../../../business/presentation/screens/business_dashboard_screen.dart';
import '../../../business/presentation/screens/business_setup_screen.dart';
import '../../../notifications/presentation/controllers/notification_controller.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../reservations/presentation/controllers/reservation_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../settings/presentation/screens/impact_detail_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _changeAvatar(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    final selected = await showAvatarPicker(context, current);
    if (selected == null || selected == current) return;

    await ref.read(settingsControllerProvider.notifier).updateAvatar(selected);
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adını düzenle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Ad Soyad'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç'),
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

    if (name == null || name.isEmpty || name == current) return;

    await ref.read(settingsControllerProvider.notifier).updateFullName(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider).valueOrNull;
    final businessAsync = ref.watch(myBusinessProvider);
    final stats = ref.watch(myImpactProvider).valueOrNull;

    final name = (profile?.fullName.trim().isNotEmpty ?? false)
        ? profile!.fullName
        : 'Adını ekle';

    return Scaffold(
      body: Column(
        children: [
          // ---- Yesil ust baslik
          _ProfileTopBar(
            name: name,
            avatarId: profile?.avatarId ?? 0,
            onAvatarTap: () =>
                _changeAvatar(context, ref, profile?.avatarId ?? 0),
            onNameTap: () =>
                _editName(context, ref, profile?.fullName ?? ''),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(profileProvider);
                ref.invalidate(myBusinessProvider);
                ref.invalidate(myImpactProvider);
                ref.invalidate(monthlyImpactProvider);
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // ---- Etki kartlari
                  Row(
                    children: [
                      Expanded(
                        child: _ImpactCard(
                          icon: Icons.eco_rounded,
                          title: 'Önlenen CO₂',
                          value: stats?.co2Kg ?? 0,
                          suffix: ' kg',
                          decimals: 1,
                          color: AppColors.success,
                          onTap: () => Navigator.of(context).push(
                            SmoothPageRoute<void>(
                              page: const ImpactDetailScreen(
                                kind: ImpactKind.co2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _ImpactCard(
                          icon: Icons.savings_outlined,
                          title: 'Tasarrufun',
                          value: stats?.savedMoney ?? 0,
                          suffix: ' ₺',
                          color: AppColors.secondary,
                          onTap: () => Navigator.of(context).push(
                            SmoothPageRoute<void>(
                              page: const ImpactDetailScreen(
                                kind: ImpactKind.money,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ---- Kurtarilan ogun
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primary.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: const Icon(
                            Icons.volunteer_activism_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Kurtarılan öğün',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const Spacer(),
                        CounterText(
                          value: (stats?.savedMeals ?? 0).toDouble(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ---- Isletme kartı
                  businessAsync.when(
                    loading: () => const _LoadingTile(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (business) => business == null
                        ? _StartSellingCard(
                            onTap: () {
                              Navigator.of(context).push(
                                SmoothPageRoute<void>(
                                  page: const BusinessSetupScreen(),
                                ),
                              );
                            },
                          )
                        : _MyBusinessTile(
                            business: business,
                            onTap: () {
                              Navigator.of(context).push(
                                SmoothPageRoute<void>(
                                  page: const BusinessDashboardScreen(),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================ UST BASLIK

class _ProfileTopBar extends ConsumerWidget {
  const _ProfileTopBar({
    required this.name,
    required this.avatarId,
    required this.onAvatarTap,
    required this.onNameTap,
  });

  final String name;
  final int avatarId;
  final VoidCallback onAvatarTap;
  final VoidCallback onNameTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              // ---- Marka + bildirim + ayarlar
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Center(
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Food',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'Rescuers',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                            ),
                          ),
                          if (unread > 0)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                constraints:
                                    const BoxConstraints(minWidth: 18),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: AppColors.primaryDark,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  unread > 9 ? '9+' : '$unread',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // ---- Avatar + isim
              Row(
                children: [
                  BouncyTap(
                    onTap: onAvatarTap,
                    scale: 0.9,
                    child: Stack(
                      children: [
                        UserAvatar(
                          avatarId: avatarId,
                          size: 64,
                          showBorder: true,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 11,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: BouncyTap(
                      onTap: onNameTap,
                      scale: 0.98,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================ PARCALAR

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
    this.suffix = '',
    this.decimals = 0,
  });

  final IconData icon;
  final String title;
  final double value;
  final Color color;
  final VoidCallback onTap;
  final String suffix;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BouncyTap(
      onTap: onTap,
      scale: 0.97,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(height: AppSpacing.md),
            CounterText(
              value: value,
              suffix: suffix,
              decimals: decimals,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartSellingCard extends StatelessWidget {
  const _StartSellingCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BouncyTap(
      onTap: onTap,
      scale: 0.98,
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
                    'İşletmen mi var?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Gün sonu ürünlerini israf etme, satışa çıkar.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
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

    return BouncyTap(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              clipBehavior: Clip.antiAlias,
              child: business.logoUrl != null
                  ? Image.network(
                      business.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _icon(accent),
                    )
                  : _icon(accent),
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
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'İşletme paneline git',
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
    );
  }

  Widget _icon(Color accent) => Icon(
        business.isIndividual
            ? Icons.volunteer_activism_rounded
            : Icons.storefront_rounded,
        color: accent,
        size: 24,
      );
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
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