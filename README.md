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
- `ChatNotifier` owns functional chat state; presentation maps request status to the robot expression
- Intro screen with optional welcome audio + TTS (failures are non-fatal)
- Chat UI with neon/cinematic presentation
- Firebase Core initialization is optional at runtime; Auth, database/storage, App Check, and Crashlytics are not yet integrated.
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
├── app/                    # app shell and Riverpod composition root
├── core/                   # constants, errors, and theme
├── domain/                 # entities, repository contracts, use cases
├── features/
│   ├── chat/                # application state and presentation
│   └── cinematic_ui/        # presentation-only widgets
└── services/ai_engine/     # MockAiEngine adapter
```

### Firebase security status

The current prototype initializes Firebase Core on a best-effort basis but does not access Firebase Authentication, Firestore, Realtime Database, Cloud Storage, or callable Functions. No deployable Firebase rules or App Check configuration are included in this repository, so remote console rules and enforcement must be verified before adding any Firebase-backed data or endpoints. Crash reporting is not active yet.

### Launcher icon

`assets/icon/dasko_icon.svg` is present. A final `dasko_icon.png` (512x512) is required before running `flutter_launcher_icons`. The generator config is intentionally disabled until that PNG exists.

### Next hard step

Replace `MockAiEngine` behind `aiEngineProvider` with a real provider implementation without changing chat UI code. Never package a Gemini Developer API key in the APK; select a server-side credential boundary and verify the provider's current free quotas and privacy requirements before enabling it.

## Project navigation

- [Project map](docs/PROJECT_MAP.md): verified architecture overview and generated inventory of Git-tracked files.
- [Project control register](docs/PROJECT_CONTROL.md): evidence-based status, open risks, and prioritized next steps.
