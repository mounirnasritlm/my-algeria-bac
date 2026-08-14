# HANDOVER SESSIONS

Handover log for agent sessions. Newest at the bottom. Keep entries factual
and self-contained so any agent can resume.

---

## Session 2026-08-14 — Project bootstrap

**Goal:** Prove the core app shell compiles (product owner's Flutter shell).

**Done**
- Verified toolchain: Flutter 3.47.0 stable / Dart 3.13.0, Android SDK 36.0.0,
  JDK 17. No Android device/emulator available (validation via analyze +
  `assembleDebug`).
- `flutter create` scaffold (project `my_algeria_bac`, org
  `dz.myalgeriabac`, platform android, `applicationId`
  `dz.myalgeriabac.my_algeria_bac` — **placeholder, unconfirmed**).
- Wrote `lib/main.dart` (product-owner shell), replaced template test with a
  shell smoke test.
- Created `docs/` set: Rules.md (backbone), PROJECT_MAP, CHANGELOG, DECISIONS,
  TASKS, BUGS, UI_SPEC, HANDOVER_SESSIONS.
- Validation: `flutter analyze` + `flutter test` + `flutter build apk --debug`
  (see results).

**Environment note**
- The sandboxed shell could not write under `C:\Users\win\Documents`
  (ACL: `CodexSandboxUsers` had RX only). It was fixed mid-session; writes to
  the workspace now work. If builds start failing with file-not-found on
  writes, re-check this.

**Next steps** (in order)
1. Confirm final `applicationId` (D-005).
2. Data model backbone + persistence + vertical slices (Phase 1, TASKS.md).
3. Wire Home dashboard to real data (UI_SPEC: static values listed).

---

## Session 2026-08-14 (continuation) — APK build blocked by network

**Goal:** Get `flutter build apk --debug` to produce an APK.

**Done**
- `flutter analyze` → no issues; `flutter test` → 1/1 passed (shell smoke test).
- Root-caused the build hang: Flutter's AGP 9.1.0 project auto-installs the
  **NDK 28.2.13676358** (~1 GB) via sdkmanager before building. The Flutter
  gradle plugin only *reads* `ndkVersion`; AGP 9's **default** NDK triggers the
  download even after removing `ndkVersion = flutter.ndkVersion` from
  `android/app/build.gradle.kts`. `android.builder.sdkDownload=false` in
  `android/gradle.properties` did NOT stop it (see BUGS).
- Workaround (UNCERTAIN, TEMPORARY): created a marker
  `C:\Android\ndk\28.2.13676358\source.properties` (`Pkg.Revision =
  28.2.13676358`) so AGP believes the NDK is installed and skips the download.
  Debug builds don't run the native strip step, so this should be safe for
  `assembleDebug`; RELEASE builds with native stripping must not rely on it.

**Blocked — slow network**
- All external hosts measure ~2-12 KB/s (dl.google.com, maven.google.com,
  repo.maven.apache.org, plugins.gradle.org). The remaining Gradle dependency
  downloads (e.g. `kotlin-compiler-embeddable` ~60 MB, androidx transitive set)
  are estimated at several hours at current bandwidth, with frequent stalls.
- Current cache state (~09:00): `~/.gradle/caches/modules-2/files-2.1` has 1144
  module dirs. Present: AGP 9.1.0, kotlin-gradle-plugin 2.4.0, androidx
  core/activity/fragment/lifecycle, flutter_embedding_debug. Missing:
  kotlin-compiler-embeddable, material, and other transitives.
- Resume command (from project root): `flutter build apk --debug`. Downloads
  resume from the Gradle cache. Machine was kept awake during grinding; if the
  machine sleeps, Gradle builds stall.

**Next steps** (in order)
1. Keep `flutter build apk --debug` running until the APK exists at
   `build/app/outputs/flutter-apk/app-debug.apk`; verify with a debug install
   on a device when one is available.
2. Commit the shell + docs milestone once the APK builds (or document the
   blocker if the network never allows it).
3. Confirm final `applicationId` (D-005) before any release work.
