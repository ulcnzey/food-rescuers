import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// ================================================================ ORTAK

/// Tum illustrasyonlarin paylastigi cizim yardimcilari.
/// Geometri 0-1 araliginda tanimlanir, sonra olceklenir; boylece
/// her boyutta ayni oranlar korunur.
mixin _IllustrationHelpers {
  double get progress;
  double get float;

  /// Arka plandaki organik leke. Duz daire yerine acisal dalgalanma
  /// kullanmak elle cizilmis hissini veren ana unsurdur.
  void drawBlob(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    double squash = 0.92,
  }) {
    final path = Path();

    for (var i = 0; i <= 360; i += 6) {
      final rad = i * math.pi / 180;
      final wobble = 1 +
          0.055 * math.sin(rad * 3 + float * 0.4) +
          0.035 * math.cos(rad * 5);
      final r = radius * wobble;
      final point = Offset(
        center.dx + r * math.cos(rad),
        center.dy + r * math.sin(rad) * squash,
      );
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  /// Bir yolu verilen ilerleme araliginda kismi cizer.
  /// PathMetric ile "kendini cizen cizgi" etkisi olusur.
  void drawAnimated(
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
      canvas.drawPath(metric.extractPath(0, metric.length * local), paint);
    }
  }

  /// Belirli bir esikten sonra beliren ogeler icin olcek degeri.
  double popIn(double threshold, {double span = 0.2}) =>
      ((progress - threshold) / span).clamp(0.0, 1.0);
}

/// Tum illustrasyonlar icin ortak animasyon iskeleti.
/// Cizim animasyonu bir kez calisir, salinim surekli tekrarlar.
class _AnimatedIllustration extends StatefulWidget {
  const _AnimatedIllustration({
    required this.size,
    required this.animate,
    required this.builder,
    this.drawDuration = const Duration(milliseconds: 1100),
  });

  final double size;
  final bool animate;
  final Duration drawDuration;
  final CustomPainter Function(double progress, double float, ThemeData theme)
      builder;

  @override
  State<_AnimatedIllustration> createState() => _AnimatedIllustrationState();
}

class _AnimatedIllustrationState extends State<_AnimatedIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _draw;
  late final AnimationController _floatCtrl;
  late final Animation<double> _drawAnim;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    _draw = AnimationController(vsync: this, duration: widget.drawDuration);
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _drawAnim = CurvedAnimation(parent: _draw, curve: Curves.easeOutCubic);
    _floatAnim = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _draw.forward();
      _floatCtrl.repeat(reverse: true);
    } else {
      _draw.value = 1;
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_drawAnim, _floatAnim]),
        builder: (context, _) => Transform.translate(
          offset: Offset(0, _floatAnim.value * 4),
          child: CustomPaint(
            painter: widget.builder(_drawAnim.value, _floatAnim.value, theme),
          ),
        ),
      ),
    );
  }
}

// ================================================================ ARAMA

/// Arama sonucu bulunamadi durumu.
class NoResultsIllustration extends StatelessWidget {
  const NoResultsIllustration({super.key, this.size = 200, this.animate = true});

  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return _AnimatedIllustration(
      size: size,
      animate: animate,
      builder: (p, f, theme) => _NoResultsPainter(
        progress: p,
        float: f,
        stroke: AppColors.primary,
        accent: AppColors.secondary,
        blob: AppColors.primary.withValues(alpha: 0.10),
      ),
    );
  }
}

class _NoResultsPainter extends CustomPainter with _IllustrationHelpers {
  _NoResultsPainter({
    required this.progress,
    required this.float,
    required this.stroke,
    required this.accent,
    required this.blob,
  });

  @override
  final double progress;
  @override
  final double float;

  final Color stroke;
  final Color accent;
  final Color blob;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    Offset p(double x, double y) => Offset(x * w, y * size.height);
    double s(double v) => v * w;

    drawBlob(canvas, p(0.5, 0.5), s(0.38), blob);

    final line = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = s(0.034)
      ..strokeCap = StrokeCap.round;

