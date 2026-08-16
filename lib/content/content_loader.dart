/// A source of content files, addressed by content-relative paths such as
/// `manifest.json` or `subjects.json`.
///
/// Implementations map the relative path to wherever the content actually
/// lives: bundled assets, a GitHub repository, or the on-device cache.
abstract class ContentLoader {
  /// Whether a file at [path] can be read from this source.
  Future<bool> exists(String path);

  /// Reads the full contents of the file at [path].
  ///
  /// Throws a [ContentNotFoundException] when the file does not exist and a
  /// transport error (e.g. [TimeoutException]) when the source cannot be
  /// reached.
  Future<String> loadFile(String path);
}

/// Thrown when a requested content file is absent from its source.
class ContentNotFoundException implements Exception {
  const ContentNotFoundException(this.path, {this.statusCode});

  final String path;

  /// HTTP status when the failure came from a remote request; null otherwise.
  final int? statusCode;

  @override
  String toString() =>
      'ContentNotFoundException($path${statusCode == null ? '' : ', HTTP $statusCode'})';
}
