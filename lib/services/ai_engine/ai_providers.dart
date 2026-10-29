import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_engine.dart';
import 'mock_ai_engine.dart';

/// Application-wide AI engine binding.
/// Swap [MockAiEngine] for a real implementation without touching UI code.
final aiEngineProvider = Provider<AiEngine>((ref) {
  return MockAiEngine();
});
