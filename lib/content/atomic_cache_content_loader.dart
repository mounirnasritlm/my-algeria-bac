import 'content_loader.dart';
import 'content_release_cache.dart';

/// Serves content from the active release of the on-device
/// [ContentReleaseCache], using the same content-relative paths as every
/// other loader.
class AtomicCacheContentLoader implements ContentLoader {
  AtomicCacheContentLoader(this._cache);

  final ContentReleaseCache _cache;

  @override
  Future<bool> exists(String path) async {
    return await _cache.readActiveFile(path) != null;
  }

  @override
  Future<String> loadFile(String path) async {
    final content = await _cache.readActiveFile(path);
    if (content == null) {
      throw ContentNotFoundException(path);
    }
    return content;
  }
}
