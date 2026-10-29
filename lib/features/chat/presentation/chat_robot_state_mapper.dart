import '../application/chat_request_status.dart';
import 'dasko_robot_state.dart';

/// Maps functional chat-request status to the mascot's presentation state.
DaskoRobotState mapChatRequestStatusToRobotState(ChatRequestStatus status) {
  switch (status) {
    case ChatRequestStatus.idle:
    case ChatRequestStatus.failed:
      return DaskoRobotState.ready;
    case ChatRequestStatus.sending:
      return DaskoRobotState.thinking;
    case ChatRequestStatus.succeeded:
      return DaskoRobotState.happy;
  }
}
