import 'package:http/http.dart' as http;

import '../config/content_config.dart';
import '../data/content_repository.dart';
import '../data/json_content_repository.dart';
import '../models/content_status.dart';
import 'atomic_cache_content_loader.dart';
import 'content_release_cache.dart';
import 'content_sync_result.dart';
import 'content_sync_service.dart';
import 'github_content_loader.dart';

/// Facade over the content pipeline: syncs remote content on demand and hands
/// the app a [ContentRepository] backed by the best available source.
///
/// Source preference:
///   1. the validated, atomically-activated cached release,
///   2. the bundled assets shipped with the app.
class AppContentManager {
  AppContentManager({
    required this.assets,
    ContentConfig? config,
    ContentReleaseCache? cache,
    http.Client? httpClient,
  })  : _config = config ?? const ContentConfig(),
        _cache = cache ?? ContentReleaseCache() {
    _remote = GitHubContentLoader(config: _config, client: httpClient);
    _syncService = ContentSyncService(remoteLoader: _remote, cache: _cache);
  }

  final ContentRepository assets;

  final ContentConfig _config;

  final ContentReleaseCache _cache;

  late final GitHubContentLoader _remote;

  late final ContentSyncService _syncService;

  /// Downloads and verifies the latest remote bundle, then activates it.
  Future<ContentSyncResult> syncNow() => _syncService.sync();

  /// Removes all cached releases. The app falls back to the bundled assets
  /// until the next successful sync.
  Future<void> clearCache() => _cache.clear();

  /// The repository the app should read from right now.
  ///
  /// Returns a cache-backed repository when an active release exists,
  /// otherwise the bundled assets.
  Future<ContentRepository> activeRepository() async {
    if (await _cache.hasActive()) {
      return JsonContentRepository(loader: AtomicCacheContentLoader(_cache));
    }
    return assets;
  }

  /// A snapshot of the content state for display purposes.
  Future<ContentStatus> status() async {
    final hasActive = await _cache.hasActive();
    if (!hasActive) {
      return const ContentStatus(
        hasCachedContent: false,
        usingCachedContent: false,
      );
    }

    return ContentStatus(
      version: await _cache.activeVersion(),
      hasCachedContent: true,
      usingCachedContent: true,
    );
  }
}
