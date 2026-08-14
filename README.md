# MY Algeria BAC

Algerian BAC-learning ecosystem. Flutter app for Android
(targetSdk 36 — required by Google Play for new apps/updates from
August 31, 2026).

## Status

**Milestone 0 — app shell.** Single-file UI shell (theme + 5-tab navigation +
Home dashboard). All Home values are static placeholders; the data model
backbone comes next. See `docs/PROJECT_MAP.md` and `docs/TASKS.md`.

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
