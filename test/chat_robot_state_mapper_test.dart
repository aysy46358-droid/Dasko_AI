import 'package:dasko_ai/features/chat/application/chat_request_status.dart';
import 'package:dasko_ai/features/chat/presentation/chat_robot_state_mapper.dart';
import 'package:dasko_ai/features/chat/presentation/dasko_robot_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapChatRequestStatusToRobotState', () {
    test('maps idle and failed requests to a neutral ready expression', () {
      expect(
        mapChatRequestStatusToRobotState(ChatRequestStatus.idle),
        DaskoRobotState.ready,
      );
      expect(
        mapChatRequestStatusToRobotState(ChatRequestStatus.failed),
        DaskoRobotState.ready,
      );
    });

    test('maps an active request to thinking', () {
      expect(
        mapChatRequestStatusToRobotState(ChatRequestStatus.sending),
        DaskoRobotState.thinking,
      );
    });

    test('maps a successful request to happy', () {
      expect(
        mapChatRequestStatusToRobotState(ChatRequestStatus.succeeded),
        DaskoRobotState.happy,
      );
    });
  });
}
