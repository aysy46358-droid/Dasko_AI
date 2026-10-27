import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import 'ai_engine.dart';

/// Temporary mock implementation.
/// Will be replaced by real Gemini (or other) provider in Phase 1.
class MockAiEngine implements AiEngine {
  @override
  Future<Either<Failure, String>> generateResponse({
    required String prompt,
    String? systemInstruction,
    List<Map<String, String>>? history,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return const Right(
      'وصلتني رسالتك. هذا رد مؤقت من MockAiEngine. سيتم استبداله بمحرك حقيقي في المرحلة التالية.',
    );
  }
}
