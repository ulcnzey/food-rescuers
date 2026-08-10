import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../map/presentation/screens/map_screen.dart';
import '../../../offers/presentation/screens/home_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../reservations/presentation/screens/my_orders_screen.dart';

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

  void _goToDiscover() => setState(() => _index = 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // IndexedStack: sekme degisince onceki ekranin kaydirma
    // konumu ve durumu korunur.
    final screens = [
      const HomeScreen(),
      const MapScreen(),
      MyOrdersScreen(onDiscover: _goToDiscover),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
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
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.primary,
                  ),
                  label: 'Siparişlerim',
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