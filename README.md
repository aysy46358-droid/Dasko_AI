# Dasko AI

Advanced personal AI companion built with Flutter.

## Current Status (Phase 0 completed)

Clean Architecture foundation is in place.

### Structure

```
lib/
├── main.dart
├── app/
│   └── app.dart
├── core/
│   ├── constants/
│   ├── errors/
│   └── theme/
├── domain/
│   └── entities/
├── features/
│   └── chat/
│       └── presentation/
└── services/
    └── ai_engine/
```

### What is ready
- Clean folder structure
- Riverpod setup
- Theme system
- Failure types
- Message entity
- AiEngine interface + Mock implementation
- Constitution file (`assets/persona/dasko_constitution.yaml`)
- Proper `.gitignore`

### Next
Phase 1: Real AI engine (Gemini) + improved chat flow
