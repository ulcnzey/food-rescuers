import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../offers/presentation/controllers/offer_controller.dart';
import '../../../offers/presentation/screens/create_offer_screen.dart';
import '../../domain/entities/business.dart';
import '../controllers/business_controller.dart';
import 'business_setup_screen.dart';
import 'edit_business_screen.dart';
import 'my_offers_screen.dart';
import 'qr_scanner_screen.dart';

class BusinessDashboardScreen extends ConsumerWidget {
  const BusinessDashboardScreen({super.key});

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

    // Once ekrani degistir ki panel bos veriyle yeniden cizilmesin.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );

    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(myBusinessProvider);

    return Scaffold(
      body: SafeArea(
        child: businessAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),

          error: (_, _) => _ErrorView(
            onRetry: () => ref.invalidate(myBusinessProvider),
          ),

          data: (business) {
            if (business == null) {
              return EmptyState(
                art: EmptyStateArt.storefront,
                title: 'İşletmen henüz kayıtlı değil',
                message: 'İlan verebilmen için önce işletme bilgilerini '
                    'tamamlaman gerekiyor.',
                actionLabel: 'İşletmemi Oluştur',
                onAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BusinessSetupScreen(),
                    ),
                  );
                },
              );
            }

            return _Dashboard(
              business: business,
              onSignOut: () => _signOut(context, ref),
              onRefresh: () async {
                ref.invalidate(myBusinessProvider);
                ref.invalidate(myOffersProvider);
              },
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- PANEL

class _Dashboard extends ConsumerWidget {
  const _Dashboard({
    required this.business,
    required this.onSignOut,
    required this.onRefresh,
  });

  final Business business;
  final VoidCallback onSignOut;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent =
        business.isIndividual ? AppColors.success : AppColors.secondary;

    final offersAsync = ref.watch(myOffersProvider);
    final offers = offersAsync.valueOrNull ?? [];

    final activeCount = offers.where((o) => o.isActive).length;
    final reservedTotal = offers.fold<int>(0, (s, o) => s + o.reservedCount);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ---- Ust bilgi
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                clipBehavior: Clip.antiAlias,
                child: business.logoUrl != null
                    ? Image.network(
                        business.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _providerIcon(accent),
                      )
                    : _providerIcon(accent),
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
                      style: theme.textTheme.titleLarge,
                    ),
                    Text(
                      business.category.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.storefront_outlined),
                tooltip: 'Müşteri görünümüne dön',
              ),
              IconButton(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Çıkış yap',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ---- Ozet kartlari
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.local_offer_outlined,
                  label: 'Aktif İlan',
                  value: '$activeCount',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Toplam Rezervasyon',
                  value: '$reservedTotal',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.list_alt_outlined,
                  label: 'Toplam İlan',
                  value: '${offers.length}',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  icon: Icons.star_outline_rounded,
                  label: 'Puan',
                  value: business.ratingCount == 0
                      ? '—'
                      : business.ratingAvg.toStringAsFixed(1),
                  color: AppColors.warning,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ---- Hizli islemler
          Text(
            'Hızlı İşlemler',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),

          _ActionTile(
            icon: Icons.add_circle_outline_rounded,
            title: 'Yeni İlan Ekle',
            subtitle: 'Gün sonu kalan ürünlerini listele',
            color: AppColors.primary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateOfferScreen()),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            icon: Icons.qr_code_scanner_rounded,
            title: 'QR Kod Okut',
            subtitle: 'Müşterinin teslimatını onayla',
            color: AppColors.secondary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QrScannerScreen()),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            icon: Icons.list_alt_rounded,
            title: 'İlanlarım',
            subtitle: '${offers.length} ilan · $activeCount aktif',
            color: AppColors.info,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyOffersScreen()),
              );
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // ---- Isletme bilgileri
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'İşletme Bilgileri',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                EditBusinessScreen(business: business),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Düzenle'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(
                  icon: Icons.schedule_rounded,
                  text: business.workingHoursLabel,
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  text: business.openDaysLabel,
                ),
                if (business.address != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: business.address!,
                  ),
                ],
                if (business.phone != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    text: business.phone!,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _providerIcon(Color accent) => Icon(
        business.isIndividual
            ? Icons.volunteer_activism_rounded
            : Icons.storefront_rounded,
        color: accent,
        size: 26,
      );
}

// ---------------------------------------------------------------- PARCALAR

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: theme.textTheme.headlineSmall),
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
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: color, size: 22),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 44,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Bilgiler yüklenemedi', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}