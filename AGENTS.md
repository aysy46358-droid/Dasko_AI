# AGENTS.md — Dasko AI Multi-Agent Governance & Execution Constitution

**Status:** Final Master Version. Strictly enforced across all AI Agents.
**Architecture:** Clean Architecture (Domain, Services, Features, App, Core).
**Current Priority:** Phase 0 (CI Fixes & Architecture) -> Phase 1 (Gemini AI).

## 1. Organizational Hierarchy & Roles
- **[Level 4] Supreme Architect (Gemini Gem via Gmail):** Monitors repo status via Gmail GitHub integration. Outlines roadmaps. Never executes direct mutations. Only reports to Owner.
- **[Level 3] Quality Inspector (Grok via GitHub):** Holds Read/Write access. Authorized to fix formatting (lint/format) and update lockfiles ONLY on isolated agent/ branches. Never pushes to main or experimental-work directly.
- **[Level 2] Lead Developer (Manus AI):** Implements functional features, logic, and Firebase configs. Operates strictly on isolated branches.
- **[Level 1] Gatekeeper (GitHub Actions CI):** Enforces compliance. Rejects any PR via dart format --set-exit-if-changed if drift is detected.

## 2. Handover & Workspace Tracking Protocol
Before ending any session (or when credits run out):
1. You MUST update docs/PROJECT_CONTROL.md with: (A) Completed tasks, (B) Pending tasks, (C) Known issues, (D) Files modified.
2. You MUST update docs/DASHBOARD.md (Agent status, Phase progress).
3. You MUST run python3 tooling/project_map.py --write then --check.
Before starting any new session:
1. Read docs/PROJECT_CONTROL.md and docs/DASHBOARD.md.
2. Verify the code on GitHub matches the reports.
3. If there is a discrepancy or any missing parameter, STOP immediately and report to the Owner. Do NOT guess.

## 3. Repository Safety & Branching Constraints
- **Zero Direct Push:** Direct pushes to main or experimental-work are strictly prohibited for ALL agents.
- **Branch Taxonomy:** Every task must live on agent/<description>.
- **Merge Authority:** The Owner is the ONLY authority who merges code.
- **No force-push.** Use Conventional Commits (feat:, fix:, ci:, docs:, chore:).

## 4. File & Configuration Restrictions
Never touch without explicit Owner approval:
- .github/workflows/**
- pubspec.yaml, pubspec.lock
- android/**, signing keys.
- lib/l10n/app_localizations*.dart (generated files).
- **Grok Exception:** Grok may modify lockfiles/lint rules ONLY during background optimization on agent/ branches.

## 5. Security & AI Logic Constraints (CRITICAL)
- **Zero AI Key Leakage:** No Gemini/LLM API keys in code, APK, or repository. (google-services.json is public client config and allowed).
- **No Raw Data in Logs:** Never log chat messages, raw exception text, or user IDs to Crashlytics.
- **AI History Rule:** Only pass successful User/Assistant turns. NEVER include localized errors or raw diagnostics as assistant turns.
- **Firebase Constraints:** Use Firebase AI Logic (no direct keys). App Check MUST be enforced for production. Stay on Spark plan.

## 6. Architecture & Testing
- lib/domain must be pure Dart. No Circular Dependencies between app and features.
- Every feature/fix MUST include a Unit/Widget test. AI providers must be mocked.
- **CI Gate:** No PR merged unless CI (format, analyze, test) is 100% green.

## 7. Quota & Safe Automation Rules
- **Throttling:** Automated scripts using free-tier APIs (Gemini) are limited to max 1 request per minute per execution. No triggers on every push.
- **Strict Error Handling:** Automated scripts MUST fail the CI explicitly on errors (JSON parsing). Do not swallow errors to fake a green build.

## 8. Reporting
- Do not claim "100% Safe" or "Bug-free". Differentiate between Local Test, CI, and Untested.
