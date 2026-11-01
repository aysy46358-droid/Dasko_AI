import 'package:dartz/dartz.dart';
import 'package:dasko_ai/core/errors/app_exception.dart';
import 'package:dasko_ai/core/errors/failures.dart';
import 'package:dasko_ai/domain/repositories/ai_engine.dart';
import 'package:dasko_ai/domain/usecases/send_message.dart';
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

class _ThrowingEngine implements AiEngine {
  _ThrowingEngine(this.error);

  final Object error;

  @override
  Future<Either<Failure, String>> generateResponse({
    required String prompt,
    String? systemInstruction,
    List<Map<String, String>>? history,
  }) async {
    throw error;
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

  test('SendMessage maps typed network exceptions to a safe failure', () async {
    final useCase = SendMessage(_ThrowingEngine(const NetworkException()));
    final result = await useCase(prompt: 'hi');

    result.fold(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('expected a network failure'),
    );
  });

  test('SendMessage hides unexpected exception details', () async {
    final useCase = SendMessage(_ThrowingEngine(Exception('private detail')));
    final result = await useCase(prompt: 'hi');

    result.fold(
      (failure) {
        expect(failure, isA<UnexpectedFailure>());
        expect(failure.message, isNot(contains('private detail')));
      },
      (_) => fail('expected an unexpected failure'),
    );
  });
}
