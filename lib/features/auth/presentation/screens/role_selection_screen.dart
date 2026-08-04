import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../business/presentation/screens/business_setup_screen.dart';
import '../../../offers/presentation/screens/home_screen.dart';
import '../../domain/enums/user_role.dart';
import '../controllers/auth_controller.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _selectedRole;

  void _select(UserRole role) {
    setState(() => _selectedRole = role);
  }

  Future<void> _continue() async {
    final role = _selectedRole;
    if (role == null) return;

    // Rolu veritabanindaki profiles kaydina yazar.
    final ok = await ref.read(authControllerProvider.notifier).selectRole(role);

    if (!mounted || !ok) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => role == UserRole.business
            ? const BusinessSetupScreen()
            : const HomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isMuted = theme.brightness == Brightness.light
        ? AppColors.textMutedLight
        : AppColors.textMutedDark;

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
                style: theme.textTheme.bodyMedium?.copyWith(color: isMuted),
              ),
              const SizedBox(height: AppSpacing.xl),

              Expanded(
                child: ListView(
                  children: [
                    _RoleCard(
                      title: 'Bireysel Kullanıcı',
                      description:
                          'Yakınındaki fırsatları keşfet, rezerve et, kurtar.',
                      icon: Icons.shopping_bag_outlined,
                      iconColor: AppColors.primary,
                      isSelected: _selectedRole == UserRole.consumer,
                      onTap: () => _select(UserRole.consumer),
                      bullets: const [
                        'Taze ve uygun fiyatlı gıdalara ulaş',
                        'Tek tuşla kolay rezervasyon',
                        'Gıda israfına bireysel katkı sağla',
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _RoleCard(
                      title: 'İşletme',
                      description:
                          'Elindeki fazlalığı israf etme, satışa veya bağışa çıkar.',
                      icon: Icons.storefront_rounded,
                      iconColor: AppColors.secondary,
                      isSelected: _selectedRole == UserRole.business,
                      onTap: () => _select(UserRole.business),
                      bullets: const [
                        'Fazla stokları kolayca gelire dönüştür',
                        'Yeni yerel müşterilere ulaş',
                        'Karbon ayak izini ve israfı azalt',
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (authState.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.10),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Text(
                      'Bu seçimi daha sonra profilinden değiştirebilirsin.',
                      textAlign: TextAlign.center,
                      style:
                          theme.textTheme.bodySmall?.copyWith(color: isMuted),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: (_selectedRole != null && !authState.isLoading)
                          ? _continue
                          : null,
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Devam Et'),
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
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
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
                              color: isSelected
                                  ? AppColors.primary
                                  : iconColor.withValues(alpha: 0.7),
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                bullet,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w500
                                      : FontWeight.normal,
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