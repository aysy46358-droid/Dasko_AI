/// Functional lifecycle of a chat request, independent of its visual treatment.
enum ChatRequestStatus {
  idle,
  sending,
  succeeded,
  failed,
}
