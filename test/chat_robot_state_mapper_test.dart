import 'package:dasko_ai/features/chat/application/chat_request_status.dart';
import 'package:dasko_ai/features/chat/presentation/chat_robot_state_mapper.dart';
import 'package:dasko_ai/features/chat/presentation/dasko_robot_state.dart';
import 'package:dasko_ai/features/chat/presentation/robot_animation_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapChatRequestStatusToRobotState', () {
    test('maps idle, success, and failure to the idle presentation state', () {
      for (final status in [
        ChatRequestStatus.idle,
        ChatRequestStatus.succeeded,
        ChatRequestStatus.failed,
      ]) {
        expect(
          mapChatRequestStatusToRobotState(status),
          DaskoRobotState.ready,
        );
      }
    });

    test('maps an active request to the thinking presentation state', () {
      expect(
        mapChatRequestStatusToRobotState(ChatRequestStatus.sending),
        DaskoRobotState.thinking,
      );
    });
  });

  group('animationNameForRobotState', () {
    test('selects the idle clip when ready', () {
      expect(
        animationNameForRobotState(DaskoRobotState.ready),
        'idle_float',
      );
    });

    test('selects the thinking clip while a request is active', () {
      expect(
        animationNameForRobotState(DaskoRobotState.thinking),
        'thinking_loop',
      );
    });
  });
}
