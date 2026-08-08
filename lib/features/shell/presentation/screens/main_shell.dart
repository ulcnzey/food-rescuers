import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../offers/presentation/screens/home_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

/// Uygulamanin ana kabugu. Alt navigasyon ve sekmeleri barindirir.
/// Rol ayrimi yok; herkes ayni sekmeleri gorur.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _index = widget.initialIndex;

  /// IndexedStack kullanildigi icin sekmeler arasi gecis yapinca
  /// onceki sekmenin kaydirma konumu ve durumu korunur.
  static const _screens = [
    HomeScreen(),
    _MapPlaceholder(),
    _TicketsPlaceholder(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outline),
          ),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.transparent,
              indicatorColor: AppColors.primary.withValues(alpha: 0.12),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return theme.textTheme.labelSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.primary
                      : theme.colorScheme.onSurfaceVariant,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              height: 66,
              elevation: 0,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon:
                      Icon(Icons.explore_rounded, color: AppColors.primary),
                  label: 'Keşfet',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon:
                      Icon(Icons.map_rounded, color: AppColors.primary),
                  label: 'Harita',
                ),
                NavigationDestination(
                  icon: Icon(Icons.confirmation_number_outlined),
                  selectedIcon: Icon(Icons.confirmation_number_rounded,
                      color: AppColors.primary),
                  label: 'Biletlerim',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon:
                      Icon(Icons.person_rounded, color: AppColors.primary),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Gecici yer tutucular. Ilerleyen adimlarda gercek ekranlar gelecek.

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) =>
      const _Soon(icon: Icons.map_rounded, title: 'Harita', subtitle: 'Yakınındaki ilanları haritada göreceksin.');
}

class _TicketsPlaceholder extends StatelessWidget {
  const _TicketsPlaceholder();

  @override
  Widget build(BuildContext context) => const _Soon(
        icon: Icons.confirmation_number_rounded,
        title: 'Biletlerim',
        subtitle: 'Rezervasyonların ve QR kodların burada olacak.',
      );
}

class _Soon extends StatelessWidget {
  const _Soon({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
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