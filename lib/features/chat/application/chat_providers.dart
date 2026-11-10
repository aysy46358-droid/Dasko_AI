import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/repositories/ai_engine.dart';
import '../../../domain/usecases/send_message.dart';
import 'chat_notifier.dart';

/// Dependency boundary for the chat feature.
///
/// The application composition root must override this provider with an
/// implementation such as `MockAiEngine`; the feature never imports services.
final aiEngineProvider = Provider<AiEngine>((ref) {
  throw StateError('AiEngine must be provided by the application composition root.');
});

final sendMessageProvider = Provider<SendMessage>((ref) {
  return SendMessage(ref.watch(aiEngineProvider));
});

final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.watch(sendMessageProvider));
});
