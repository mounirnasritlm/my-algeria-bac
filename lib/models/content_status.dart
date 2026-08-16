/// Snapshot of the content state the app can display.
class ContentStatus {
  const ContentStatus({
    this.version,
    required this.hasCachedContent,
    required this.usingCachedContent,
  });

  /// Version of the content currently served to the UI.
  final String? version;

  /// Whether a downloaded bundle is stored on device.
  final bool hasCachedContent;

  /// Whether the app is reading from the cache (false when it falls back to
  /// the bundled assets).
  final bool usingCachedContent;
}
