import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/message.dart';
import '../../../domain/usecases/send_message.dart';
import '../../../services/ai_engine/ai_providers.dart';
import 'dasko_robot_state.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isReplying = false,
    this.robotState = DaskoRobotState.ready,
    this.errorMessage,
  });

  final List<Message> messages;
  final bool isReplying;
  final DaskoRobotState robotState;
  final String? errorMessage;

  ChatState copyWith({
    List<Message>? messages,
    bool? isReplying,
    DaskoRobotState? robotState,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isReplying: isReplying ?? this.isReplying,
      robotState: robotState ?? this.robotState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._sendMessage, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid(),
        super(const ChatState());

  final SendMessage _sendMessage;
  final Uuid _uuid;

  Future<void> send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isReplying) return;

    final userMessage = Message(
      id: _uuid.v4(),
      text: text,
      isUser: true,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isReplying: true,
      robotState: DaskoRobotState.thinking,
      clearError: true,
    );

    final result = await _sendMessage(prompt: text);

    result.fold(
      (failure) {
        state = state.copyWith(
          messages: [
            ...state.messages,
            Message(
              id: _uuid.v4(),
              text: 'حدث خطأ: ${failure.message}',
              isUser: false,
              createdAt: DateTime.now(),
            ),
          ],
          isReplying: false,
          robotState: DaskoRobotState.happy,
          errorMessage: failure.message,
        );
      },
      (assistantMessage) {
        state = state.copyWith(
          messages: [...state.messages, assistantMessage],
          isReplying: false,
          robotState: DaskoRobotState.happy,
          clearError: true,
        );
      },
    );
  }
}

final sendMessageProvider = Provider<SendMessage>((ref) {
  return SendMessage(ref.watch(aiEngineProvider));
});

final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.watch(sendMessageProvider));
});
