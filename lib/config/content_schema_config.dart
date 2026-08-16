/// Schema compatibility rules between the app and remote content releases.
///
/// The rule is intentionally conservative: a matching major version is
/// compatible, anything else is rejected. A content schema change that breaks
/// the app requires an app update — the content repository cannot silently
/// teach an old APK how to interpret a new schema.
class ContentSchemaConfig {
  const ContentSchemaConfig._();

  static const String supportedSchemaVersion = '1.0.0';

  static const int supportedMajorVersion = 1;

  /// Whether [remoteVersion] can be consumed by this app.
  ///
  /// Throws [FormatException] when [remoteVersion] is not a valid semver-like
  /// string.
  static bool isCompatible(String remoteVersion) {
    return _readMajorVersion(remoteVersion) == supportedMajorVersion;
  }

  static int _readMajorVersion(String version) {
    final parts = version.split('.');

    if (parts.isEmpty) {
      throw FormatException('Invalid schema version: $version');
    }

    final major = int.tryParse(parts.first);
    if (major == null) {
      throw FormatException('Invalid schema version: $version');
    }

    return major;
  }
}
