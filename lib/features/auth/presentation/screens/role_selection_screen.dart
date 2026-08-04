import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/enums/user_role.dart';
import '../../../offers/presentation/screens/home_screen.dart';

// Riverpod Provider to store selected role.
final selectedRoleProvider = StateProvider<UserRole?>((ref) => null);

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedRole = ref.watch(selectedRoleProvider);

    void onRoleSelect(UserRole role) {
      ref.read(selectedRoleProvider.notifier).state = role;
    }

    void onContinue() {
      if (selectedRole == null) return;

      if (selectedRole == UserRole.consumer) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        // Business placeholder panel
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: const Text('İşletme Paneli'),
                leading: IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () {
                    // Reset role and go back to login for demo flow convenience
                    ref.read(selectedRoleProvider.notifier).state = null;
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                ),
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        size: 80,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'İşletme Paneli — yakında',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Ürünlerinizi ekleyebileceğiniz ve siparişleri yönetebileceğiniz panel çok yakında burada olacak.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.brightness == Brightness.light
                              ? AppColors.textMutedLight
                              : AppColors.textMutedDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          (route) => false,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                'Nasıl kullanmak istersin?',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sana en uygun deneyimi sunabilmemiz için bir rol seç.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.light
                      ? AppColors.textMutedLight
                      : AppColors.textMutedDark,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Vertically stacked cards
              Expanded(
                child: ListView(
                  children: [
                    _RoleCard(
                      title: 'Bireysel Kullanıcı',
                      description: 'Yakınındaki fırsatları keşfet, rezerve et, kurtar.',
                      icon: Icons.shopping_bag_outlined,
                      iconColor: AppColors.primary,
                      isSelected: selectedRole == UserRole.consumer,
                      onTap: () => onRoleSelect(UserRole.consumer),
                      bullets: const [
                        'Taze ve uygun fiyatlı gıdalara ulaş',
                        'Tek tuşla kolay rezervasyon',
                        'Gıda israfına bireysel katkı sağla',
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _RoleCard(
                      title: 'İşletme',
                      description: 'Elindeki fazlalığı israf etme, satışa veya bağışa çıkar.',
                      icon: Icons.storefront_rounded,
                      iconColor: AppColors.secondary,
                      isSelected: selectedRole == UserRole.business,
                      onTap: () => onRoleSelect(UserRole.business),
                      bullets: const [
                        'Fazla stokları kolayca gelire dönüştür',
                        'Yeni yerel müşterilere ulaş',
                        'Karbon ayak izini ve israfı azalt',
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom note and continue button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Bu seçimi daha sonra profilinden değiştirebilirsin.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.brightness == Brightness.light
                            ? AppColors.textMutedLight
                            : AppColors.textMutedDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: selectedRole != null ? onContinue : null,
                      child: const Text('Devam Et'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;
  final List<String> bullets;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isSelected
        ? AppColors.primary
        : (theme.brightness == Brightness.light
            ? AppColors.borderLight
            : AppColors.borderDark);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: iconColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.brightness == Brightness.light
                            ? AppColors.textMutedLight
                            : AppColors.textMutedDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    ...bullets.map(
                      (bullet) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: isSelected ? AppColors.primary : iconColor.withValues(alpha: 0.7),
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                bullet,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
