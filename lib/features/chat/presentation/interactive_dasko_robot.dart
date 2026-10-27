import 'package:flutter/material.dart';

enum DaskoRobotState { ready, thinking, happy }

class InteractiveDaskoRobot extends StatelessWidget {
  const InteractiveDaskoRobot({
    super.key,
    required this.state,
    this.size = 84,
  });

  final DaskoRobotState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glow = state == DaskoRobotState.happy
        ? const Color(0xFF7C4DFF)
        : const Color(0xFF00E5FF);
    final faceIcon = switch (state) {
      DaskoRobotState.ready => Icons.sentiment_satisfied_alt_rounded,
      DaskoRobotState.thinking => Icons.psychology_alt_rounded,
      DaskoRobotState.happy => Icons.auto_awesome_rounded,
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF182C46), Color(0xFF0B0F19)],
        ),
        border: Border.all(color: glow, width: 2),
        boxShadow: [
          BoxShadow(color: glow.withValues(alpha: 0.45), blurRadius: 24, spreadRadius: 2),
          const BoxShadow(color: Color(0x337C4DFF), blurRadius: 32),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            faceIcon,
            key: ValueKey(state),
            size: size * 0.52,
            color: glow,
          ),
        ),
      ),
    );
  }
}
