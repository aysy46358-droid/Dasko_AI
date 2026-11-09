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
- Arabic and English localization generated with Flutter `gen-l10n`; language choice is persisted and restored before localized UI is shown
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

### Localization

The app supports Arabic (`ar`, RTL) and English (`en`, LTR) through Flutter's official `gen-l10n` generator. Source strings and placeholder metadata live in `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`; generated Dart localization classes are committed under `lib/l10n/`. `l10n.yaml` defines the generator inputs, and `flutter: generate: true` is enabled in `pubspec.yaml`. The `intl` constraint is `^0.20.3` (resolved to `0.20.3` in `pubspec.lock`, matching the Flutter 3.47.8 `flutter_localizations` constraint).

After editing an ARB file, run `flutter gen-l10n`, review the generated diff, then run `flutter analyze` and `flutter test`. CI resolves dependencies from the lockfile and runs `flutter gen-l10n` before formatting, analysis, and tests. `LocaleNotifier` in `lib/app/providers.dart` restores and persists the language; the app shell waits for restoration before showing localized content to avoid a first-frame language flash.

### Structure (current)

```text
lib/
├── main.dart
├── app/                    # app shell and composition root
├── core/                   # constants, errors, and theme types
├── domain/                 # entities, repository contracts, use cases
├── l10n/                   # ARB sources and committed generated localizations
├── features/
│   ├── chat/                # application state and presentation
│   ├── settings/            # persisted appearance preference and settings UI
│   └── cinematic_ui/        # presentation-only widgets
└── services/ai_engine/     # MockAiEngine adapter
```

### Firebase security status

The prototype initializes Firebase Core on a best-effort basis and wires Crashlytics for non-fatal Flutter and uncaught asynchronous errors on supported Android/iOS/macOS platforms. The reviewed handlers pass a sanitized error type, fixed source label, and stack frames; they do not pass raw exception messages, chat content, API keys, or user identifiers. This is a source-level statement, not proof of what reaches Firebase in production: no test event has been verified on a device or in Firebase Console. The app does not currently access Firebase Authentication, Firestore, Realtime Database, Cloud Storage, or callable Functions. No deployable Firebase rules or App Check configuration are included in this repository; verify remote console rules and enforcement before adding Firebase-backed data or endpoints.

### Launcher icon status

The approved 1024×1024 PNG source set is stored unchanged under `assets/icon/`: `dasko_icon_full_1024.png`, `dasko_foreground_1024.png`, and `dasko_background_1024.png`. `flutter_launcher_icons` generates the Android launcher and adaptive icons from these assets. iOS generation is intentionally disabled (`ios: false`) because this repository does not yet contain an `ios/` project; do not report iOS icon support as complete. Regenerate Android resources with `dart run flutter_launcher_icons`.

### Next hard step

Before wiring a real `AiEngine`, define the server-side credential boundary, decide how conversation history is represented and passed, and test success, timeout, failure, privacy, and quota handling. Never package a Gemini Developer API key in the APK; verify the provider's current free quotas and privacy requirements before enabling it.

## Project navigation

- [Project map](docs/PROJECT_MAP.md): architecture overview and generated inventory of Git-tracked files.
- [Project control register](docs/PROJECT_CONTROL.md): evidence-based status, open risks, and prioritized next steps.

When handing work to another tool or contributor, start with `docs/PROJECT_CONTROL.md`; it records the verified branch/head, current implementation boundaries (including that the robot is a 2D poster, not a 3D model), CI evidence, deferred iOS setup, and remaining security/AI tasks. Then consult `docs/PROJECT_MAP.md` before changing architecture or file ownership.
