import 'dasko_robot_state.dart';

/// Returns the local GLB animation clip for a presentation-only robot state.
String animationNameForRobotState(DaskoRobotState state) {
  return switch (state) {
    DaskoRobotState.ready => 'idle_float',
    DaskoRobotState.thinking => 'thinking_loop',
  };
}
