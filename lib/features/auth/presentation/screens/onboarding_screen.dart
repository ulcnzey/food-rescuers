import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Yemekler çöpe gitmesin',
      subtitle: 'Yakınındaki işletmeler gün sonunda ellerinde kalan taze ve lezzetli fazla gıdaları listeler.',
      icon: Icons.storefront_rounded,
      gradientColors: [AppColors.primary, AppColors.primaryDark],
      illustrationBuilder: (isActive) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.0 : 0.8,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
              ),
            ),
            AnimatedRotation(
              turns: isActive ? 0.0 : -0.1,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              child: AnimatedScale(
                scale: isActive ? 1.1 : 0.9,
                duration: const Duration(milliseconds: 500),
                child: const Card(
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Icon(
                      Icons.fastfood_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 20,
              top: 20,
              child: AnimatedScale(
                scale: isActive ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
                ),
              ),
            )
          ],
        );
      },
    ),
    OnboardingData(
      title: 'Uygun fiyata, hatta ücretsiz',
      subtitle: 'Sürpriz paketleri çok uygun fiyatlarla, hatta bazen tamamen ücretsiz olarak tek dokunuşla rezerve et.',
      icon: Icons.touch_app_rounded,
      gradientColors: [AppColors.secondary, Color(0xFFD48220)],
      illustrationBuilder: (isActive) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.0 : 0.75,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.secondaryLight, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
              ),
            ),
            AnimatedSlide(
              offset: isActive ? Offset.zero : const Offset(0, 0.2),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              child: const Icon(
                Icons.sell_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
            Positioned(
              left: 30,
              bottom: 20,
              child: AnimatedScale(
                scale: isActive ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 650),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: const Text(
                    '₺0 (Bedava!)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            )
          ],
        );
      },
    ),
    OnboardingData(
      title: 'Git, QR kodunu göster, al',
      subtitle: 'Belirlenen saat aralığında işletmeye git, uygulamadaki QR kodunu göster, ödemeni yap ve paketini teslim al.',
      icon: Icons.qr_code_scanner_rounded,
      gradientColors: [AppColors.primary, AppColors.success],
      illustrationBuilder: (isActive) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.0 : 0.8,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.success.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            AnimatedRotation(
              turns: isActive ? 0.05 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: AnimatedScale(
                scale: isActive ? 1.0 : 0.8,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    size: 64,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 15,
              bottom: 25,
              child: AnimatedScale(
                scale: isActive ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                ),
              ),
            )
          ],
        );
      },
    ),
  ];

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (!isLastPage)
            TextButton(
              onPressed: _finishOnboarding,
              child: Text(
                'Atla',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  final isActive = _currentPage == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Dynamic vector illustration container
                        SizedBox(
                          height: 240,
                          child: Center(
                            child: page.illustrationBuilder(isActive),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.brightness == Brightness.light
                                ? AppColors.textMutedLight
                                : AppColors.textMutedDark,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Animated Dot Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : (theme.brightness == Brightness.light
                                  ? AppColors.borderLight
                                  : AppColors.borderDark),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Forward / Get Started Button
                  FilledButton(
                    onPressed: () {
                      if (isLastPage) {
                        _finishOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(isLastPage ? 'Başlayalım' : 'İleri'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Widget Function(bool isActive) illustrationBuilder;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.illustrationBuilder,
  });
}
