# Dasko AI

Advanced personal AI companion built with Flutter.

## Branch: `experimental-work`

This branch is the active experimental line. It extends the Phase 0 foundation with cinematic UI, intro flow, tracked Android project, and stricter CI.

### What works now

- Clean folder structure (`app` / `core` / `domain` / `features` / `services`)
- Riverpod app scope
- `AiEngine` interface with `MockAiEngine` implementation
- `aiEngineProvider` (UI does not construct the engine)
- `SendMessage` use case
- `ChatNotifier` owns chat state (messages, loading, robot state)
- Intro screen with optional welcome audio + TTS (failures are non-fatal)
- Chat UI with neon/cinematic presentation
- Firebase init is optional at runtime (app still launches if init fails)
- CI: format check, analyze, tests, signed release APK verification

### What is still mock

- AI replies come from `MockAiEngine` only
- No real LLM provider is wired yet

### Entry flow

1. `DaskoIntroScreen` (welcome)
2. `ChatScreen` (conversation UI)

### Structure (current)

```
lib/
├── main.dart
├── app/app.dart
├── core/
├── domain/
│   ├── entities/
│   └── usecases/send_message.dart
├── features/chat/
│   ├── application/chat_notifier.dart
│   └── presentation/
└── services/ai_engine/
    ├── ai_engine.dart
    ├── mock_ai_engine.dart
    └── ai_providers.dart
```

### Launcher icon

`assets/icon/dasko_icon.svg` is present. A final `dasko_icon.png` (512x512) is required before running `flutter_launcher_icons`. The generator config is intentionally disabled until that PNG exists.

### Next hard step

Replace `MockAiEngine` behind `aiEngineProvider` with a real provider implementation (e.g. Gemini) without changing chat UI code.
