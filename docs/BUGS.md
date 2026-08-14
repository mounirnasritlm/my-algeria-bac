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
    28.2.13676358`). UNVERIFIED whether the build succeeds end-to-end.
  - Risk: a real NDK is NOT installed. If a build task invokes NDK tools
    (e.g. `stripDebugSymbols` for native stripping), it will fail. Verify the
    full `assembleDebug` result before trusting this.
  - Steps to verify: run `flutter build apk --debug` to completion; for release
    builds, install the real NDK 28.2.
