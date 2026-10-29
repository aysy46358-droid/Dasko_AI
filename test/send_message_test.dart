import 'package:dartz/dartz.dart';
import 'package:dasko_ai/core/errors/failures.dart';
import 'package:dasko_ai/domain/usecases/send_message.dart';
import 'package:dasko_ai/services/ai_engine/ai_engine.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEngine implements AiEngine {
  _FakeEngine(this.response);

  final Either<Failure, String> response;

  @override
  Future<Either<Failure, String>> generateResponse({
    required String prompt,
    String? systemInstruction,
    List<Map<String, String>>? history,
  }) async {
    return response;
  }
}

void main() {
  test('SendMessage rejects empty prompt', () async {
    final useCase = SendMessage(_FakeEngine(const Right('ok')));
    final result = await useCase(prompt: '   ');
    expect(result.isLeft(), isTrue);
  });

  test('SendMessage maps engine success to assistant Message', () async {
    final useCase = SendMessage(_FakeEngine(const Right('hello')));
    final result = await useCase(prompt: 'hi');
    expect(result.isRight(), isTrue);
    result.fold(
      (_) => fail('expected success'),
      (message) {
        expect(message.isUser, isFalse);
        expect(message.text, 'hello');
      },
    );
  });

  test('SendMessage maps engine failure', () async {
    final useCase = SendMessage(_FakeEngine(const Left(ServerFailure('down'))));
    final result = await useCase(prompt: 'hi');
    expect(result.isLeft(), isTrue);
  });
}
