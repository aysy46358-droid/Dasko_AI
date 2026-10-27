import 'package:flutter/material.dart';

/// Animated cyan/violet border with a rotating sweep and restrained glow.
class AnimatedNeonBorder extends StatefulWidget {
  const AnimatedNeonBorder({
    super.key,
    required this.child,
    this.borderRadius = 18,
    this.borderWidth = 1.35,
    this.backgroundColor = const Color(0xFF111827),
    this.duration = const Duration(milliseconds: 3600),
  });

  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final Color backgroundColor;
  final Duration duration;

  @override
  State<AnimatedNeonBorder> createState() => _AnimatedNeonBorderState();
}

class _AnimatedNeonBorderState extends State<AnimatedNeonBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sweep,
      builder: (context, _) {
        final glow = .16 + (_sweep.value * .16);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: glow),
                blurRadius: 17,
                spreadRadius: .5,
              ),
              BoxShadow(
                color: const Color(0xFF7C4DFF).withValues(alpha: glow * .82),
                blurRadius: 22,
                spreadRadius: .5,
              ),
            ],
            gradient: SweepGradient(
              transform: GradientRotation(_sweep.value * 6.283185307179586),
              colors: const [
                Color(0xFF00E5FF),
                Color(0xFF315BFF),
                Color(0xFF7C4DFF),
                Color(0xFFE0B7FF),
                Color(0xFF00E5FF),
              ],
              stops: const [0, .26, .52, .77, 1],
            ),
          ),
          padding: EdgeInsets.all(widget.borderWidth),
          child: Container(
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(
                (widget.borderRadius - widget.borderWidth).clamp(0, 100),
              ),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
