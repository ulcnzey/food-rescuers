import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/branding/app_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../shell/presentation/screens/main_shell.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  /// Oturum kontrolu basarisiz olursa kullaniciya tekrar dene sunulur.
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _decideNextScreen();
  }

  Future<void> _decideNextScreen() async {
    setState(() => _hasError = false);

    // Logo animasyonunun tamamlanmasi icin asgari sure.
    final minimumWait = Future<void>.delayed(
      const Duration(milliseconds: 2200),
    );

    try {
      final repo = ref.read(authRepositoryProvider);
      final hasSession = repo.currentSession != null;

      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('onboarding_seen') ?? false;

      await minimumWait;
      if (!mounted) return;

      // Oturum yok -> ilk kullanimsa tanitim, degilse giris.
      if (!hasSession) {
        _go(seenOnboarding ? const LoginScreen() : const OnboardingScreen());
        return;
      }

      // Oturum var -> herkes ayni ana ekrana gider.
      // Rol ayrimi kaldirildi; ilan verme yetenegi profilden aciliyor.
      _go(const MainShell());
    } catch (_) {
      await minimumWait;
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  void _go(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMuted = theme.brightness == Brightness.light
        ? AppColors.textMutedLight
        : AppColors.textMutedDark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: theme.brightness == Brightness.light
                      ? [AppColors.bgLight, Colors.white]
                      : [AppColors.bgDark, AppColors.surfaceDark],
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AnimatedAppLogo(size: 130),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'FoodRescuers',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Kurtarılan her öğün bir umut',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  // Baglanti hatasi durumunda tekrar dene
                  if (_hasError) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Bağlantı kurulamadı',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.error),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: _decideNextScreen,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Tekrar dene'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(160, 44),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}