    // Buyutec camı
    final lens = Path()
      ..addOval(Rect.fromCircle(center: p(0.45, 0.44), radius: s(0.20)));
    drawAnimated(canvas, lens, line, from: 0.0, to: 0.55);

    // Sap
    final handle = Path()
      ..moveTo(p(0.60, 0.60).dx, p(0.60, 0.60).dy)
      ..lineTo(p(0.75, 0.76).dx, p(0.75, 0.76).dy);
    drawAnimated(canvas, handle, line, from: 0.55, to: 0.75);

    // Cam icindeki "bulunamadi" carpisi
    final t = popIn(0.75);
    if (t > 0) {
      final cross = Paint()
        ..color = accent.withValues(alpha: t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s(0.028)
        ..strokeCap = StrokeCap.round;

      canvas.save();
      final c = p(0.45, 0.44);
      canvas.translate(c.dx, c.dy);
      canvas.scale(t);
      canvas.rotate(float * 0.05);
      canvas.translate(-c.dx, -c.dy);

      canvas.drawLine(p(0.38, 0.37), p(0.52, 0.51), cross);
      canvas.drawLine(p(0.52, 0.37), p(0.38, 0.51), cross);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_NoResultsPainter old) =>
      old.progress != progress || old.float != float;
}

// ================================================================ BASARI

/// Rezervasyon tamamlandi, islem basarili durumlari.
class SuccessIllustration extends StatelessWidget {
  const SuccessIllustration({super.key, this.size = 200, this.animate = true});

  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return _AnimatedIllustration(
      size: size,
      animate: animate,
      drawDuration: const Duration(milliseconds: 900),
      builder: (p, f, theme) => _SuccessPainter(
        progress: p,
        float: f,
        stroke: AppColors.success,
        accent: AppColors.secondary,
        blob: AppColors.success.withValues(alpha: 0.12),
      ),
    );
  }
}

class _SuccessPainter extends CustomPainter with _IllustrationHelpers {
  _SuccessPainter({
    required this.progress,
    required this.float,
    required this.stroke,
    required this.accent,
    required this.blob,
  });

  @override
  final double progress;
  @override
  final double float;

  final Color stroke;
  final Color accent;
  final Color blob;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    Offset p(double x, double y) => Offset(x * w, y * size.height);
    double s(double v) => v * w;

    drawBlob(canvas, p(0.5, 0.5), s(0.36), blob);

    final ring = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = s(0.032)
      ..strokeCap = StrokeCap.round;

    // Halka
    final circle = Path()
      ..addOval(Rect.fromCircle(center: p(0.5, 0.5), radius: s(0.26)));
    drawAnimated(canvas, circle, ring, from: 0.0, to: 0.6);

    // Tik isareti
    final check = Path()
      ..moveTo(p(0.38, 0.51).dx, p(0.38, 0.51).dy)
      ..lineTo(p(0.46, 0.60).dx, p(0.46, 0.60).dy)
      ..lineTo(p(0.63, 0.41).dx, p(0.63, 0.41).dy);

    final checkPaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = s(0.045)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    drawAnimated(canvas, check, checkPaint, from: 0.6, to: 0.9);

    // Kutlama parcaciklari
    final t = popIn(0.75, span: 0.25);
    if (t > 0) {
      final dot = Paint()..color = accent.withValues(alpha: t * 0.9);
      const positions = [
        [0.20, 0.28], [0.80, 0.30], [0.16, 0.68],
        [0.84, 0.66], [0.50, 0.14], [0.50, 0.88],
      ];

      for (var i = 0; i < positions.length; i++) {
        final base = p(positions[i][0], positions[i][1]);
        final drift = float * (i.isEven ? 2.5 : -2.5);
        canvas.drawCircle(
          Offset(base.dx, base.dy + drift),
          s(0.020) * t,
          dot,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SuccessPainter old) =>
      old.progress != progress || old.float != float;
}

// ================================================================ DUKKAN

/// Isletme kaydi yok, magaza bulunamadi durumlari.
class StorefrontIllustration extends StatelessWidget {
  const StorefrontIllustration({
    super.key,
    this.size = 200,
    this.animate = true,
  });

  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return _AnimatedIllustration(
      size: size,
      animate: animate,
      builder: (p, f, theme) => _StorefrontPainter(
        progress: p,
        float: f,
        stroke: AppColors.primary,
        accent: AppColors.secondary,
        blob: AppColors.secondary.withValues(alpha: 0.12),
      ),
    );
  }
}

class _StorefrontPainter extends CustomPainter with _IllustrationHelpers {
  _StorefrontPainter({
    required this.progress,
    required this.float,
    required this.stroke,
    required this.accent,
    required this.blob,
  });

