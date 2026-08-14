# DECISIONS

Decision log. Format: DECISION / REASON / STATUS / SOURCE. Append new
entries; never rewrite history without a note.

---

## D-001 — Flutter as the app framework

- DECISION: Build the app with Flutter (Dart), Android target.
- REASON: Product owner supplied the Flutter app shell and instructed that the
  core shell must compile first. (An earlier draft plan proposed Kotlin +
  Jetpack Compose; it was superseded by the product owner's Flutter input.)
- STATUS: Accepted
- SOURCE: Product owner prompt (Flutter shell code).

## D-002 — Prove the shell before adding dependencies

- DECISION: Do not install Firebase, AdMob, RevenueCat, Hive, SQLite,
  authentication, AI, or other third-party packages yet.
- REASON: "We're first proving the core shell compiles." Keep the first
  milestone small and verifiable; each dependency must later be verified
  against current official docs (Rules.md §3).
- STATUS: Accepted
- SOURCE: Product owner prompt.

## D-003 — Minimal navigation for now

- DECISION: Use `MaterialApp.home` + an in-shell `NavigationBar` /
  `IndexedStack` tab switch. No routing package.
- REASON: Navigation should match actual screen complexity; a routing package
  is not needed before the screen structure requires it.
- STATUS: Accepted
- SOURCE: Product owner prompt.

## D-004 — Single-file app shell for milestone 0

- DECISION: Keep the whole shell in `lib/main.dart` as delivered.
- REASON: Fastest path to a compiling, runnable slice; refactoring into
  folders is a deliberate next step alongside the data layer (vertical
  slices, Rules.md §51).
- STATUS: Accepted (interim)
- SOURCE: Engineering.

## D-005 — Placeholder package name

- DECISION: `flutter create --org dz.myalgeriabac` →
  `applicationId dz.myalgeriabac.my_algeria_bac`.
- REASON: The product owner has NOT confirmed the final applicationId. This is
  a placeholder that MUST be confirmed before any Play release (Rules.md §55 —
  package name is expensive to reverse after release).
- STATUS: UNKNOWN — REQUIRES DECISION (pending product owner confirmation)
- SOURCE: Default, flagged.

## D-006 — No fabricated educational content in milestone 0

- DECISION: The shell renders static placeholder values (streak 3, mission
  4/10, mastery 42%, "Mathematics • Functions"). These are UI placeholders,
  not real user data and NOT educational content.
- REASON: Rules.md §1/§2 — never fabricate educational facts or requirements.
- STATUS: Accepted (placeholders clearly marked as static in CHANGELOG)
- SOURCE: Rules.md.

## D-007 — Target Android 16 (API 36)

- DECISION: Build against compileSdk/targetSdk 36.
- REASON: Google Play requires new apps/updates to target Android 16 / API 36+
  from August 31, 2026 (product owner note). Android SDK 36.0.0 is installed.
- STATUS: Accepted
- SOURCE: Product owner prompt + verified environment.

## D-008 — NDK auto-download workaround (TEMPORARY, UNCERTAIN)

- DECISION: Skip the ~1 GB NDK 28.2 auto-download during `assembleDebug` by
  placing a fake installed-NDK marker at
  `C:\Android\ndk\28.2.13676358\source.properties` (`Pkg.Revision =
  28.2.13676358`).
- REASON: The network cannot complete the download in reasonable time; debug
  builds don't run the native strip step. This is a build-environment
  workaround, NOT a real NDK.
- STATUS: TEMPORARY — accepted for `assembleDebug` only; must be removed and
  replaced with a real NDK 28.2 install before any release/native build.
- SOURCE: Engineering (BUGS B-001).
