/// Typed exceptions raised by infrastructure adapters before being mapped to
/// the domain result type. Details are intentionally not displayed directly to
/// users; user-facing copy is selected by the presentation layer.
sealed class AppException implements Exception {
  const AppException({this.code});

  final String? code;
}

class NetworkException extends AppException {
  const NetworkException({super.code});
}

class AiEngineException extends AppException {
  const AiEngineException({super.code});
}

class SecurityException extends AppException {
  const SecurityException({super.code});
}
