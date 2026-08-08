import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Bos liste durumlarinda kullanilan illustrasyon.
/// Kalin konturlu, dolgu kullanmayan, organik egrili cizim dili.
/// Tamamen vektorel; asset dosyasi yok, her boyutta keskin,
/// tema degisiminde renkler otomatik uyum saglar.
class EmptyBasketIllustration extends StatefulWidget {
  const EmptyBasketIllustration({
    super.key,
    this.size = 200,
    this.animate = true,
  });

  final double size;
  final bool animate;

  @override
  State<EmptyBasketIllustration> createState() =>
      _EmptyBasketIllustrationState();
}

class _EmptyBasketIllustrationState extends State<EmptyBasketIllustration>
    with TickerProviderStateMixin {
  /// Cizginin kendini cizmesi (0 -> 1)
  late final AnimationController _drawController;

  /// Surekli tekrarlayan hafif salinim
  late final AnimationController _floatController;

  late final Animation<double> _draw;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();

    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _draw = CurvedAnimation(
      parent: _drawController,
      curve: Curves.easeOutCubic,
    );

    _float = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _drawController.forward();
      _floatController.repeat(reverse: true);
    } else {
      _drawController.value = 1;
    }
  }

  @override
  void dispose() {
    _drawController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_draw, _float]),
        builder: (context, _) {
          return Transform.translate(
            offset: Offset(0, _float.value * 4),
            child: CustomPaint(
              painter: _EmptyBasketPainter(
                progress: _draw.value,
                float: _float.value,
                stroke: AppColors.primary,
                accent: AppColors.secondary,
                blob: AppColors.primary.withValues(alpha: 0.10),
                muted: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.35),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyBasketPainter extends CustomPainter {
  _EmptyBasketPainter({
    required this.progress,
    required this.float,
    required this.stroke,
    required this.accent,
    required this.blob,
    required this.muted,
  });

  /// 0 -> cizim baslamadi, 1 -> tamamlandi
  final double progress;

  /// -1 .. 1 arasi salinim degeri
  final double float;

  final Color stroke;
  final Color accent;
  final Color blob;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Butun geometri 0-1 araliginda tanimli, sonra olceklenir.
    // Boylece her boyutta ayni oranlar korunur.
    Offset p(double x, double y) => Offset(x * w, y * h);
    double s(double v) => v * w;

    // ---- 1) Arka plandaki organik leke
    _drawBlob(canvas, size, p, s);

    // ---- 2) Sepet govdesi
    _drawBasket(canvas, p, s);

    // ---- 3) Sap
    _drawHandle(canvas, p, s);

    // ---- 4) Ucusan yaprak (vurgu rengi)
    _drawLeaf(canvas, p, s);

    // ---- 5) Kesik cizgili "bos" isareti
    _drawDashes(canvas, p, s);
  }

  /// Arka planda yumusak, duzensiz bir leke.
  /// Duz daire yerine bunu kullanmak elle cizilmis hissi verir.
  void _drawBlob(
    Canvas canvas,
    Size size,
    Offset Function(double, double) p,
    double Function(double) s,
  ) {
    final path = Path();
    final center = p(0.5, 0.52);
    final radius = s(0.40);

    // Yaricapi acisal olarak dalgalandirarak organik sekil uretiyoruz.
    for (var i = 0; i <= 360; i += 6) {
      final rad = i * math.pi / 180;
      final wobble = 1 +
          0.055 * math.sin(rad * 3 + float * 0.4) +
          0.035 * math.cos(rad * 5);
      final r = radius * wobble;
      final point = Offset(
        center.dx + r * math.cos(rad),
        center.dy + r * math.sin(rad) * 0.92,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = blob);
  }

  void _drawBasket(
    Canvas canvas,
    Offset Function(double, double) p,
    double Function(double) s,
  ) {
    final paint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = s(0.032)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Sepet: ust kenari genis, tabani dar bir kase.
    final body = Path()
      ..moveTo(p(0.24, 0.52).dx, p(0.24, 0.52).dy)
      ..cubicTo(
        p(0.25, 0.74).dx, p(0.25, 0.74).dy,
        p(0.32, 0.84).dx, p(0.32, 0.84).dy,
        p(0.50, 0.845).dx, p(0.50, 0.845).dy,
      )
      ..cubicTo(
        p(0.68, 0.84).dx, p(0.68, 0.84).dy,
        p(0.75, 0.74).dx, p(0.75, 0.74).dy,
        p(0.76, 0.52).dx, p(0.76, 0.52).dy,
      );

    _drawAnimated(canvas, body, paint, from: 0.0, to: 0.55);

    // Ust kenar cizgisi
    final rim = Path()
      ..moveTo(p(0.21, 0.52).dx, p(0.21, 0.52).dy)
      ..quadraticBezierTo(
        p(0.50, 0.47).dx, p(0.50, 0.47).dy,
        p(0.79, 0.52).dx, p(0.79, 0.52).dy,
      );

    _drawAnimated(canvas, rim, paint, from: 0.10, to: 0.60);

    // Ic dokusu: iki dikey cizgi (hasir sepet hissi)
    final texture = Paint()
      ..color = stroke.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s(0.018)
      ..strokeCap = StrokeCap.round;

    final line1 = Path()
      ..moveTo(p(0.40, 0.56).dx, p(0.40, 0.56).dy)
      ..lineTo(p(0.385, 0.80).dx, p(0.385, 0.80).dy);
    final line2 = Path()
      ..moveTo(p(0.60, 0.56).dx, p(0.60, 0.56).dy)
      ..lineTo(p(0.615, 0.80).dx, p(0.615, 0.80).dy);

    _drawAnimated(canvas, line1, texture, from: 0.45, to: 0.75);
    _drawAnimated(canvas, line2, texture, from: 0.50, to: 0.80);
  }

  void _drawHandle(
    Canvas canvas,
    Offset Function(double, double) p,
    double Function(double) s,
  ) {
    final paint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = s(0.028)
      ..strokeCap = StrokeCap.round;

    final handle = Path()
      ..moveTo(p(0.34, 0.50).dx, p(0.34, 0.50).dy)
      ..cubicTo(
        p(0.34, 0.30).dx, p(0.34, 0.30).dy,
        p(0.66, 0.30).dx, p(0.66, 0.30).dy,
        p(0.66, 0.50).dx, p(0.66, 0.50).dy,
      );

    _drawAnimated(canvas, handle, paint, from: 0.55, to: 0.85);
  }

  /// Sepetin uzerinde suzulen yaprak. Salinimla birlikte hafif doner.
  void _drawLeaf(
    Canvas canvas,
    Offset Function(double, double) p,
    double Function(double) s,
  ) {
    if (progress < 0.75) return;

    final t = ((progress - 0.75) / 0.25).clamp(0.0, 1.0);

    canvas.save();
    final pivot = p(0.70, 0.26);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(float * 0.10);
    canvas.scale(t);
    canvas.translate(-pivot.dx, -pivot.dy);

    final fill = Paint()..color = accent.withValues(alpha: 0.85);

    final leaf = Path()
      ..moveTo(p(0.70, 0.18).dx, p(0.70, 0.18).dy)
      ..cubicTo(
        p(0.83, 0.20).dx, p(0.83, 0.20).dy,
        p(0.84, 0.30).dx, p(0.84, 0.30).dy,
        p(0.71, 0.33).dx, p(0.71, 0.33).dy,
      )
      ..cubicTo(
        p(0.66, 0.30).dx, p(0.66, 0.30).dy,
        p(0.65, 0.21).dx, p(0.65, 0.21).dy,
        p(0.70, 0.18).dx, p(0.70, 0.18).dy,
      )
      ..close();

    canvas.drawPath(leaf, fill);

    // Yaprak damari
    final vein = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s(0.012)
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      Path()
        ..moveTo(p(0.695, 0.20).dx, p(0.695, 0.20).dy)
        ..quadraticBezierTo(
          p(0.74, 0.26).dx, p(0.74, 0.26).dy,
          p(0.715, 0.315).dx, p(0.715, 0.315).dy,
        ),
      vein,
    );

    canvas.restore();
  }

  /// Sepetin bos oldugunu anlatan kesik cizgili elips.
  void _drawDashes(
    Canvas canvas,
    Offset Function(double, double) p,
    double Function(double) s,
  ) {
    if (progress < 0.85) return;

    final t = ((progress - 0.85) / 0.15).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = muted.withValues(alpha: 0.55 * t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s(0.014)
      ..strokeCap = StrokeCap.round;

    final center = p(0.50, 0.635);
    final rx = s(0.155);
    final ry = s(0.055);

    // 12 parcali kesik elips
    const segments = 12;
    for (var i = 0; i < segments; i++) {
      final start = (i / segments) * 2 * math.pi;
      final end = start + (2 * math.pi / segments) * 0.55;

      final path = Path();
      const steps = 6;
      for (var j = 0; j <= steps; j++) {
        final a = start + (end - start) * (j / steps);
        final point = Offset(
          center.dx + rx * math.cos(a),
          center.dy + ry * math.sin(a),
        );
        if (j == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  /// Bir yolu, verilen ilerleme araliginda kismi olarak cizer.
  /// PathMetric kullanarak "kendini cizen cizgi" etkisi olusturur.
  void _drawAnimated(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double from,
    required double to,
  }) {
    final local = ((progress - from) / (to - from)).clamp(0.0, 1.0);
    if (local <= 0) return;

    if (local >= 1) {
      canvas.drawPath(path, paint);
      return;
    }

    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * local),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EmptyBasketPainter old) =>
      old.progress != progress || old.float != float;
}