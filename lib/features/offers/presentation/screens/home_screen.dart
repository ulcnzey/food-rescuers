import 'package:flutter/material.dart';
import '../../../../core/branding/app_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/offer.dart';
import '../widgets/food_type_style.dart';
import '../widgets/offer_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FoodType? _selected;

  // GECICI: Supabase baglanana kadar sahte veri
  late final List<Offer> _all = [
    Offer(
      id: '1',
      businessName: 'Ahmet Usta Fırın',
      title: 'Karışık Poğaça Paketi',
      originalPrice: 60,
      price: 20,
      quantityAvailable: 4,
      pickupEnd: DateTime.now().add(const Duration(hours: 2, minutes: 15)),
      distanceKm: 0.45,
      rating: 4.8,
      foodType: FoodType.bakery,
    ),
    Offer(
      id: '2',
      businessName: 'Mahalle Marketi',
      title: 'Sebze Kurtarma Kutusu',
      originalPrice: 0,
      price: 0,
      quantityAvailable: 2,
      pickupEnd: DateTime.now().add(const Duration(minutes: 45)),
      distanceKm: 1.2,
      rating: 4.5,
      foodType: FoodType.produce,
    ),
    Offer(
      id: '3',
      businessName: 'Kahve Durağı',
      title: 'Günün Sandviç Menüsü',
      originalPrice: 120,
      price: 45,
      quantityAvailable: 6,
      pickupEnd: DateTime.now().add(const Duration(hours: 3)),
      distanceKm: 2.1,
      rating: 4.9,
      foodType: FoodType.meal,
    ),
  ];

  List<Offer> get _visible =>
      _selected == null ? _all : _all.where((o) => o.foodType == _selected).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(theme: theme)),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            const SliverToBoxAdapter(child: _ImpactCard()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            const SliverToBoxAdapter(child: _SearchBar()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverToBoxAdapter(
              child: _Categories(
                selected: _selected,
                onChanged: (v) => setState(() => _selected = v),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Text(
                      'Yakınındaki fırsatlar',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      '${_visible.length} ilan',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.xxl),
              sliver: SliverList.separated(
                itemCount: _visible.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) => OfferCard(offer: _visible[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Row(
        children: [
          const AppLogoMark(size: 28, monochrome: true),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Konumun',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.place_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Elazığ, Merkez',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                  ],
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
    );
  }
}

/// "Bu ay X ogun kurtardin" karti
class _ImpactCard extends StatelessWidget {
  const _ImpactCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volunteer_activism_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bu ay 12 öğün kurtardın',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Yaklaşık 8 kg gıda israfı önlendi',
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

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'İşletme veya ürün ara...',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.selected, required this.onChanged});

  final FoodType? selected;
  final ValueChanged<FoodType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _Chip(
            label: 'Tümü',
            icon: Icons.apps_rounded,
            active: selected == null,
            onTap: () => onChanged(null),
          ),
          ...FoodType.values.map((t) {
            final s = FoodTypeStyle.of(t);
            return _Chip(
              label: s.label,
              icon: s.icon,
              active: selected == t,
              onTap: () => onChanged(t),
            );
          }),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: active ? AppColors.primary : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                color: active ? AppColors.primary : theme.colorScheme.outline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 16,
                    color: active ? Colors.white : theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: active ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}