import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/message.dart';
import '../../../domain/usecases/send_message.dart';
import 'chat_request_status.dart';

class ChatState {
  ChatState({
    List<Message> messages = const [],
    this.requestStatus = ChatRequestStatus.idle,
    this.errorMessage,
  }) : messages = UnmodifiableListView<Message>(messages);

  /// Read-only view: callers cannot mutate the notifier's list in place.
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
      super(ChatState());

  final SendMessage _sendMessage;
  final Uuid _uuid;

  /// [errorText] is supplied by the presentation layer so this notifier stays
  /// free of user-facing copy; it is shown if the engine call fails.
  Future<void> send(String rawText, {required String errorText}) async {
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
      (_) {
        state = state.copyWith(
          messages: [
            ...state.messages,
            Message(
              id: _uuid.v4(),
              text: errorText,
              isUser: false,
              createdAt: DateTime.now(),
            ),
          ],
          requestStatus: ChatRequestStatus.failed,
          errorMessage: errorText,
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
