# MY Algeria BAC

Algerian BAC-learning ecosystem. Flutter app for Android
(targetSdk 36 — required by Google Play for new apps/updates from
August 31, 2026).

## Status

**Milestone 2 — learning core + gamification + Arabic-first localization.**
Subjects/chapters/lessons, quizzes, timed BAC Boss exams with autosave, XP and
levels, achievements, streaks, smart study plan, and a catalog-driven UI in
French/Arabic/English (Arabic-primary). Stabilization V1 done: developer tools
behind a feature flag, database migration tests, and CI
(`.github/workflows/ci.yml`). See `docs/PROJECT_MAP.md`, `docs/TASKS.md`, and
`docs/DECISIONS.md` (D-010).

## Prerequisites

- Flutter 3.47+ (stable) with Android toolchain
- Android SDK 36 (`platforms;android-36`, `build-tools;36.0.0`)

## Commands

```bash
flutter pub get        # resolve dependencies
flutter analyze        # static analysis
flutter test           # run widget/unit tests
flutter build apk --debug   # build debug APK (build/app/outputs/flutter-apk/)
flutter run            # run on a connected device/emulator
```

## Rules and docs

The project runs under a strict anti-hallucination ruleset. Read it before
writing code:

- `docs/Rules.md` — the backbone (must-know)
- `docs/DECISIONS.md` — decision log (see D-005: applicationId is an
  unconfirmed placeholder)
- `docs/UI_SPEC.md` — design/UI reference
- `docs/TASKS.md` — phase roadmap
