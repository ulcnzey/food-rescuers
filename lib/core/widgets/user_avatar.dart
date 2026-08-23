import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Vektorel avatar seti. Gorsel dosyasi yok; her avatar
/// CustomPainter ile ciziliyor. APK boyutu artmiyor,
/// her boyutta keskin kaliyor.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.avatarId,
    this.size = 56,
    this.showBorder = false,
  });

  final int avatarId;
  final double size;
  final bool showBorder;

  /// Toplam avatar sayisi.
  static const count = 8;

  /// Her avatarin zemin rengi.
  static const _bgColors = [
    Color(0xFFC5E4DA),
    Color(0xFFFDE8C8),
    Color(0xFFD6E4F7),
    Color(0xFFF7D6E0),
    Color(0xFFE0DBF5),
    Color(0xFFD8F0D8),
    Color(0xFFFAE0D0),
    Color(0xFFD5EEF0),
  ];

  static const _fgColors = [
    Color(0xFF0F4C42),
    Color(0xFFB57415),
    Color(0xFF2C5C96),
    Color(0xFF9B3D5E),
    Color(0xFF5A4A96),
    Color(0xFF2E7A3E),
    Color(0xFFB35A2A),
    Color(0xFF1F6B72),
  ];

  @override
  Widget build(BuildContext context) {
    final index = avatarId.clamp(0, count - 1);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bgColors[index],
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: Colors.white, width: size * 0.05)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _AvatarPainter(index: index, color: _fgColors[index]),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter({required this.index, required this.color});

  final int index;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    Offset p(double x, double y) => Offset(x * w, y * size.height);
    double s(double v) => v * w;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s(0.055)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()..color = color;

    // Ortak: yuz cemberi
    canvas.drawCircle(p(0.5, 0.52), s(0.28), stroke);

    // Gozler
    switch (index % 4) {
      case 0: // yuvarlak gozler
        canvas.drawCircle(p(0.41, 0.47), s(0.035), fill);
        canvas.drawCircle(p(0.59, 0.47), s(0.035), fill);
        break;
      case 1: // gozluklu
        canvas.drawCircle(p(0.40, 0.47), s(0.075), stroke);
        canvas.drawCircle(p(0.60, 0.47), s(0.075), stroke);
        canvas.drawLine(p(0.475, 0.47), p(0.525, 0.47), stroke);
        break;
      case 2: // cizgi gozler
        canvas.drawLine(p(0.37, 0.47), p(0.44, 0.47), stroke);
        canvas.drawLine(p(0.56, 0.47), p(0.63, 0.47), stroke);
        break;
      case 3: // gulen gozler
        canvas.drawArc(
          Rect.fromCircle(center: p(0.41, 0.48), radius: s(0.05)),
          math.pi, math.pi, false, stroke,
        );
        canvas.drawArc(
          Rect.fromCircle(center: p(0.59, 0.48), radius: s(0.05)),
          math.pi, math.pi, false, stroke,
        );
        break;
    }

    // Agiz
    if (index < 4) {
      canvas.drawArc(
        Rect.fromCircle(center: p(0.5, 0.55), radius: s(0.11)),
        0.25, math.pi - 0.5, false, stroke,
      );
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: p(0.5, 0.57), radius: s(0.09)),
        0.4, math.pi - 0.8, false, stroke,
      );
    }

    // Ust aksesuar: sac, sapka, yaprak
    switch (index) {
      case 0:
      case 4: // yaprak
        final leaf = Path()
          ..moveTo(p(0.5, 0.22).dx, p(0.5, 0.22).dy)
          ..cubicTo(
            p(0.65, 0.14).dx, p(0.65, 0.14).dy,
            p(0.68, 0.05).dx, p(0.68, 0.05).dy,
            p(0.56, 0.08).dx, p(0.56, 0.08).dy,
          )
          ..cubicTo(
            p(0.48, 0.11).dx, p(0.48, 0.11).dy,
            p(0.47, 0.18).dx, p(0.47, 0.18).dy,
            p(0.5, 0.22).dx, p(0.5, 0.22).dy,
          );
        canvas.drawPath(leaf, Paint()..color = AppColors.freeBadge);
        break;

      case 1:
      case 5: // sac
        canvas.drawArc(
          Rect.fromCircle(center: p(0.5, 0.52), radius: s(0.28)),
          math.pi + 0.3, math.pi - 0.6, false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = s(0.10)
            ..strokeCap = StrokeCap.round,
        );
        break;

      case 2:
      case 6: // sapka
        canvas.drawLine(p(0.26, 0.34), p(0.74, 0.34), stroke);
        final cap = Path()
          ..moveTo(p(0.33, 0.34).dx, p(0.33, 0.34).dy)
          ..quadraticBezierTo(
            p(0.5, 0.14).dx, p(0.5, 0.14).dy,
            p(0.67, 0.34).dx, p(0.67, 0.34).dy,
          );
        canvas.drawPath(cap, stroke);
        break;

      case 3:
      case 7: // fiyonk
        canvas.drawCircle(p(0.71, 0.30), s(0.055), fill);
        canvas.drawCircle(p(0.79, 0.27), s(0.045), fill);
        break;
    }
  }

  @override
  bool shouldRepaint(_AvatarPainter old) =>
      old.index != index || old.color != color;
}

/// Avatar secme alt sayfasi.
Future<int?> showAvatarPicker(BuildContext context, int current) {
  return showModalBottomSheet<int>(
    context: context,
    builder: (ctx) {
      var selected = current;

      return StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Avatarını seç',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),

                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: List.generate(UserAvatar.count, (i) {
                    final active = selected == i;

                    return GestureDetector(
                      onTap: () => setState(() => selected = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: active
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: UserAvatar(avatarId: i, size: 64),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(selected),
                    child: const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}