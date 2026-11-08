import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/ai_engine.dart';
import '../domain/usecases/send_message.dart';
import '../features/chat/application/chat_notifier.dart';
import '../services/ai_engine/mock_ai_engine.dart';

/// Composition-root binding for the currently selected local demo engine.
/// Replace this binding when a real provider is deliberately introduced.
final aiEngineProvider = Provider<AiEngine>((ref) => MockAiEngine());

final sendMessageProvider = Provider<SendMessage>((ref) {
  return SendMessage(ref.watch(aiEngineProvider));
});

final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.watch(sendMessageProvider));
});

/// Selectable app palettes.
///
/// `neon` is the product's signature look: the dark canvas plus cyan/violet
/// glow accents. `light` and `dark` are the plain Material variants.
enum AppThemeMode { light, dark, neon }

/// App-wide theme selection consumed by `MaterialApp.theme`.
/// Defaults to [AppThemeMode.neon] because that is the shipped aesthetic.
final themeProvider = StateProvider<AppThemeMode>((ref) => AppThemeMode.neon);
