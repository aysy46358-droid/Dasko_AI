import 'dart:math' as math;

import 'package:flutter/material.dart';

enum DaskoRobotState { ready, thinking, happy }

/// Layered 2.5D Dasko mascot. The public API stays stable for existing screens.
class InteractiveDaskoRobot extends StatefulWidget {
  const InteractiveDaskoRobot({
    super.key,
    required this.state,
    this.size = 112,
  }) : assert(size > 0);

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
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _motion,
          builder: (context, _) => CustomPaint(
            painter: _DaskoRobotPainter(
              phase: _motion.value * math.pi * 2,
              state: widget.state,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the mascot in explicit back-to-front layers so each part can evolve
/// independently without changing the screens that host [InteractiveDaskoRobot].
class _DaskoRobotPainter extends CustomPainter {
  const _DaskoRobotPainter({required this.phase, required this.state});

  final double phase;
  final DaskoRobotState state;

  static const _RobotColors colors = _RobotColors();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    const designSize = 220.0;
    final scale = math.min(size.width, size.height) / (designSize + 12);
    final offsetX = (size.width - designSize * scale) / 2;
    final offsetY = (size.height - designSize * scale) / 2;
    final pulse = 0.78 + (math.sin(phase * 2) + 1) * 0.11;
    final bob = math.sin(phase) * 2.2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    _drawGroundGlow(canvas, pulse);
    canvas.save();
    canvas.translate(0, bob);
    _drawAmbientAura(canvas, pulse);
    _drawAntennae(canvas, pulse);
    _drawEarPods(canvas, pulse);
    _drawArms(canvas, pulse);
    _drawTorso(canvas, pulse);
    _drawHelmet(canvas, pulse);
    _drawFace(canvas, pulse);
    _drawHighlights(canvas, pulse);
    canvas.restore();
    canvas.restore();
  }

  void _drawGroundGlow(Canvas canvas, double pulse) {
    final shadow = Paint()
      ..color = colors.deepBlue.withValues(alpha: 0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(110, 210), width: 104, height: 13),
      shadow,
    );
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          colors.cyan.withValues(alpha: 0.18 * pulse),
          colors.violet.withValues(alpha: 0.09 * pulse),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCenter(center: const Offset(110, 202), width: 136, height: 28),
      );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(110, 202), width: 136, height: 28),
      glow,
    );
  }

  void _drawAmbientAura(Canvas canvas, double pulse) {
    final aura = Paint()
      ..shader = RadialGradient(
        colors: [
          colors.cyan.withValues(alpha: 0.12 * pulse),
          colors.violet.withValues(alpha: 0.09 * pulse),
          Colors.transparent,
        ],
        stops: const [0, 0.58, 1],
      ).createShader(
        Rect.fromCircle(center: const Offset(110, 111), radius: 101),
      );
    canvas.drawCircle(const Offset(110, 111), 101, aura);

    final orbitalGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = colors.cyan.withValues(alpha: 0.20 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(110, 111),
        width: 196,
        height: 67,
      ),
      orbitalGlow,
    );
  }

  void _drawAntennae(Canvas canvas, double pulse) {
    for (final x in [53.0, 167.0]) {
      final stem = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.cyan, colors.violet.withValues(alpha: 0.82)],
        ).createShader(Rect.fromLTRB(x - 2, 8, x + 2, 39));
      canvas.drawLine(Offset(x, 13), Offset(x, 36), stem);

      final bulbGlow = Paint()
        ..color = colors.cyan.withValues(alpha: 0.48 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      canvas.drawCircle(Offset(x, 13), 8, bulbGlow);
      final bulb = Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          colors: [Color(0xFFFFFFFF), Color(0xFF75F8FF), Color(0xFF078CBF)],
        ).createShader(Rect.fromCircle(center: Offset(x, 13), radius: 7));
      canvas.drawCircle(Offset(x, 13), 6.5, bulb);
      canvas.drawCircle(
        Offset(x - 2, 10.5),
        1.5,
        Paint()..color = Colors.white.withValues(alpha: 0.92),
      );
    }
  }

  void _drawEarPods(Canvas canvas, double pulse) {
    _drawEarPod(
      canvas,
      const Rect.fromLTRB(24, 65, 51, 111),
      rightSide: false,
      pulse: pulse,
    );
    _drawEarPod(
      canvas,
      const Rect.fromLTRB(169, 65, 196, 111),
      rightSide: true,
      pulse: pulse,
    );
  }

  void _drawEarPod(
    Canvas canvas,
    Rect rect, {
    required bool rightSide,
    required double pulse,
  }) {
    final pod = RRect.fromRectAndRadius(rect, const Radius.circular(13));
    canvas.drawRRect(
      pod.shift(const Offset(0, 3)),
      Paint()
        ..color = colors.deepBlue.withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRRect(
      pod,
      Paint()
        ..shader = LinearGradient(
          begin: rightSide ? Alignment.centerRight : Alignment.centerLeft,
          end: rightSide ? Alignment.centerLeft : Alignment.centerRight,
          colors: [colors.cyan, colors.shellBlue, colors.violet],
        ).createShader(rect),
    );
    canvas.drawRRect(
      pod,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = colors.ice.withValues(alpha: 0.78),
    );

    final innerRect = rightSide
        ? Rect.fromLTRB(
            rect.left + 6, rect.top + 7, rect.right - 4, rect.bottom - 7)
        : Rect.fromLTRB(
            rect.left + 4, rect.top + 7, rect.right - 6, rect.bottom - 7);
    final innerPod = RRect.fromRectAndRadius(
      innerRect,
      const Radius.circular(9),
    );
    canvas.drawRRect(
      innerPod,
      Paint()
        ..color = colors.deepBlue.withValues(alpha: 0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final lightX = rightSide ? rect.right - 4 : rect.left + 4;
    canvas.drawLine(
      Offset(lightX, rect.top + 12),
      Offset(lightX, rect.bottom - 12),
      Paint()
        ..color = colors.cyan.withValues(alpha: 0.7 * pulse)
        ..strokeWidth = 1.3,
    );
  }

  void _drawArms(Canvas canvas, double pulse) {
    final leftArm = Path()
      ..moveTo(73, 154)
      ..cubicTo(56, 154, 49, 169, 43, 186)
      ..lineTo(40, 195);
    _drawArmPath(
      canvas,
      leftArm,
      const Rect.fromLTRB(36, 150, 78, 201),
      pulse,
    );
    final rightArm = Path()
      ..moveTo(148, 153)
      ..cubicTo(166, 151, 177, 137, 185, 119)
      ..lineTo(192, 108);
    _drawArmPath(
      canvas,
      rightArm,
      const Rect.fromLTRB(145, 103, 197, 158),
      pulse,
    );

    _drawHand(canvas, const Offset(40, 196), leftSide: true, pulse: pulse);
    _drawHand(canvas, const Offset(194, 105), leftSide: false, pulse: pulse);
  }

  void _drawArmPath(Canvas canvas, Path path, Rect bounds, double pulse) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = colors.deepBlue.withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.cyan.withValues(alpha: 0.95),
            colors.shellBlue,
            colors.violet.withValues(alpha: 0.94),
          ],
        ).createShader(bounds),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = colors.ice.withValues(alpha: 0.55 * pulse),
    );
  }

  void _drawHand(
    Canvas canvas,
    Offset center, {
    required bool leftSide,
    required double pulse,
  }) {
    final handRect = Rect.fromCenter(
      center: center,
      width: 22,
      height: 18,
    );
    final hand = RRect.fromRectAndRadius(handRect, const Radius.circular(8));
    canvas.drawRRect(
      hand,
      Paint()
        ..shader = LinearGradient(
          colors: leftSide
              ? [colors.cyan, colors.shellBlue]
              : [colors.shellBlue, colors.violet],
        ).createShader(handRect),
    );
    canvas.drawRRect(
      hand,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = colors.ice.withValues(alpha: 0.75 * pulse),
    );
    canvas.drawCircle(
      center,
      3,
      Paint()
        ..color = colors.ice.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _drawTorso(Canvas canvas, double pulse) {
    final neck = RRect.fromRectAndRadius(
      const Rect.fromLTRB(91, 125, 129, 151),
      const Radius.circular(11),
    );
    canvas.drawRRect(
      neck,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF1C93B7), Color(0xFF504E9D), Color(0xFF302653)],
        ).createShader(const Rect.fromLTRB(91, 125, 129, 151)),
    );

    const bodyRect = Rect.fromLTRB(57, 137, 163, 211);
    final body = RRect.fromRectAndRadius(bodyRect, const Radius.circular(31));
    canvas.drawRRect(
      body.shift(const Offset(0, 4)),
      Paint()
        ..color = colors.deepBlue.withValues(alpha: 0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6AF4F7),
            Color(0xFF33CFE1),
            Color(0xFF778BE6),
            Color(0xFFB56BFF),
          ],
          stops: [0, 0.34, 0.70, 1],
        ).createShader(bodyRect),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = colors.ice.withValues(alpha: 0.84),
    );

    final frontPanel = RRect.fromRectAndRadius(
      const Rect.fromLTRB(77, 159, 143, 197),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      frontPanel.shift(const Offset(0, 2)),
      Paint()..color = colors.deepBlue.withValues(alpha: 0.42),
    );
    canvas.drawRRect(
      frontPanel,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF07192D), Color(0xFF0B1732)],
        ).createShader(const Rect.fromLTRB(77, 159, 143, 197)),
    );
    canvas.drawRRect(
      frontPanel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..shader = const LinearGradient(
          colors: [Color(0xFFB5FFFF), Color(0xFF00E5FF), Color(0xFFC28BFF)],
        ).createShader(const Rect.fromLTRB(77, 159, 143, 197)),
    );

    final coreGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = colors.cyan.withValues(alpha: 0.47 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final infinity = _infinityPath(const Offset(110, 178), 22, 9);
    canvas.drawPath(infinity, coreGlow);
    canvas.drawPath(
      infinity,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = const LinearGradient(
          colors: [Color(0xFF00F4F1), Color(0xFF67F7FF), Color(0xFFB96DFF)],
        ).createShader(const Rect.fromLTRB(88, 168, 132, 187)),
    );

    final bodyGlint = Path()
      ..moveTo(74, 146)
      ..quadraticBezierTo(87, 141, 100, 146);
    canvas.drawPath(
      bodyGlint,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.42 * pulse),
    );
  }

  Path _infinityPath(Offset center, double width, double height) {
    final left = center.dx - width;
    final right = center.dx + width;
    final top = center.dy - height;
    final bottom = center.dy + height;
    return Path()
      ..moveTo(center.dx, center.dy)
      ..cubicTo(left + 2, top - 2, left - 1, top + 1, left, center.dy)
      ..cubicTo(
          left + 1, bottom - 1, left + 8, bottom + 1, center.dx, center.dy)
      ..cubicTo(right - 8, top - 1, right - 1, top + 1, right, center.dy)
      ..cubicTo(
          right + 1, bottom - 1, right - 8, bottom + 1, center.dx, center.dy);
  }

  void _drawHelmet(Canvas canvas, double pulse) {
    const shellRect = Rect.fromLTRB(32, 28, 188, 143);
    final shell = RRect.fromRectAndRadius(shellRect, const Radius.circular(47));
    canvas.drawRRect(
      shell.shift(const Offset(0, 5)),
      Paint()
        ..color = colors.deepBlue.withValues(alpha: 0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRRect(
      shell,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF03D7E4),
            Color(0xFF73EAF0),
            Color(0xFFC1CFFF),
            Color(0xFFB876F3),
            Color(0xFF5AADEB),
          ],
          stops: [0, 0.26, 0.52, 0.78, 1],
        ).createShader(shellRect),
    );
    canvas.drawRRect(
      shell,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = colors.ice.withValues(alpha: 0.91),
    );

    const innerShellRect = Rect.fromLTRB(39, 35, 181, 136);
    final innerShell = RRect.fromRectAndRadius(
      innerShellRect,
      const Radius.circular(40),
    );
    canvas.drawRRect(
      innerShell,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF70E7EC), Color(0xFF56CBE0), Color(0xFF9377E2)],
        ).createShader(innerShellRect),
    );

    const visorRect = Rect.fromLTRB(47, 50, 173, 126);
    final visor = RRect.fromRectAndRadius(visorRect, const Radius.circular(29));
    canvas.drawRRect(
      visor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF020A1B), Color(0xFF07152B), Color(0xFF020817)],
        ).createShader(visorRect),
    );
    canvas.drawRRect(
      visor,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = colors.deepBlue.withValues(alpha: 0.88),
    );
    canvas.drawRRect(
      visor,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = colors.cyan.withValues(alpha: 0.57 * pulse),
    );
  }

  void _drawFace(Canvas canvas, double pulse) {
    const visorRect = Rect.fromLTRB(47, 50, 173, 126);
    final visor = RRect.fromRectAndRadius(visorRect, const Radius.circular(29));
    canvas.save();
    canvas.clipRRect(visor);

    final topReflection = Paint()
      ..shader = LinearGradient(
        colors: [
          colors.cyan.withValues(alpha: 0.08 * pulse),
          Colors.transparent,
        ],
      ).createShader(const Rect.fromLTRB(57, 53, 163, 75));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(54, 51, 166, 76),
        const Radius.circular(25),
      ),
      topReflection,
    );

    final scanline = Paint()
      ..color = colors.cyan.withValues(alpha: 0.09 * pulse)
      ..strokeWidth = 0.7;
    for (var i = 0; i < 5; i++) {
      final y = 54 + ((phase * 3.2 + i * 16) % 70);
      canvas.drawLine(
          const Offset(52, 0).translate(0, y), Offset(168, y), scanline);
    }

    final eyeY = 82.0 + (state == DaskoRobotState.thinking ? 2 : 0);
    if (state == DaskoRobotState.thinking) {
      for (final x in [88.0, 110.0, 132.0]) {
        canvas.drawCircle(
          Offset(x, eyeY),
          3.1 + math.sin(phase * 2 + x) * 0.5,
          Paint()
            ..color = colors.cyan
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    } else {
      _drawEye(canvas, const Offset(81, 82), pulse);
      _drawEye(canvas, const Offset(139, 82), pulse);
    }

    final mouth = Path();
    final mouthY = state == DaskoRobotState.happy ? 102.0 : 103.0;
    if (state == DaskoRobotState.happy) {
      mouth
        ..moveTo(101, mouthY - 1)
        ..quadraticBezierTo(110, mouthY + 7, 119, mouthY - 1);
    } else {
      mouth
        ..moveTo(105, mouthY)
        ..lineTo(115, mouthY);
    }
    canvas.drawPath(
      mouth,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = colors.ice.withValues(alpha: 0.93),
    );

    final glintX = 51 + ((phase * 10) % 118);
    final glint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          colors.cyan.withValues(alpha: 0.20 * pulse),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTRB(glintX - 9, 50, glintX + 9, 126));
    canvas.drawRect(Rect.fromLTRB(glintX - 9, 50, glintX + 9, 126), glint);
    canvas.restore();
  }

  void _drawEye(Canvas canvas, Offset center, double pulse) {
    final glow = Path()
      ..moveTo(center.dx - 11, center.dy + 4)
      ..quadraticBezierTo(
          center.dx, center.dy - 11, center.dx + 11, center.dy + 4);
    canvas.drawPath(
      glow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = colors.cyan.withValues(alpha: 0.56 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      glow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.6
        ..strokeCap = StrokeCap.round
        ..color = colors.cyan,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy - 1),
      1.6,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  void _drawHighlights(Canvas canvas, double pulse) {
    final topGlint = Path()
      ..moveTo(62, 39)
      ..cubicTo(78, 31, 121, 31, 143, 38);
    canvas.drawPath(
      topGlint,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.46 * pulse),
    );

    final leftGlint = Path()
      ..moveTo(43, 74)
      ..cubicTo(40, 89, 42, 112, 51, 124);
    canvas.drawPath(
      leftGlint,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round
        ..color = colors.ice.withValues(alpha: 0.54 * pulse),
    );

    final rightGlint = Paint()
      ..color = colors.violet.withValues(alpha: 0.25 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(176, 86), width: 5, height: 36),
      rightGlint,
    );
  }

  @override
  bool shouldRepaint(covariant _DaskoRobotPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.state != state;
}

class _RobotColors {
  const _RobotColors();

  final Color cyan = const Color(0xFF00E5FF);
  final Color violet = const Color(0xFF9B72F2);
  final Color shellBlue = const Color(0xFF42BFE0);
  final Color ice = const Color(0xFFE0FBFC);
  final Color deepBlue = const Color(0xFF061226);
}
