# CODE REVIEW — Backlog of fixes for advisor-provided code

Tracker for issues found while reviewing the advisor's code slices
(`Desktop/1.txt` … `4.txt` + future ones) against this repo and Rules.md.
Apply the fixes once all the code is in, then tick them off. Newest findings
append at the bottom.

Status legend: `[ ]` OPEN, `[x]` DONE, `[~]` partial/in progress.

---

## Priority 1 — Schema (foundation; fix before real content arrives)

- [x] **FIX-01 — Provenance fields are incomplete on `Question`.** (3.txt)
  Only `sourceId` + `verified: bool` exist. Rules.md §2 (lines 40–54) requires
  `sourceType / sourceName / sourceYear / sourceUrl / sourcePage` (+ the
  validation pipeline status, Rules.md line 300: `validationStatus`). Expand
  to the Rules.md shape (structured `source` object or equivalent).
  FIX: added `models/source.dart` (`ContentSource`: sourceType, sourceName,
  sourceYear, sourceUrl, sourcePage, verified) and `validationStatus` on
  `Question`.

- [x] **FIX-02 — Only `Question` has provenance.** (3.txt)
  Rules.md requires provenance on EVERY educational content item — `Lesson`
  and `Concept` must carry it too.
  FIX: `Lesson.source` and `Concept.source` now carry a `ContentSource`.

- [x] **FIX-03 — `Concept` model is missing.** (3.txt)
  `Lesson.conceptIds` references concepts and the tree claims a Concepts
  level, but there is no `models/concept.dart`.
  FIX: added `models/concept.dart` (id, name, summary, lessonId, source) and
  `DemoData.concepts` resolving every referenced concept id.

- [x] **FIX-04 — `Question` cannot represent its own types.** (3.txt, 4.txt)
  `numeric`, `multiSelect`, `trueFalse` have no representation in
  `choices` + `correctChoiceIndex`. The quiz engine also assumes
  multiple-choice semantics.
  FIX: added `QuestionType { multipleChoice, trueFalse, numeric }` with
  per-type answers (`correctIndex` for choice types, `numericAnswer` for
  numeric). `QuizPage` filters quiz sets to choice types and only scores
  those; numeric/multiSelect are reserved (engine renders nothing for them
  until implemented). See DECISIONS.
  NOTE: the persisted `question_attempts` schema still stores choice indexes
  only — see FIX-20 (still OPEN, needs schema v2 + migration).

- [x] **FIX-05 — Demo lesson text is fabricated educational content.** (3.txt)
  Demo `Lesson.description`s ("Introduction to mathematical functions." etc.)
  are educational claims with NO provenance and NOT flagged as demo.
  Rules.md: never fabricate educational content.
  FIX: every demo Lesson/Concept/Question now uses
  `ContentSource.requiresVerification` (`CONTENT_REQUIRES_VERIFICATION`,
  `verified: false`); `LessonPage` already shows a "demonstration content
  only" banner. Real verified content arrives with the real content pipeline.

## Priority 2 — Regressions vs shipped milestone 0

