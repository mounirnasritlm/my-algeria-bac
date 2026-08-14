# BUGS

Known issues and bug tracker. One entry per bug.

---

_No confirmed bugs yet._

## Open / unverified observations

- **B-001 — AGP 9.1.0 forces NDK 28.2 auto-download (UNCERTAIN workaround)**
  - Symptom: `flutter build apk --debug` starts "Installing NDK (Side by side)
    28.2" (~1 GB) before Gradle tasks run; build stalls on the download.
  - Attempted fixes that did NOT stop it: removing
    `ndkVersion = flutter.ndkVersion` from `android/app/build.gradle.kts`;
    adding `android.builder.sdkDownload=false` to `android/gradle.properties`.
  - Root cause (verified in Flutter 3.47 gradle plugin source): the plugin
    only reads `ndkVersion`; AGP 9's **default** NDK version is what triggers
    the install. `ValidateCompileSdkVersionTask.kt:158` even writes
    `ndkVersion = "$maxPluginNdkVersion"`.
  - Workaround applied: fake installed-NDK marker
    `C:\Android\ndk\28.2.13676358\source.properties` (`Pkg.Revision =
    28.2.13676358`). This alone let AGP skip the download but the build then
    failed at `stripDebugDebugSymbols` (no real `llvm-strip`).
  - RESOLVED for debug builds: `android/app/build.gradle.kts` now disables the
    `strip*DebugSymbols` tasks. Debug engine .so files keep their symbols by
    design, so stripping is not needed. `assembleDebug` builds successfully.
  - UNVERIFIED for release builds: Flutter's release engine .so files are
    pre-stripped by Flutter, so disabling the strip task may be acceptable,
    but confirm before shipping a release. Installing the real NDK 28.2 is the
    fully safe option.
  - Steps to verify: run `flutter build apk --debug` to completion (done); for
    release builds, build `app-release.apk` and inspect native lib sizes.
