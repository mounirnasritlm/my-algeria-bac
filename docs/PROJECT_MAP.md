# PROJECT MAP

## Product
**MY Algeria BAC** — Algerian BAC-learning ecosystem. Flutter app targeting
Android (compileSdk/targetSdk 36).

## Repository layout

```
.
├── lib/
│   └── main.dart          # App entry: theme + main shell + screens (single-file shell milestone)
├── android/               # Flutter-generated Android host project
├── test/
│   └── widget_test.dart   # Shell smoke test (boot + bottom-nav)
├── docs/
│   ├── Rules.md           # Backbone ruleset (product owner, first prompt)
│   ├── PROJECT_MAP.md     # This file
│   ├── CHANGELOG.md       # Version history
│   ├── DECISIONS.md       # Decision log
│   ├── TASKS.md           # Task tracker (phases)
│   ├── BUGS.md            # Known issues / bug tracker
│   ├── UI_SPEC.md         # UI + design spec
│   └── HANDOVER_SESSIONS.md
├── pubspec.yaml
├── analysis_options.yaml
├── .gitignore
└── README.md
```

## Current state (v0.1.0)
- Flutter 3.47.0 stable / Dart 3.13.0, Android SDK 36.0.0.
- Single-file app shell: theme, Material 3, `MainShell` with 5 tabs
  (Home, Learn, Practice, Progress, Profile), Home dashboard cards
  (mission, continue learning, progress, quick practice).
- No routing package, no data layer, no third-party dependencies yet
  (deliberate — see `DECISIONS.md`).
- Unit/widget tests: smoke test only.

## Next layer (per Rules.md §61 & TASKS.md)
The real data model backbone, then the vertical slices built on it:
`BAC Stream → Subject → Unit → Lesson → Concept → Question → Quiz → User Progress`.
