import 'package:flutter/material.dart';

/// Listeye kademeli giris. Her ogenin index'ine gore gecikme uygular,
/// boylece kartlar sirayla belirir.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delayStep = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 380),
    this.offsetY = 24,
  });

  final Widget child;
  final int index;
  final Duration delayStep;
  final Duration duration;
  final double offsetY;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(vsync: this, duration: widget.duration);

    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offsetY / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

    // Index'e gore gecikmeli baslat.
    Future<void>.delayed(widget.delayStep * widget.index, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Basinca hafif kuculen dokunma tepkisi.
/// Fiziksel geri bildirim hissi verir.
class BouncyTap extends StatefulWidget {
  const BouncyTap({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// 0'dan hedefe sayan rakam. Etki istatistiklerinde kullanilir.
class CounterText extends StatelessWidget {
  const CounterText({
    super.key,
    required this.value,
    this.style,
    this.suffix = '',
    this.decimals = 0,
    this.duration = const Duration(milliseconds: 900),
  });

  final double value;
  final TextStyle? style;
  final String suffix;
  final int decimals;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '${v.toStringAsFixed(decimals)}$suffix',
        style: style,
      ),
    );
  }
}

/// Yukleme sirasinda icerigin yerini tutan parlayan kutu.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.outline.withValues(alpha: 0.35);
    final highlight = theme.colorScheme.outline.withValues(alpha: 0.12);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1 + _c.value * 3, 0),
            end: Alignment(_c.value * 3, 0),
            colors: [base, highlight, base],
          ),
        ),
      ),
    );
  }
}

/// Ekran gecisleri. Varsayilan Material gecisi yerine
/// daha yumusak bir kayma + solma kullanir.
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  SmoothPageRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, _, _) => page,
          transitionsBuilder: (_, animation, _, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );

  final Widget page;
}