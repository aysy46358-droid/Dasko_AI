import 'dart:math' as math;

import 'package:flutter/material.dart';

enum DaskoRobotState { ready, thinking, happy }

/// Procedurally drawn holographic robot; no emoji/icon glyph is used as its face.
class InteractiveDaskoRobot extends StatefulWidget {
  const InteractiveDaskoRobot({
    super.key,
    required this.state,
    this.size = 112,
  });

  final DaskoRobotState state;
  final double size;

  @override
  State<InteractiveDaskoRobot> createState() => _InteractiveDaskoRobotState();
}

class _InteractiveDaskoRobotState extends State<InteractiveDaskoRobot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();

  @override
  void didUpdateWidget(covariant InteractiveDaskoRobot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _motion.duration = widget.state == DaskoRobotState.thinking
          ? const Duration(milliseconds: 1700)
          : const Duration(milliseconds: 4200);
      _motion
        ..stop()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, _) => CustomPaint(
          painter: _HolographicRobotPainter(
            phase: _motion.value * math.pi * 2,
            state: widget.state,
          ),
        ),
      ),
    );
  }
}

class _HolographicRobotPainter extends CustomPainter {
  const _HolographicRobotPainter({required this.phase, required this.state});

  final double phase;
  final DaskoRobotState state;

