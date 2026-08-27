import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/notification_controller.dart';

/// Bildirim izni isteme ekrani.
/// Kullanici reddederse veya carpiya basarsa gecilir;
/// izin verirse sistem izni istenir.
class NotificationPermissionScreen extends ConsumerStatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  ConsumerState<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends ConsumerState<NotificationPermissionScreen> {
  bool _busy = false;

  Future<void> _allow() async {
    setState(() => _busy = true);

    await ref.read(notificationPermissionProvider).allow();

    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _skip() async {
    setState(() => _busy = true);

    await ref.read(notificationPermissionProvider).deny();

    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ---- Sag ust: gec
            Positioned(
              right: AppSpacing.sm,
              top: AppSpacing.sm,
              child: IconButton(
                onPressed: _busy ? null : _skip,
                icon: Icon(
                  Icons.close_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // ---- Animasyonlu zil
                  const _BellIllustration(),

                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'Fırsatları kaçırma',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Bildirimlere izin verirsen sana şunları haber veririz:',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  const _Benefit(
                    icon: Icons.local_offer_rounded,
                    color: AppColors.primary,
                    title: 'Favori işletmenden yeni ilan',
                    subtitle: 'Takip ettiğin yerler ürün listelediğinde',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _Benefit(
                    icon: Icons.access_time_rounded,
                    color: AppColors.secondary,
                    title: 'Alım saati hatırlatması',
                    subtitle: 'Rezervasyonunu unutmadan teslim al',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _Benefit(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    title: 'Sipariş durumu',
                    subtitle: 'Rezervasyon onayı ve teslimat bilgisi',
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _allow,
                      child: _busy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Bildirimlere İzin Ver'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: _busy ? null : _skip,
                    child: const Text('Şimdi değil'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Bu tercihi ayarlardan istediğin zaman değiştirebilirsin.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
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

/// Sallanan zil. Dikkat cekiyor ama rahatsiz etmiyor.
class _BellIllustration extends StatefulWidget {
  const _BellIllustration();

  @override
  State<_BellIllustration> createState() => _BellIllustrationState();
}

class _BellIllustrationState extends State<_BellIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _tilt;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // Ilk 600 ms sallaniyor, kalan surede duruyor.
    _tilt = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.16), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 0.16, end: -0.16), weight: 8),
      TweenSequenceItem(tween: Tween(begin: -0.16, end: 0.10), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 0.10, end: 0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 68),
    ]).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _tilt,
          builder: (context, child) => Transform.rotate(
            angle: _tilt.value,
            alignment: Alignment.topCenter,
            child: child,
          ),
          child: const Icon(
            Icons.notifications_active_rounded,
            size: 56,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(icon, size: 20, color: color),
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
      ],
    );
  }
}

/// Gerekiyorsa izin ekranini acar.
/// Tercih daha once kaydedilmisse hicbir sey yapmaz.
Future<void> maybeShowNotificationPrompt(
  BuildContext context,
  WidgetRef ref,
) async {
  final pref = await ref.read(notificationPreferenceProvider.future);

  // Kullanici daha once karar vermisse tekrar sorma.
  if (pref.promptSeen || !context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const NotificationPermissionScreen(),
    ),
  );
}