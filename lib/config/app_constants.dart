/// App-wide display constants.
class AppConstants {
  const AppConstants._();

  /// User-facing product name used by the running app.
  ///
  /// The Android launcher label lives in
  /// `android/app/src/main/AndroidManifest.xml` and is kept in sync manually
  /// because the manifest cannot reference Dart values.
  static const String appDisplayName = 'MY Algeria BAC';
}
