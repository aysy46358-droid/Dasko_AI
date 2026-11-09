# Dasko AI

Advanced personal AI companion built with Flutter.

## Branch: `experimental-work`

This branch is the active experimental line. It extends the Phase 0 foundation with a cinematic intro, a poster-based robot UI, theme choices, a tracked Android project, and CI validation.

### What works now

- Clean folder structure (`app` / `core` / `domain` / `features` / `services`)
- Riverpod app scope and an `AiEngine` domain interface
- `SendMessage` use case and `ChatNotifier` functional chat state
- Presentation maps request status to robot UI status
- Robot UI displays the bundled 2D poster at `assets/images/robot_poster.png`; status effects are Flutter UI effects, not GLB/model-viewer animations
- Light, Dark, and Neon theme choices with best-effort persistence
- Intro screen with optional welcome audio and TTS; failures are non-fatal
- Firebase Core initialization is optional at runtime; Crashlytics handlers are wired for non-fatal Flutter and uncaught asynchronous errors on supported platforms, but report ingestion has not been verified
- CI checks formatting, analysis, tests, assets, Android configuration, and signed release APK metadata

### What is still mock or unverified

- AI replies come from `MockAiEngine` only; no real LLM provider is wired
- The current chat request path sends the current prompt but does not yet pass earlier messages as conversation history
- Crashlytics delivery to Firebase Console/device has not been verified
- Firebase Authentication, Firestore, Realtime Database, Storage, callable Functions, and App Check are not integrated in the application

### Entry flow

1. `DaskoIntroScreen` (welcome)
2. `ChatScreen` (conversation UI)

### Structure (current)

```text
lib/
├── main.dart
├── app/                    # app shell and composition root
├── core/                   # constants, errors, and theme types
├── domain/                 # entities, repository contracts, use cases
├── features/
│   ├── chat/                # application state and presentation
│   ├── settings/            # persisted appearance preference and settings UI
│   └── cinematic_ui/        # presentation-only widgets
└── services/ai_engine/     # MockAiEngine adapter
```

### Firebase security status

The prototype initializes Firebase Core on a best-effort basis and wires Crashlytics for non-fatal Flutter and uncaught asynchronous errors on supported Android/iOS/macOS platforms. The reviewed handlers pass a sanitized error type, fixed source label, and stack frames; they do not pass raw exception messages, chat content, API keys, or user identifiers. This is a source-level statement, not proof of what reaches Firebase in production: no test event has been verified on a device or in Firebase Console. The app does not currently access Firebase Authentication, Firestore, Realtime Database, Cloud Storage, or callable Functions. No deployable Firebase rules or App Check configuration are included in this repository; verify remote console rules and enforcement before adding Firebase-backed data or endpoints.

### Launcher icon

`assets/icon/dasko_icon.svg` is present. A final `dasko_icon.png` (512x512) is required before running `flutter_launcher_icons`. The generator config is intentionally disabled until that PNG exists.

### Next hard step

Before wiring a real `AiEngine`, define the server-side credential boundary, decide how conversation history is represented and passed, and test success, timeout, failure, privacy, and quota handling. Never package a Gemini Developer API key in the APK; verify the provider's current free quotas and privacy requirements before enabling it.

## Project navigation

- [Project map](docs/PROJECT_MAP.md): architecture overview and generated inventory of Git-tracked files.
- [Project control register](docs/PROJECT_CONTROL.md): evidence-based status, open risks, and prioritized next steps.
