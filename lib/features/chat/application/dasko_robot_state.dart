/// Visual readiness of the Dasko mascot during chat and intro flows.
///
/// Lives in the application layer so presentation widgets and application
/// state can share the same type without application importing presentation.
enum DaskoRobotState {
  ready,
  thinking,
  happy,
}
