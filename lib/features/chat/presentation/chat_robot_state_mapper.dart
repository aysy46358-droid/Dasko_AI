import '../application/chat_request_status.dart';
import 'dasko_robot_state.dart';

/// Maps application request status to a presentation-only robot state.
DaskoRobotState mapChatRequestStatusToRobotState(ChatRequestStatus status) {
  switch (status) {
    case ChatRequestStatus.sending:
      return DaskoRobotState.thinking;
    case ChatRequestStatus.idle:
    case ChatRequestStatus.succeeded:
    case ChatRequestStatus.failed:
      return DaskoRobotState.ready;
  }
}