- [x] **FIX-06 — Do not replace the shipped shell wholesale.** (1.txt, 3.txt,
  4.txt)
  The advisor's main.dart drops milestone-0 deliverables: the custom
  `AppTheme` (colors #2563EB/#10B981/#F7F9FC, card/nav-bar/input themes) and
  the Home dashboard (streak chip, mission, continue-learning, progress,
  quick-practice cards).
  FIX: `AppTheme` restored unchanged in `lib/app/app_theme.dart`; dashboard
  cards restored in `lib/screens/home_page.dart`; "Continue learning" and
  "Start practice" now navigate to `SubjectPage('math')`.

- [x] **FIX-07 — Folder structure vs inline code contradiction.** (2.txt,
  3.txt, 4.txt)
  Step 1 declares `models/`, `screens/`, `app/`, `data/` but the pasted code
  keeps `MainShell`/`HomePage`/`LearnPage` inline in main.dart.
  FIX: thin `main.dart` (entry + `StudyApp`); `MainShell` in
  `lib/screens/main_shell.dart`; all pages import from `screens/`.

## Priority 3 — Compile errors in provided code

- [x] **FIX-08 — Duplicate `_MainShellState` class.** (2.txt)
  Declared twice → won't compile. Remove one.
  FIX: not applicable — the advisor's inline main.dart was never pasted
  wholesale; the shipped code has a single `MainShell` in
  `lib/screens/main_shell.dart`.

- [x] **FIX-09 — `DemoData` referenced but never provided.** (2.txt)
  `DemoData.subjects` / `DemoData.questions` used before `data/demo_data.dart`
  (and the `Question` model) exist.
  FIX: models + `data/demo_data.dart` landed together with the screens.

- [x] **FIX-10 — 1.txt is an incomplete fragment.** (1.txt)
  No imports / `main()` / shell classes; starts mid-file. Not paste-able.
  FIX: not applicable — the shell came from the shipped milestone-0
  (`main.dart` + `screens/`), not from 1.txt.

## Priority 4 — Screen robustness & correctness

- [x] **FIX-11 — `firstWhere` without `orElse`.** (4.txt)
  `SubjectPage` and `LessonPage` crash with StateError on a missing id.
  FIX: added `orElse: () => ...first` fallbacks in `SubjectPage`,
  `LessonPage`, and both `firstWhere` calls in `QuizPage` (`_loadTitle`,
  `_finishQuiz`).

- [x] **FIX-12 — Quiz engine only handles `multipleChoice`.** (4.txt)
  `_choiceColor` / `_choiceIcon` / scoring assume `correctChoiceIndex`.
  FIX: no longer applicable — the shipped `Question` model has no `type`
  field (only `options` + `correctIndex`), so the engine has exactly one
  supported shape and nothing unguarded. The real design work is FIX-04
  (representing question types in the model), which stays OPEN.

- [ ] **FIX-13 — XP value is a display placeholder.** (4.txt)
  `xpEarned = correctAnswers * 10` is not the scoring engine.
  FIX: keep for now but mark clearly; replace with the real scoring engine
  when XP lands (Rules.md).

## Priority 5 — Tests & validation

- [x] **FIX-14 — Smoke test asserts old dashboard texts.** (test/)
  Update `test/widget_test.dart` for the new screens after the refactor;
  keep `flutter analyze` + `flutter test` green.
  FIX: test now asserts the restored dashboard ('Ready for BAC?', 'TODAY\'S
  MISSION') and Learn tab navigation; analyze clean + test 1/1 green.

## Explicitly deferred (do NOT "fix" now)

- [ ] **DEFER-01 — Persistence (sqflite/Drift) until the domain model is
  stable.** (3.txt, 4.txt) Agreed — the advisor's order
  (Attempt → Scoring → Repository → DB → XP/Mastery/Weak points/Review)
  matches Rules.md §12–§14.
- [ ] **DEFER-02 — `UserProgress` is per-lesson only** (no XP totals, streak,
  mastery). Acceptable starting point; extend with `QuizAttempt` /
  `QuestionAttempt` / XP / Streak / Mastery next.
- [ ] **DEFER-03 — `Subject.language` is a plain string.** Plan localized
  content (Arabic/French/English, RTL) later — Rules.md §28.
- [ ] **DEFER-04 — No `quiz.dart` model yet.** Fine until the quiz engine is
  defined; don't claim it exists.

## Informational (no action)

- Advisor text says "Flutter 3.44.7" — repo is on 3.47.0; Material 3 is
  already the default here. No change needed.
- 4.txt navigation (`Navigator.push` + `MaterialPageRoute`, D-003) and the
  result "Back to lesson" pop are correct. No change.

---

## Slice 5 — Persistence (5.txt)

Confirmed good: transaction upsert of lesson_progress, streak logic
(diff==0 keep, diff==1 increment, diff>1 reset) is correct, "result is saved
only after the quiz completes" principle, local-only storage (privacy), and
`refresh-friendly` reload on the Progress screen. No Riverpod/Bloc — agreed.

### Priority 1 — Will break `flutter test`

- [x] **FIX-15 — Smoke test will fail with `MissingPluginException`.**
  `IndexedStack` builds ALL tabs at boot, so the new `ProgressPage.initState`
  → `ProgressRepository()` → `openDatabase()` runs during the test on the Dart
  VM where sqflite has no platform channel.
  FIX (applied): `ProgressRepository._loadCached` already wraps every
  `ProgressDatabase` call in `try/catch` and falls back to
  `UserProgress.empty()`, so the boot path never surfaces the plugin
  exception. Verified: `flutter test` passes 1/1 with the full shell
  mounted.

### Priority 2 — Reliability

- [x] **FIX-16 — DB writes are fire-and-forget before navigation.**
  `saveQuestionAttempt` (per submit) and `saveQuizResult` (on last question)
  are not awaited before `pushReplacement`. The app can be killed before the
  write lands.
  FIX: verified satisfied — `_finishQuiz` `await`s `saveLessonResult` before
  `pushReplacement` (both the "Finish and save" button and the "End quiz"
  dialog paths), and the current quiz never fires per-submit writes (no
  `saveQuestionAttempt` call sites exist).

- [x] **FIX-17 — Verify sqflite/path versions against current docs (Rules.md
  §3) before installing.** Advisor claims sqflite 2.4.3 stable.
  FIX: resolved from the lockfile via `flutter pub deps` — `sqflite 2.4.3`,
  `path 1.9.1`. Matches the advisor's claim; recorded in DECISIONS.

- [x] **FIX-18 — `AppDatabase.get database` can double-open under race.**
  The lazy `if (_database != null)` check + await can open twice if two
  callers race on first access.
  FIX: `ProgressDatabase` now caches `Future<Database>?` via
  `_database ??= _open()`, so concurrent first-access callers share one open.

### Priority 3 — Schema / future-proofing

- [ ] **FIX-19 — No migrations yet (`version: 1`, no `onUpgrade`).**
  When the `Question` answer model generalizes (FIX-04) the
  `question_attempts` schema must change.
  FIX: plan schema versioning + a migration test before any schema change.

- [ ] **FIX-20 — `question_attempts` stores choice INDEX only.**
  `selected_answer` / `correct_answer` are `INTEGER` (choice index). Only
  valid for `multipleChoice` (ties to FIX-04). A numeric question has no
  index. Must change with the answer model.

- [x] **FIX-21 — Progress list shows raw `lesson_id`** (e.g. `math_functions`)
  instead of a readable title. Map ids to lesson titles (via DemoData or a
  stored title column).
  FIX: the `lessons` table already stores a `title` column and
  `LessonProgress.title` is populated; `_LessonProgressCard` now renders
  `progress.title`.

### Deferred (do NOT fix now)

- [ ] **DEFER-05 — Home "Continue learning" is hardcoded to Mathematics.**
  The real fix (read the user's most-recent unfinished lesson from a
  repository) belongs to the next repository/query layer. Keep hardcoded
  until then, but it is a known gap.
- [ ] **DEFER-06 — No app-level state management.** Advisor is right to avoid
  Riverpod/Bloc for one screen; a state layer comes when multiple screens
  need to refresh each other (e.g. Progress reload on visible).
- [ ] **DEFER-07 — XP/streak/mastery live ad-hoc in `app_state`.**
  Verify against Rules.md §31 (mastery formula, streak definitions) when the
  XP system milestone lands; a dedicated schema may replace `app_state`.

### New informational

- `ProgressPage` uses `Future.wait` on five heterogeneous futures then casts
  by index — works but fragile to reordering; fine for now.
- `getOverallAccuracy` uses `COALESCE(SUM(...), 0)` — verified correct with
  sqflite's int/double returns.
