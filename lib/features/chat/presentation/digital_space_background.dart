import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated starfield, volumetric nebula and perspective grid used behind UI.
class DigitalSpaceBackground extends StatefulWidget {
  const DigitalSpaceBackground({super.key, required this.child});

  final Widget child;

  @override
  State<DigitalSpaceBackground> createState() => _DigitalSpaceBackgroundState();
}

class _DigitalSpaceBackgroundState extends State<DigitalSpaceBackground>
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
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.2, -0.5),
              radius: 1.25,
              colors: [Color(0xFF18223B), Color(0xFF101426), Color(0xFF0B0F19)],
              stops: [0, 0.48, 1],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _motion,
          builder: (context, _) =>
              CustomPaint(painter: _SpacePainter(phase: _motion.value)),
        ),
        widget.child,
      ],
    );
  }
}

class _SpacePainter extends CustomPainter {
  const _SpacePainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final center = Offset(size.width * 0.5, size.height * 0.43);
    final nebula = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.075),
          const Color(0xFF7C4DFF).withValues(alpha: 0.065),
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
        ..color = (i.isEven ? const Color(0xFF00E5FF) : const Color(0xFF7C4DFF))
            .withValues(alpha: 0.12 + (i % 3) * .035);
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
      ..color = const Color(0xFF00E5FF).withValues(alpha: .10);
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
    for (var i = 0; i < 54; i++) {
      final baseX = ((i * 73 + 19) % 997) / 997 * size.width;
      final baseY = ((i * 137 + 41) % 991) / 991 * size.height;
      final drift = (phase * (8 + i % 9) + i * 3.7) % 22;
      final x = (baseX + drift) % size.width;
      final y = baseY;
      final radius = i % 7 == 0 ? 1.55 : (i % 3 == 0 ? 1.0 : .55);
      final color =
          i.isEven ? const Color(0xFF8DEFFF) : const Color(0xFFBBA7FF);
      starPaint
        ..color = color.withValues(
          alpha: .24 + ((math.sin(phase * math.pi * 2 + i) + 1) * .19),
        )
        ..maskFilter =
            i % 7 == 0 ? const MaskFilter.blur(BlurStyle.normal, 2) : null;
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }

    final vignette = Paint()
      ..shader = const RadialGradient(
        radius: .85,
        colors: [Colors.transparent, Color(0xAA050811)],
        stops: [.42, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _SpacePainter oldDelegate) =>
      oldDelegate.phase != phase;
}
