import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../home/domain/entities/banner_item.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../notifications/presentation/controllers/notification_controller.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../offers/presentation/controllers/offer_controller.dart';
import '../../../offers/presentation/screens/create_offer_screen.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/business_stats.dart';
import '../controllers/business_controller.dart';
import 'business_setup_screen.dart';
import 'edit_business_screen.dart';
import 'my_offers_screen.dart';
import 'qr_scanner_screen.dart';

class BusinessDashboardScreen extends ConsumerWidget {
  const BusinessDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(myBusinessProvider);

    return Scaffold(
      body: businessAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (_, _) => SafeArea(
          child: _ErrorView(
            onRetry: () => ref.invalidate(myBusinessProvider),
          ),
        ),

        data: (business) {
          if (business == null) {
            return SafeArea(
              child: EmptyState(
                art: EmptyStateArt.storefront,
                title: 'İşletmen henüz kayıtlı değil',
                message: 'İlan verebilmen için önce işletme bilgilerini '
                    'tamamlaman gerekiyor.',
                actionLabel: 'İşletmemi Oluştur',
                onAction: () {
                  Navigator.of(context).push(
                    SmoothPageRoute<void>(page: const BusinessSetupScreen()),
                  );
                },
              ),
            );
          }

          return _Dashboard(business: business);
        },
      ),
    );
  }
}

