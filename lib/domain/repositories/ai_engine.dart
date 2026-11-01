import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';

/// Contract for generating an assistant response.
///
/// Implementations belong to the infrastructure/services layer; domain use
/// cases depend only on this abstraction.
abstract interface class AiEngine {
  Future<Either<Failure, String>> generateResponse({
    required String prompt,
    String? systemInstruction,
    List<Map<String, String>>? history,
  });
}
