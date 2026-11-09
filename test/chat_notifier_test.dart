import 'dart:async';
import 'package:dartz/dartz.dart';

import 'package:dasko_ai/core/errors/failures.dart';
import 'package:dasko_ai/domain/repositories/ai_engine.dart';
import 'package:dasko_ai/domain/usecases/send_message.dart';
import 'package:dasko_ai/features/chat/application/chat_notifier.dart';
import 'package:dasko_ai/features/chat/application/chat_request_status.dart';
import 'package:flutter_test/flutter_test.dart';

// Stand-in for the localized failure copy the UI injects at send time.
const _errorText = 'Could not complete your request.';

class _CompleterEngine implements AiEngine {
  final Completer<Either<Failure, String>> completer =
      Completer<Either<Failure, String>>();

  @override
  Future<Either<Failure, String>> generateResponse({
    required String prompt,
    String? systemInstruction,
    List<Map<String, String>>? history,
  }) {
    return completer.future;
  }
}

void main() {
  group('ChatNotifier request status', () {
    test('transitions from idle through sending to succeeded', () async {
      final engine = _CompleterEngine();
      final notifier = ChatNotifier(SendMessage(engine));

      expect(notifier.state.requestStatus, ChatRequestStatus.idle);
      expect(notifier.state.isReplying, isFalse);

      final request = notifier.send('hello', errorText: _errorText);
      expect(notifier.state.requestStatus, ChatRequestStatus.sending);
      expect(notifier.state.isReplying, isTrue);

      engine.completer.complete(const Right<Failure, String>('answer'));
      await request;

      expect(notifier.state.requestStatus, ChatRequestStatus.succeeded);
      expect(notifier.state.isReplying, isFalse);
      expect(notifier.state.messages, hasLength(2));
      expect(notifier.state.messages.last.text, 'answer');
      expect(notifier.state.errorMessage, isNull);

      notifier.dispose();
    });

    test('transitions to failed without labeling the result as visual state',
        () async {
      final engine = _CompleterEngine();
      final notifier = ChatNotifier(SendMessage(engine));

      final request = notifier.send('hello', errorText: _errorText);
      engine.completer.complete(
        const Left<Failure, String>(ServerFailure('unavailable')),
      );
      await request;

      expect(notifier.state.requestStatus, ChatRequestStatus.failed);
      expect(notifier.state.isReplying, isFalse);
      expect(notifier.state.errorMessage, _errorText);
      expect(notifier.state.messages, hasLength(2));
      expect(notifier.state.messages.last.text, _errorText);
      expect(notifier.state.messages.last.text, isNot(contains('unavailable')));

      notifier.dispose();
    });
  });
}
