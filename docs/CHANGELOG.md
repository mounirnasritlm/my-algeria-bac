# CHANGELOG

All notable changes to this project are documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/). Dates use
YYYY-MM-DD.

## [0.2.0] - 2026-08-16

### Added
- Learning core: subjects → chapters → lessons, demo content with provenance,
  content repository (assets + JSON), quiz engine with mastery feedback.
- BAC Boss: timed exam sessions with autosave/resume, flags, navigator,
  auto-submit on expiry, and a full exam report with comeback plan.
- Gamification: XP ledger, levels + BAC ranks, achievements (localized),
  streak 2.0 with daily goals, smart study plan with weak-point priorities.
- Localization: catalog-driven UI (`AppStrings.t`) in French/Arabic/English,
  Arabic-primary (`appLanguage = 'ar'`) with Arabic demo content; engine-layer
  strings centralized in `lib/l10n/engine_strings.dart`.
- Developer tools: diagnostics panel (`lib/dev/developer_menu.dart`) gated
  behind `FeatureFlags.developerTools` (off by default).
- Database tests: `sqflite_common_ffi` dev dependency; schema creation and
  v1→v8 / v7→v8 migration tests (`test/database_migration_test.dart`).
- CI: `.github/workflows/ci.yml` (flutter analyze + test on push/PR).

### Changed
- Android launcher label: `my_algeria_bac` → `MY Algeria BAC` (technical
  package name unchanged).
- Tests updated for Arabic-primary defaults (widget/app_strings/profile/plan/
  exam-session suites).

### Security
- Dependency/secrets audit (2026-08-16): all direct dependencies up to date;
  no API keys, tokens, or secrets found in tracked files. See DECISIONS D-010.

## [0.1.0] - 2026-08-14

### Added
- Flutter project scaffold (`flutter create`, project name `my_algeria_bac`,
  org `dz.myalgeriabac`, platform: android).
- App shell (single-file `lib/main.dart`):
  - `MyAlgeriaBacApp` MaterialApp entry, theme `AppTheme.light()`.
  - Material 3 theme: primary `#2563EB`, secondary `#10B981`,
    background `#F7F9FC`; Card/InputDecoration/NavigationBar themes.
  - `MainShell` with 5-tab bottom navigation (Home, Learn, Practice,
    Progress, Profile) using `IndexedStack`.
  - `HomePage` dashboard: header + streak chip, daily mission card,
    continue-learning card, progress card, quick-practice card.
  - Placeholder pages for Learn / Practice / Progress / Profile.
- Widget smoke test covering app boot + tab navigation.
- Documentation set under `docs/` (Rules, PROJECT_MAP, DECISIONS, TASKS,
  BUGS, UI_SPEC, CHANGELOG, HANDOVER_SESSIONS).

### Notes
- Navigation intentionally minimal (no routing package yet).
- No data layer, gamification, monetization, or educational content yet.
  All UI values shown on Home (streak `3`, mission `4/10`, mastery `42%`,
  etc.) are static placeholders — NOT real data.
- No Android device/emulator available at build time; validation via
  `flutter analyze` + `flutter build apk --debug`.

### Changed
- `android/app/build.gradle.kts`: skip the `strip*DebugSymbols` Gradle tasks.
  Debug builds keep the Flutter engine's debug symbols, so stripping is
  unnecessary and would require a real NDK install (BUGS B-001).
- Debug APK now builds: `build/app/outputs/flutter-apk/app-debug.apk` (~22 MB).