  static const Color cyan = Color(0xFF00E5FF);
  static const Color violet = Color(0xFF7C4DFF);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final unit = size.width / 220;
    final bob = math.sin(phase) * 3.5 * unit;
    final pulse = 0.65 + ((math.sin(phase * 2) + 1) * 0.175);
    canvas.save();
    canvas.translate(0, bob);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          cyan.withValues(alpha: 0.22 * pulse),
          violet.withValues(alpha: 0.12 * pulse),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * .49));
    canvas.drawCircle(center, size.width * .49, glowPaint);

    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy + 7 * unit);
      canvas.rotate(phase * (i.isEven ? 0.35 : -0.27) + i * 0.9);
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (i == 1 ? 1.7 : 1.0) * unit
        ..color = (i.isEven ? cyan : violet).withValues(alpha: 0.48 * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.4 * unit);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * (0.90 - i * 0.08),
          height: size.height * (0.25 + i * 0.025),
        ),
        ringPaint,
      );
      canvas.restore();
    }

    _drawBody(canvas, size, unit, pulse);
    _drawHead(canvas, size, unit, pulse);
    _drawScanLines(canvas, size, unit, pulse);
    canvas.restore();
  }

  void _drawHead(Canvas canvas, Size size, double unit, double pulse) {
    final c = Offset(size.width / 2, size.height * 0.36);
    final headRect = Rect.fromCenter(
      center: c,
      width: size.width * 0.55,
      height: size.height * 0.43,
    );
    final head = RRect.fromRectAndRadius(headRect, Radius.circular(25 * unit));

    final glow = Paint()
      ..color = cyan.withValues(alpha: 0.26 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * unit
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * unit);
    canvas.drawRRect(head, glow);

    final shell = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF294A68), Color(0xFF101A2A), Color(0xFF17112D)],
      ).createShader(headRect);
    canvas.drawRRect(head, shell);
    canvas.drawRRect(
      head,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 * unit
        ..shader = SweepGradient(
          transform: GradientRotation(phase),
          colors: const [cyan, violet, Color(0xFFB8F7FF), cyan],
        ).createShader(headRect),
    );

    final sidePaint = Paint()..color = const Color(0xFF1C3653);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          headRect.left - 7 * unit,
          c.dy - 11 * unit,
          12 * unit,
          24 * unit,
        ),
        Radius.circular(5 * unit),
      ),
      sidePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          headRect.right - 5 * unit,
          c.dy - 11 * unit,
          12 * unit,
          24 * unit,
        ),
        Radius.circular(5 * unit),
      ),
      sidePaint,
    );
    final led = Paint()
      ..color = cyan
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * unit);
    canvas.drawCircle(Offset(headRect.left - 1 * unit, c.dy), 2.5 * unit, led);
    canvas.drawCircle(Offset(headRect.right + 1 * unit, c.dy), 2.5 * unit, led);

    final visorRect = Rect.fromCenter(
      center: Offset(c.dx, c.dy + 1 * unit),
      width: headRect.width * 0.77,
      height: headRect.height * 0.48,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(visorRect, Radius.circular(13 * unit)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF071522), Color(0xFF101B32)],
        ).createShader(visorRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(visorRect, Radius.circular(13 * unit)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9 * unit
        ..color = cyan.withValues(alpha: 0.75),
    );

    final eyeY = visorRect.center.dy -
        (state == DaskoRobotState.thinking ? 1 : 0) * unit;
    final eyeRadius = (state == DaskoRobotState.thinking ? 2.4 : 3.4) * unit;
    final eyePaint = Paint()
      ..color = state == DaskoRobotState.happy ? const Color(0xFFB9A2FF) : cyan
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * unit);
    canvas.drawCircle(
      Offset(visorRect.left + visorRect.width * 0.27, eyeY),
      eyeRadius * pulse,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(visorRect.right - visorRect.width * 0.27, eyeY),
      eyeRadius * pulse,
      eyePaint,
    );

    final mouth = Path();
    final mouthCenter = Offset(c.dx, visorRect.bottom - 7 * unit);
    if (state == DaskoRobotState.happy) {
      mouth.moveTo(mouthCenter.dx - 7 * unit, mouthCenter.dy - 1 * unit);
      mouth.quadraticBezierTo(
        mouthCenter.dx,
        mouthCenter.dy + 5 * unit,
        mouthCenter.dx + 7 * unit,
        mouthCenter.dy - 1 * unit,
      );
    } else if (state == DaskoRobotState.thinking) {
      mouth.moveTo(mouthCenter.dx - 6 * unit, mouthCenter.dy);
      mouth.lineTo(mouthCenter.dx + 6 * unit, mouthCenter.dy);
      mouth.moveTo(mouthCenter.dx, mouthCenter.dy - 3 * unit);
      mouth.lineTo(mouthCenter.dx, mouthCenter.dy + 3 * unit);
    } else {
      mouth.moveTo(mouthCenter.dx - 5 * unit, mouthCenter.dy);
      mouth.lineTo(mouthCenter.dx + 5 * unit, mouthCenter.dy);
    }
    canvas.drawPath(
      mouth,
      Paint()
        ..color = violet
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.8 * unit,
    );

    final antenna = Paint()
      ..color = cyan.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7 * unit;
    canvas.drawLine(
      Offset(c.dx, headRect.top),
      Offset(c.dx, headRect.top - 13 * unit),
      antenna,
    );
    canvas.drawCircle(
      Offset(c.dx, headRect.top - 16 * unit),
      (2.5 + math.sin(phase * 2) * 0.7) * unit,
      Paint()
        ..color = cyan
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * unit),
    );
  }

  void _drawBody(Canvas canvas, Size size, double unit, double pulse) {
    final bodyRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.70),
      width: size.width * 0.43,
      height: size.height * 0.24,
    );
    final body = RRect.fromRectAndRadius(bodyRect, Radius.circular(18 * unit));
    canvas.drawRRect(
      body,
      Paint()
        ..color = cyan.withValues(alpha: 0.16 * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * unit),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF203B5B), Color(0xFF0C1423)],
        ).createShader(bodyRect),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3 * unit
        ..color = violet.withValues(alpha: 0.9),
    );

    final coreRect = Rect.fromCenter(
      center: Offset(bodyRect.center.dx, bodyRect.center.dy - 1 * unit),
      width: bodyRect.width * 0.26,
      height: bodyRect.height * 0.36,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(coreRect, Radius.circular(5 * unit)),
      Paint()
        ..color = cyan.withValues(alpha: 0.65)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * unit),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(coreRect, Radius.circular(5 * unit)),
      Paint()..color = const Color(0xFFB5FBFF),
    );

    final armPaint = Paint()
      ..color = cyan.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5 * unit;
    canvas.drawLine(
      Offset(bodyRect.left + 2 * unit, bodyRect.top + 7 * unit),
      Offset(bodyRect.left - 8 * unit, bodyRect.bottom - 2 * unit),
      armPaint,
    );
    canvas.drawLine(
      Offset(bodyRect.right - 2 * unit, bodyRect.top + 7 * unit),
      Offset(bodyRect.right + 8 * unit, bodyRect.bottom - 2 * unit),
      armPaint,
    );
  }

  void _drawScanLines(Canvas canvas, Size size, double unit, double pulse) {
    final linePaint = Paint()
      ..color = cyan.withValues(alpha: 0.13 * pulse)
      ..strokeWidth = 0.65 * unit;
    final offset = (phase * 10 * unit) % (size.height * 0.75);
    for (var i = 0; i < 7; i++) {
      final y =
          size.height * 0.12 + ((i * 18 * unit + offset) % (size.height * .76));
      canvas.drawLine(
        Offset(size.width * .22, y),
        Offset(size.width * .78, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HolographicRobotPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.state != state;
}
