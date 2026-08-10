import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/illustrations/app_illustrations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../reservations/presentation/controllers/reservation_controller.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  /// Manuel kod girisi icin. Ekran omru boyunca yasar,
  /// boylece diyalog kapanirken silinmis controller'a erisilmez.
  final _codeController = TextEditingController();

  /// Ayni kod arka arkaya okunmasin diye islem sirasinda kilitlenir.
  bool _processing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _scanner.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;

    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _processing = true);
    await _scanner.stop();

    await _verify(() => ref
        .read(reservationControllerProvider.notifier)
        .completeByQr(raw));
  }

  /// Dogrulama sonucunu ortak sekilde isler.
  Future<void> _verify(Future<bool> Function() action) async {
    final ok = await action();

    if (!mounted) return;

    if (ok) {
      await _showResult(success: true);
    } else {
      final error = ref.read(reservationControllerProvider).errorMessage;
      await _showResult(success: false, message: error);
    }
  }

  Future<void> _showResult({required bool success, String? message}) async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => _ResultSheet(
        success: success,
        message: message,
        onContinue: () => Navigator.of(ctx).pop(),
      ),
    );

    if (!mounted) return;

    // Kamerayi tekrar baslat, siradaki musteriye hazir olsun.
    setState(() => _processing = false);
    await _scanner.start();
  }

  /// QR okunamazsa 6 haneli kodu elle girme secenegi.
  Future<void> _enterCodeManually() async {
    _codeController.clear();

    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Doğrulama Kodu'),
        content: TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            hintText: '123456',
            counterText: '',
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_codeController.text.trim()),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );

    if (code == null || code.length != 6 || !mounted) return;

    setState(() => _processing = true);

    await _verify(() => ref
        .read(reservationControllerProvider.notifier)
        .completeByCode(code));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _scanner, onDetect: _onDetect),

          // ---- Karartma + okuma penceresi
          const _ScannerOverlay(),

          // ---- Ust cubuk
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  _CircleButton(
                    icon: _torchOn
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    onTap: () {
                      _scanner.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ---- Alt yonlendirme
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _processing
                          ? 'Doğrulanıyor...'
                          : 'Müşterinin QR kodunu okut',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Kodu çerçeve içine hizala',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextButton.icon(
                      onPressed: _processing ? null : _enterCodeManually,
                      icon: const Icon(Icons.keyboard_rounded, size: 18),
                      label: const Text('Kodu elle gir'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_processing)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- PARCALAR

/// Ortasi seffaf, kenarlari karartilmis okuma penceresi.
class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = c.maxWidth * 0.68;
        final left = (c.maxWidth - size) / 2;
        final top = (c.maxHeight - size) / 2 - 40;

        return Stack(
          children: [
            // Karartma: pencere disinda kalan alan
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.62),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Kose isaretleri
            Positioned(
              left: left,
              top: top,
              child: SizedBox(
                width: size,
                height: size,
                child: CustomPaint(painter: _CornerPainter()),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const len = 32.0;
    const r = 24.0;

    // Sol ust
    canvas.drawPath(
      Path()
        ..moveTo(0, len + r)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(len + r, 0),
      paint,
    );
    // Sag ust
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len - r, 0)
        ..lineTo(size.width - r, 0)
        ..quadraticBezierTo(size.width, 0, size.width, r)
        ..lineTo(size.width, len + r),
      paint,
    );
    // Sag alt
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - len - r)
        ..lineTo(size.width, size.height - r)
        ..quadraticBezierTo(
            size.width, size.height, size.width - r, size.height)
        ..lineTo(size.width - len - r, size.height),
      paint,
    );
    // Sol alt
    canvas.drawPath(
      Path()
        ..moveTo(len + r, size.height)
        ..lineTo(r, size.height)
        ..quadraticBezierTo(0, size.height, 0, size.height - r)
        ..lineTo(0, size.height - len - r),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.20),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// Okuma sonucu: basarili veya hatali.
class _ResultSheet extends StatelessWidget {
  const _ResultSheet({
    required this.success,
    required this.message,
    required this.onContinue,
  });

  final bool success;
  final String? message;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (success)
              const SizedBox(
                width: 140,
                height: 140,
                child: SuccessIllustration(size: 140),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
              ),

            const SizedBox(height: AppSpacing.lg),
            Text(
              success ? 'Teslimat onaylandı' : 'Doğrulanamadı',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              success
                  ? 'Ürünü müşteriye teslim edebilirsin. Bu kod artık '
                      'kullanılamaz.'
                  : (message ?? 'Kod geçersiz veya daha önce kullanılmış.'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onContinue,
                style: success
                    ? null
                    : FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                child: const Text('Devam Et'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}