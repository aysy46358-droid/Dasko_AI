import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';

/// Unified interface for any AI provider (Gemini, local models, etc.)
abstract class AiEngine {
  Future<Either<Failure, String>> generateResponse({
    required String prompt,
    String? systemInstruction,
    List<Map<String, String>>? history,
  });
}