  @override
  final double progress;
  @override
  final double float;

  final Color stroke;
  final Color accent;
  final Color blob;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    Offset p(double x, double y) => Offset(x * w, y * size.height);
    double s(double v) => v * w;

    drawBlob(canvas, p(0.5, 0.52), s(0.38), blob);

    final line = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = s(0.030)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Dukkan govdesi
    final body = Path()
      ..moveTo(p(0.24, 0.46).dx, p(0.24, 0.46).dy)
      ..lineTo(p(0.24, 0.80).dx, p(0.24, 0.80).dy)
      ..lineTo(p(0.76, 0.80).dx, p(0.76, 0.80).dy)
      ..lineTo(p(0.76, 0.46).dx, p(0.76, 0.46).dy);
    drawAnimated(canvas, body, line, from: 0.0, to: 0.45);

    // Tente: dalgali alt kenar
    final awning = Path()..moveTo(p(0.18, 0.46).dx, p(0.18, 0.46).dy);
    for (var i = 0; i < 4; i++) {
      final x0 = 0.18 + i * 0.16;
      awning.quadraticBezierTo(
        p(x0 + 0.08, 0.53).dx, p(x0 + 0.08, 0.53).dy,
        p(x0 + 0.16, 0.46).dx, p(x0 + 0.16, 0.46).dy,
      );
    }
    awning.lineTo(p(0.82, 0.34).dx, p(0.82, 0.34).dy);
    awning.lineTo(p(0.18, 0.34).dx, p(0.18, 0.34).dy);
    awning.close();

    final awningPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = s(0.030)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    drawAnimated(canvas, awning, awningPaint, from: 0.35, to: 0.75);

    // Kapi
    final door = Path()
      ..moveTo(p(0.43, 0.80).dx, p(0.43, 0.80).dy)
      ..lineTo(p(0.43, 0.61).dx, p(0.43, 0.61).dy)
      ..lineTo(p(0.57, 0.61).dx, p(0.57, 0.61).dy)
      ..lineTo(p(0.57, 0.80).dx, p(0.57, 0.80).dy);
    drawAnimated(canvas, door, line, from: 0.65, to: 0.9);

    // Tabela kalbi
    final t = popIn(0.8);
    if (t > 0) {
      canvas.save();
      final c = p(0.5, 0.22);
      canvas.translate(c.dx, c.dy + float * 2);
      canvas.scale(t);
      canvas.translate(-c.dx, -c.dy);

      final heart = Path()
        ..moveTo(p(0.50, 0.26).dx, p(0.50, 0.26).dy)
        ..cubicTo(
          p(0.40, 0.20).dx, p(0.40, 0.20).dy,
          p(0.43, 0.14).dx, p(0.43, 0.14).dy,
          p(0.50, 0.18).dx, p(0.50, 0.18).dy,
        )
        ..cubicTo(
          p(0.57, 0.14).dx, p(0.57, 0.14).dy,
          p(0.60, 0.20).dx, p(0.60, 0.20).dy,
          p(0.50, 0.26).dx, p(0.50, 0.26).dy,
        )
        ..close();

      canvas.drawPath(heart, Paint()..color = accent.withValues(alpha: 0.85));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_StorefrontPainter old) =>
      old.progress != progress || old.float != float;
}