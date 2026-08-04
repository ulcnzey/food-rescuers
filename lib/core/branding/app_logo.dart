import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppLogoMark extends StatelessWidget {
  final double size;
  final bool monochrome;
  final Color? color;

  const AppLogoMark({
    super.key,
    this.size = 48,
    this.monochrome = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bowlColor = monochrome
        ? (color ?? theme.colorScheme.onSurface)
        : AppColors.primary;
    final leafColor = monochrome
        ? (color ?? theme.colorScheme.onSurface)
        : AppColors.secondary;

    return CustomPaint(
      size: Size(size, size),
      painter: _AppLogoPainter(
        bowlColor: bowlColor,
        leafColor: leafColor,
        leafProgress: 1.0,
        scale: 1.0,
      ),
    );
  }
}

class AppLogoFull extends StatelessWidget {
  final double size;
  final bool monochrome;
  final Color? color;
  final bool showTagline;

  const AppLogoFull({
    super.key,
    this.size = 40,
    this.monochrome = false,
    this.color,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTextColor = monochrome
        ? (color ?? theme.colorScheme.onSurface)
        : AppColors.primary;
    final secondaryTextColor = theme.brightness == Brightness.light
        ? AppColors.textLight
        : AppColors.textDark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppLogoMark(
              size: size,
              monochrome: monochrome,
              color: color,
            ),
            SizedBox(width: size * 0.25),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Food',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: size * 0.75,
                    fontWeight: FontWeight.normal,
                    color: secondaryTextColor,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Rescuers',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: size * 0.75,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (showTagline) ...[
          SizedBox(height: size * 0.1),
          Padding(
            padding: EdgeInsets.only(left: size * 1.25),
            child: Text(
              'Kurtarılan her öğün bir umut',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: size * 0.3,
                color: theme.brightness == Brightness.light
                    ? AppColors.textMutedLight
                    : AppColors.textMutedDark,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class AnimatedAppLogo extends StatefulWidget {
  final double size;

  const AnimatedAppLogo({super.key, this.size = 120});

  @override
  State<AnimatedAppLogo> createState() => _AnimatedAppLogoState();
}

class _AnimatedAppLogoState extends State<AnimatedAppLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _leafAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Leaf draws itself in first 900ms (0.0 to 0.75 of controller)
    _leafAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeInOutCubic),
      ),
    );

    // Settle scale animation in last 300ms (0.75 to 1.0 of controller)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _AppLogoPainter(
              bowlColor: AppColors.primary,
              leafColor: AppColors.secondary,
              leafProgress: _leafAnimation.value,
              scale: _scaleAnimation.value,
            ),
          ),
        );
      },
    );
  }
}

class _AppLogoPainter extends CustomPainter {
  final Color bowlColor;
  final Color leafColor;
  final double leafProgress;
  final double scale;

  _AppLogoPainter({
    required this.bowlColor,
    required this.leafColor,
    required this.leafProgress,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Define stroke widths based on size to ensure legibility
    final double strokeWidth = (w * 0.08).clamp(2.0, 16.0);

    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Draw the Bowl (Stylized half-ellipse)
    // Positioned in the lower half of the size bounds
    paint.color = bowlColor;
    paint.strokeWidth = strokeWidth;

    final bowlPath = Path()
      ..moveTo(w * 0.15, h * 0.6)
      ..cubicTo(
        w * 0.15, h * 0.9, // Control 1
        w * 0.85, h * 0.9, // Control 2
        w * 0.85, h * 0.6, // End point
      );

    canvas.drawPath(bowlPath, paint);

    // 2. Draw the Leaf shape (Doubles as a rescuing hand/cradle gesture)
    if (leafProgress > 0) {
      final leafPaint = Paint()
        ..isAntiAlias = true
        ..color = leafColor
        ..style = PaintingStyle.fill;

      // We animate the path generation based on leafProgress
      final leafPath = Path();

      // The base of the leaf stems from bottom center inside the bowl
      final double startX = w * 0.5;
      final double startY = h * 0.7;

      // Peak of the leaf when fully grown
      final double targetPeakY = h * 0.12;
      final double currentPeakY = startY - (startY - targetPeakY) * leafProgress;

      // Right tip (hand/thumb branch representation)
      final double targetThumbX = w * 0.72;
      final double targetThumbY = h * 0.38;
      final double currentThumbX = startX + (targetThumbX - startX) * leafProgress;
      final double currentThumbY = startY - (startY - targetThumbY) * leafProgress;

      leafPath.moveTo(startX, startY);

      // Left edge of the leaf (cradling curve)
      leafPath.cubicTo(
        w * 0.28, startY - (startY - h * 0.45) * leafProgress, // Left control
        w * 0.30, startY - (startY - h * 0.15) * leafProgress, // Left control 2
        startX, currentPeakY, // Tip of leaf
      );

      // Right edge of the leaf (descending down to thumb)
      leafPath.cubicTo(
        startX + (w * 0.08) * leafProgress, startY - (startY - h * 0.22) * leafProgress,
        currentThumbX - (w * 0.02) * leafProgress, currentThumbY - (h * 0.1) * leafProgress,
        currentThumbX, currentThumbY,
      );

      // Crotch between thumb and leaf body
      leafPath.cubicTo(
        currentThumbX - (w * 0.08) * leafProgress, currentThumbY + (h * 0.08) * leafProgress,
        startX + (w * 0.12) * leafProgress, startY - (startY - h * 0.55) * leafProgress,
        startX, startY,
      );

      canvas.drawPath(leafPath, leafPaint);

      // Draw secondary details / leaf vein / palm crease line to look premium
      if (leafProgress > 0.6) {
        final detailPaint = Paint()
          ..isAntiAlias = true
          ..color = Colors.white.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (w * 0.035).clamp(1.2, 5.0)
          ..strokeCap = StrokeCap.round;

        final detailPath = Path()
          ..moveTo(startX, startY - (startY - h * 0.58) * leafProgress)
          ..quadraticBezierTo(
            startX - (w * 0.05) * leafProgress,
            startY - (startY - h * 0.40) * leafProgress,
            startX - (w * 0.02) * leafProgress,
            startY - (startY - h * 0.26) * leafProgress,
          );
        canvas.drawPath(detailPath, detailPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AppLogoPainter oldDelegate) {
    return oldDelegate.bowlColor != bowlColor ||
        oldDelegate.leafColor != leafColor ||
        oldDelegate.leafProgress != leafProgress ||
        oldDelegate.scale != scale;
  }
}