// ================================================================ PANEL

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.business});

  final Business business;

  /// Gunun saatine gore selamlama.
  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return 'İyi geceler';
    if (h < 12) return 'Günaydın';
    if (h < 18) return 'Merhaba';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(businessStatsProvider).valueOrNull ??
        const BusinessStats();

    return Column(
      children: [
        _BusinessTopBar(
          greeting: _greeting(),
          business: business,
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myBusinessProvider);
              ref.invalidate(businessStatsProvider);
              ref.invalidate(myOffersProvider);
              ref.invalidate(businessBannersProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              children: [
                // ---- Reklam karuseli (isletme tarafi)
                const _BusinessBannerCarousel(),
                const SizedBox(height: AppSpacing.lg),

                // ---- Bugun teslim bekleyen uyarisi
                if (stats.pendingPickups > 0) ...[
                  _PendingBanner(
                    count: stats.pendingPickups,
                    onTap: () => Navigator.of(context).push(
                      SmoothPageRoute<void>(page: const QrScannerScreen()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ---- Bugunun ozeti
                Text(
                  'Bugünün özeti',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.md),

                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Rezervasyon',
                        value: stats.todayReservations.toDouble(),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Teslim edilen',
                        value: stats.todayCompleted.toDouble(),
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.payments_outlined,
                        label: 'Bugünkü ciro',
                        value: stats.todayRevenue,
                        suffix: ' ₺',
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.local_offer_outlined,
                        label: 'Aktif ilan',
                        value: stats.activeOffers.toDouble(),
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // ==========================================================
                // AKILLI FIYAT ONERISI — MODEL BURAYA BAGLANACAK
                // Su an yer tutucu. Egitilmis regresyon modeli
                // devreye girdiginde bu kart gercek tahmin gosterecek.
                // ==========================================================
                _AiInsightCard(
                  totalSavedMeals: stats.totalSavedMeals,
                  weekRevenue: stats.weekRevenue,
                ),

                const SizedBox(height: AppSpacing.lg),

                // ---- Hizli islemler
                Text(
                  'Hızlı İşlemler',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.md),

                _ActionTile(
                  icon: Icons.add_circle_outline_rounded,
                  title: 'Yeni İlan Ekle',
                  subtitle: 'Gün sonu kalan ürünlerini listele',
                  color: AppColors.primary,
                  onTap: () => Navigator.of(context).push(
                    SmoothPageRoute<void>(page: const CreateOfferScreen()),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ActionTile(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'QR Kod Okut',
                  subtitle: 'Müşterinin teslimatını onayla',
                  color: AppColors.secondary,
                  badge: stats.pendingPickups > 0
                      ? '${stats.pendingPickups}'
                      : null,
                  onTap: () => Navigator.of(context).push(
                    SmoothPageRoute<void>(page: const QrScannerScreen()),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ActionTile(
                  icon: Icons.list_alt_rounded,
                  title: 'İlanlarım',
                  subtitle: '${stats.activeOffers} aktif ilan',
                  color: AppColors.info,
                  onTap: () => Navigator.of(context).push(
                    SmoothPageRoute<void>(page: const MyOffersScreen()),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ActionTile(
                  icon: Icons.storefront_outlined,
                  title: 'İşletme Bilgileri',
                  subtitle: 'Ad, konum, saatler ve logo',
                  color: AppColors.success,
                  onTap: () => Navigator.of(context).push(
                    SmoothPageRoute<void>(
                      page: EditBusinessScreen(business: business),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ================================================================ UST BASLIK

class _BusinessTopBar extends ConsumerWidget {
  const _BusinessTopBar({required this.greeting, required this.business});

  final String greeting;
  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    final accent =
        business.isIndividual ? AppColors.success : AppColors.secondary;

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
              // ---- Marka + bildirim + geri
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      tooltip: 'Müşteri görünümüne dön',
                    ),
                  ),
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
                  SizedBox(
                    width: 40,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          ),
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
                              constraints: const BoxConstraints(minWidth: 18),
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
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // ---- Selamlama + isletme
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    padding: const EdgeInsets.all(3),
                    clipBehavior: Clip.antiAlias,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: business.logoUrl != null
                          ? Image.network(
                              business.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _icon(accent),
                            )
                          : _icon(accent),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          business.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (business.ratingCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            business.ratingAvg.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
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

  Widget _icon(Color accent) => DecoratedBox(
        decoration: BoxDecoration(color: accent.withValues(alpha: 0.15)),
        child: Icon(
          business.isIndividual
              ? Icons.volunteer_activism_rounded
              : Icons.storefront_rounded,
          color: accent,
          size: 24,
        ),
      );
}

// ================================================================ BANNER

class _BusinessBannerCarousel extends ConsumerStatefulWidget {
  const _BusinessBannerCarousel();

  @override
  ConsumerState<_BusinessBannerCarousel> createState() =>
      _BusinessBannerCarouselState();
}

class _BusinessBannerCarouselState
    extends ConsumerState<_BusinessBannerCarousel> {
  final _controller = PageController(viewportFraction: 0.94);
  Timer? _timer;
  int _page = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoScroll(int count) {
    _timer?.cancel();
    if (count < 2) return;

    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_controller.hasClients) return;

      _controller.animateToPage(
        (_page + 1) % count,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(businessBannersProvider);

    return async.when(
      loading: () => const ShimmerBox(
        width: double.infinity,
        height: 108,
        radius: AppSpacing.radiusXl,
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_timer == null) _startAutoScroll(banners.length);
        });

        return Column(
          children: [
            SizedBox(
              height: 108,
              child: PageView.builder(
                controller: _controller,
                itemCount: banners.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _BannerCard(item: banners[i]),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 5,
                  width: _page == i ? 18 : 5,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.item});

  final BannerItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: item.bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (item.imageUrl != null)
            Positioned.fill(
              child: Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================ PARCALAR

/// Teslim bekleyen rezervasyon uyarisi.
class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BouncyTap(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pending_actions_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count teslim bekliyor',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Müşteri geldiğinde QR kodunu okut',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// AI fiyat onerisi karti. Model devreye girene kadar
/// ozet istatistik gosteriyor; baglandiginda tahmin gelecek.
class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({
    required this.totalSavedMeals,
    required this.weekRevenue,
  });

  final int totalSavedMeals;
  final double weekRevenue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.info.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Akıllı Öneriler',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'Yakında',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Geçmiş satışlarından öğrenen model, her ilan için en uygun '
            'fiyatı ve satılma ihtimalini önerecek.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Toplam kurtarılan',
                  value: '$totalSavedMeals öğün',
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: theme.colorScheme.outline,
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Bu hafta',
                  value: '${weekRevenue.toStringAsFixed(0)} ₺',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.suffix = '',
  });

  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final String suffix;

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
          CounterText(
            value: value,
            suffix: suffix,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
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
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BouncyTap(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (badge != null)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        badge!,
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