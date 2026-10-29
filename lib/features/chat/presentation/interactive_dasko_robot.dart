import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dasko_robot_state.dart';

export 'dasko_robot_state.dart';

/// Layered 2.5D Dasko mascot. Public API unchanged for screens and tests.
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

class _DaskoRobotPainter extends CustomPainter {
  const _DaskoRobotPainter({required this.phase, required this.state});

  final double phase;
  final DaskoRobotState state;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;
    final pulse = 0.78 + (math.sin(phase * 2) + 1) * 0.11;
    final bob = math.sin(phase) * 2.2;

    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF6AF4F7),
          Color(0xFF00E5FF),
          Color(0xFF7C4DFF),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.save();
    canvas.translate(0, bob);
    canvas.drawCircle(center, radius, bodyPaint);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFFE0FBFC).withValues(alpha: 0.85 * pulse);
    canvas.drawCircle(center, radius * 0.92, ring);

    final eyeOffset = state == DaskoRobotState.thinking ? 2.0 : 0.0;
    final eyeY = center.dy - radius * 0.12 + eyeOffset;
    final eyePaint = Paint()..color = const Color(0xFF061226);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.22, eyeY),
      radius * 0.08,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.22, eyeY),
      radius * 0.08,
      eyePaint,
    );

    final mouthPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF061226);

    final mouthY = center.dy + radius * 0.22;
    final path = Path();
    if (state == DaskoRobotState.happy) {
      path.moveTo(center.dx - radius * 0.2, mouthY);
      path.quadraticBezierTo(
        center.dx,
        mouthY + radius * 0.14,
        center.dx + radius * 0.2,
        mouthY,
      );
    } else {
      path.moveTo(center.dx - radius * 0.16, mouthY);
      path.lineTo(center.dx + radius * 0.16, mouthY);
    }
    canvas.drawPath(path, mouthPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DaskoRobotPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.state != state;
}
