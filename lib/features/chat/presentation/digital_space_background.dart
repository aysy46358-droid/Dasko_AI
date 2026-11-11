import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_theme_mode.dart';

/// Animated starfield, volumetric nebula and perspective grid used behind UI.
///
/// Palette-aware: [AppThemeMode.dark] renders a flat pitch-black canvas,
/// [AppThemeMode.neon] keeps the deep space field, and light mode uses a light
/// wash of the same accents so surfaces are never painted over a dark
/// backdrop.
class DigitalSpaceBackground extends ConsumerStatefulWidget {
  const DigitalSpaceBackground({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DigitalSpaceBackground> createState() =>
      _DigitalSpaceBackgroundState();
}

class _DigitalSpaceBackgroundState extends ConsumerState<DigitalSpaceBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  )..repeat();

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final appThemeMode = ref.watch(themeProvider);

    // Pitch-black Dark palette: a flat canvas, no gradient, no blue tint and
    // no starfield -- the LED bubbles are the only light source.
    if (appThemeMode == AppThemeMode.dark) {
      return ColoredBox(color: AppTheme.darkBackground, child: widget.child);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.2, -0.5),
              radius: 1.25,
              colors: isLight
                  ? <Color>[colors.surface, theme.scaffoldBackgroundColor]
                  : const <Color>[
                      Color(0xFF18223B),
                      Color(0xFF101426),
                      Color(0xFF0B0F19),
                    ],
              stops: isLight
                  ? const <double>[0, 1]
                  : const <double>[0, 0.48, 1],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _motion,
          builder: (context, _) => CustomPaint(
            painter: _SpacePainter(
              phase: _motion.value,
              brightness: theme.brightness,
              primary: colors.primary,
              secondary: colors.secondary,
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _SpacePainter extends CustomPainter {
  const _SpacePainter({
    required this.phase,
    required this.brightness,
    required this.primary,
    required this.secondary,
  });

  final double phase;
  final Brightness brightness;
  final Color primary;
  final Color secondary;

  bool get _isLight => brightness == Brightness.light;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final center = Offset(size.width * 0.5, size.height * 0.43);
    final nebula = Paint()
      ..shader = RadialGradient(
        colors: [
          primary.withValues(alpha: _isLight ? 0.10 : 0.075),
          secondary.withValues(alpha: _isLight ? 0.08 : 0.065),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * .75));
    canvas.drawRect(Offset.zero & size, nebula);

    // A slowly rotating set of orbital ellipses adds depth behind the robot.
    for (var i = 0; i < 6; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(phase * math.pi * 2 * (i.isEven ? 0.08 : -0.055) + i * .18);
      final orbit = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = (i.isEven ? primary : secondary).withValues(
          alpha: (_isLight ? 0.18 : 0.12) + (i % 3) * .035,
        );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * (0.55 + i * .16),
          height: size.height * (0.09 + i * .018),
        ),
        orbit,
      );
      canvas.restore();
    }

    // Perspective floor grid converges toward the digital horizon.
    final horizonY = size.height * .72;
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..color = primary.withValues(alpha: _isLight ? .06 : .10);
    for (var i = -8; i <= 8; i++) {
      final bottomX = size.width * .5 + i * size.width * .11;
      canvas.drawLine(
        Offset(size.width * .5 + i * size.width * .012, horizonY),
        Offset(bottomX, size.height),
        grid,
      );
    }
    for (var i = 0; i < 12; i++) {
      final t = i / 11;
      final eased = t * t;
      final y = horizonY + eased * (size.height - horizonY);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Stable pseudo-random stars drift gently; no runtime randomness or jitter.
    final starPaint = Paint();
    final starAlphaScale = _isLight ? 0.45 : 1.0;
    for (var i = 0; i < 54; i++) {
      final baseX = ((i * 73 + 19) % 997) / 997 * size.width;
      final baseY = ((i * 137 + 41) % 991) / 991 * size.height;
      final drift = (phase * (8 + i % 9) + i * 3.7) % 22;
      final x = (baseX + drift) % size.width;
      final y = baseY;
      final radius = i % 7 == 0 ? 1.55 : (i % 3 == 0 ? 1.0 : .55);
      starPaint
        ..color = (i.isEven ? primary : secondary).withValues(
          alpha:
              (.24 + ((math.sin(phase * math.pi * 2 + i) + 1) * .19)) *
              starAlphaScale,
        )
        ..maskFilter = i % 7 == 0
            ? const MaskFilter.blur(BlurStyle.normal, 2)
            : null;
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }

    // Vignette only makes sense on the dark canvas.
    if (!_isLight) {
      final vignette = Paint()
        ..shader = const RadialGradient(
          radius: .85,
          colors: [Colors.transparent, Color(0xAA050811)],
          stops: [.42, 1],
        ).createShader(Offset.zero & size);
      canvas.drawRect(Offset.zero & size, vignette);
    }
  }

  @override
  bool shouldRepaint(covariant _SpacePainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.brightness != brightness ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary;
}
