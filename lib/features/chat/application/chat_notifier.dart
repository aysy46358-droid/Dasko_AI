import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/message.dart';
import '../../../domain/usecases/send_message.dart';
import '../../../services/ai_engine/ai_providers.dart';
import 'chat_request_status.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.requestStatus = ChatRequestStatus.idle,
    this.errorMessage,
  });

  final List<Message> messages;
  final ChatRequestStatus requestStatus;
  final String? errorMessage;

  bool get isReplying => requestStatus == ChatRequestStatus.sending;

  ChatState copyWith({
    List<Message>? messages,
    ChatRequestStatus? requestStatus,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      requestStatus: requestStatus ?? this.requestStatus,
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
      requestStatus: ChatRequestStatus.sending,
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
          requestStatus: ChatRequestStatus.failed,
          errorMessage: failure.message,
        );
      },
      (assistantMessage) {
        state = state.copyWith(
          messages: [...state.messages, assistantMessage],
          requestStatus: ChatRequestStatus.succeeded,
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
