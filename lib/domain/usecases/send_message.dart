import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/failures.dart';
import '../../services/ai_engine/ai_engine.dart';
import '../entities/message.dart';

/// Sends a user prompt through [AiEngine] and returns the assistant [Message].
class SendMessage {
  SendMessage(this._engine, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AiEngine _engine;
  final Uuid _uuid;

  Future<Either<Failure, Message>> call({
    required String prompt,
    String? systemInstruction,
    List<Map<String, String>>? history,
  }) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      return const Left(UnexpectedFailure('Empty message'));
    }

    final result = await _engine.generateResponse(
      prompt: trimmed,
      systemInstruction: systemInstruction,
      history: history,
    );

    return result.map(
      (text) => Message(
        id: _uuid.v4(),
        text: text,
        isUser: false,
        createdAt: DateTime.now(),
      ),
    );
  }
}
