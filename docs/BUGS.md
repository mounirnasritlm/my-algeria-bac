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
  - BROKEN resolution (reverted): disabling the `strip*DebugSymbols` tasks in
    `android/app/build.gradle.kts`. In AGP 9.1 a disabled task's outputs are
    treated as empty, so `stripped_native_libs` was empty and the APK shipped
    with **zero native libs** -> `MissingLibraryException: Could not find
    'libflutter.so'` crash on launch.
  - CURRENT resolution: keep the strip tasks enabled and provide a no-op
    `llvm-strip.exe` stub (compiled from `strip_stub.cs`, copies the input to
    the output instead of stripping) at
    `C:\Android\ndk\28.2.13676358\toolchains\llvm\prebuilt\windows-x86_64\bin\`
    (also as the per-ABI `*-strip.exe` variants AGP probes). Debug engine .so
    files keep their symbols by design, so not stripping them is harmless.
    Debug APKs are consequently large (~650 MB arm64-only) but runnable.
  - STILL OPEN: release builds. Flutter's release engine .so files are
    pre-stripped, but a release APK must be verified end-to-end. Installing
    the real NDK 28.2 (the ~1 GB download AGP wants) is the fully safe option
    and would also shrink debug APKs back to a normal size.
