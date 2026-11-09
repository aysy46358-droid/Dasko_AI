import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../l10n/app_localizations.dart';
import 'dasko_robot_state.dart';

export 'dasko_robot_state.dart';

const _pulseDuration = Duration(milliseconds: 1400);

/// Renders the robot artwork and pulses a cyan glow while Dasko is thinking.
///
/// The poster image is the single source of truth for the robot, so there is
/// no platform view, no bridge and no load-time camera jump to coordinate.
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
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: _pulseDuration,
  );

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant InteractiveDaskoRobot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) _syncPulse();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// Only the thinking state animates; every other state shows a steady glow.
  void _syncPulse() {
    if (widget.state == DaskoRobotState.thinking) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = Theme.of(context).colorScheme.primary;

    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final pulse = _pulse.value;
            final isThinking = widget.state == DaskoRobotState.thinking;

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.size * 0.28),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(
                      alpha: 0.28 + (isThinking ? pulse * 0.45 : 0),
                    ),
                    blurRadius: 25,
                    spreadRadius: isThinking ? pulse * 2.5 : 0.5,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => const RadialGradient(
              colors: [Colors.white, Colors.transparent],
              stops: [0.5, 1.0],
            ).createShader(bounds),
            child: Image.asset(
              AppAssets.robotPoster,
              fit: BoxFit.contain,
              semanticLabel: AppLocalizations.of(context)!.robotAlt,
            ),
          ),
        ),
      ),
    );
  }
}
