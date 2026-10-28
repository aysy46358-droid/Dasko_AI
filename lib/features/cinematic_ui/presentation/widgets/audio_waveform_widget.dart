import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Decorative audio waveform for the cinematic presentation.
///
/// The bars are a visual treatment only; playback state and audio processing
/// belong in the feature's application/domain layers.
class AudioWaveformWidget extends StatelessWidget {
  const AudioWaveformWidget({
    super.key,
    this.barCount = 31,
    this.height = 32,
    this.color = const Color(0xFF35F4F4),
    this.secondaryColor = const Color(0xFFB56BFF),
  }) : assert(barCount > 0);

  final int barCount;
  final double height;
  final Color color;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WaveformPainter(
          barCount: barCount,
          primaryColor: color,
          secondaryColor: secondaryColor,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.barCount,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final int barCount;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final gap = size.width / (barCount * 1.8);
    final barWidth = math.max(1.2, gap * 0.58).toDouble();
    final usableGap =
        (size.width - barWidth * barCount) / (barCount - 1).clamp(1, barCount);
    final centerY = size.height / 2;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    for (var i = 0; i < barCount; i++) {
      final normalized = (i / (barCount - 1).clamp(1, barCount)) * 2 - 1;
      final envelope = 0.25 + 0.75 * (1 - normalized.abs());
      final rhythm = (math.sin(i * 1.37) + math.cos(i * 0.63)).abs() / 2;
      final barHeight = math
          .max(3.0, size.height * envelope * (0.22 + rhythm * 0.65))
          .toDouble();
      final x = barWidth / 2 + i * (barWidth + usableGap);
      final blend = i / (barCount - 1).clamp(1, barCount);
      paint.color = Color.lerp(primaryColor, secondaryColor, blend)!;
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
      paint.maskFilter = null;
      paint.color = Color.lerp(
        primaryColor,
        secondaryColor,
        blend,
      )!
          .withValues(alpha: 0.8);
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.barCount != barCount ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.secondaryColor != secondaryColor;
}
