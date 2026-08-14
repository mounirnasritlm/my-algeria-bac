# TASKS

Task tracker mapped to Rules.md §42 (feature phases) and §61 (first
milestone). Status legend: `[ ]` pending, `[~]` in progress, `[x]` done.

## Phase 0 — Shell (current)

- [x] Flutter project scaffold (Android platform, API 36)
- [x] App shell: theme + 5-tab navigation + Home dashboard
- [x] Shell smoke test
- [x] Documentation set (`docs/`)
- [ ] Confirm final `applicationId` (see DECISIONS D-005) — **blocking for release only**

## Phase 1 — Foundation (Rules.md §61)

- [ ] Data model backbone: BAC Stream → Subject → Unit → Lesson → Concept → Question → Quiz → User Progress
- [ ] Local persistence layer (DB decision pending: SQLite/Hive/other — must be verified, not assumed)
- [ ] Subjects screen
- [ ] Lessons screen
- [ ] Quiz engine (extensible question types, Rules.md §10)
- [ ] Quiz screen
- [ ] Progress screen (real data)
- [ ] XP system
- [ ] Basic streak system
- [ ] Unit tests for XP / streak / mastery / quiz scoring
- [ ] Localization foundation (Arabic RTL, French, English)

## Phase 2 — BAC Engine (Rules.md §13, §14)

- [ ] BAC exam archive
- [ ] Exam mode (timer, navigation, scoring)
- [ ] Solutions / corrections
- [ ] Weak points system
- [ ] Review / spaced-repetition scheduler (encapsulated, Rules.md §12)
- [ ] "How to Study" academy

## Phase 3 — Monetization (Rules.md §27–§34)

- [ ] AdProvider abstraction
- [ ] Rewarded ads (non-monetary rewards only — Rules.md §28)
- [ ] Premium + Play Billing entitlement architecture

## Phase 4 — Content Ecosystem (Rules.md §24, §16)

- [ ] Video hub
- [ ] Remote content / content packs
- [ ] Sponsor system (clearly separated from recommendations — Rules.md §32)

## Phase 5 — Advanced (deferred, not started)

- [ ] Adaptive learning / advanced analytics / leaderboards / challenges
- [ ] AI-assisted tutoring (retrieval from verified content — Rules.md §43)

## Content pipeline (Rules.md §2, §26)

- [ ] Content schema with provenance metadata
- [ ] Validation pipeline: import → parse → normalize → source check → structure check → answer check → human review → publish
- [ ] Product owner to supply verified source content
