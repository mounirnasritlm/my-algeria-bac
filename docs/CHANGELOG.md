# CHANGELOG

All notable changes to this project are documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/). Dates use
YYYY-MM-DD.

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
