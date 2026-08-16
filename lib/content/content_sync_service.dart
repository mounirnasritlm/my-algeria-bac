import 'dart:convert';

import '../models/content_manifest.dart';
import '../services/content/content_hash_service.dart';
import '../services/content/content_release_validator.dart';
import 'content_loader.dart';
import 'content_release_cache.dart';
import 'content_sync_result.dart';

/// Downloads content from a remote loader, verifies it against the remote
/// manifest, and activates it in the cache.
///
/// Safety contract:
///  * Nothing is written to `active/` until every file has been downloaded
///    AND verified against its SHA-256 digest in the remote manifest.
///  * Downloads land in a staging directory; activation is a single atomic
///    directory swap, so a crash mid-run never corrupts the bundle the app
///    reads from.
///  * A schema-incompatible or corrupt remote bundle is rejected and the
///    previous active release is kept (`rejectedInvalidUpdate`).
///  * An unreachable remote keeps the previous active release
///    (`offlineUsingCache`).
class ContentSyncService {
  ContentSyncService({
    required ContentLoader remoteLoader,
    required this.cache,
    this.manifestFile = 'manifest.json',
  }) : _remote = remoteLoader;

  final ContentLoader _remote;

  final ContentReleaseCache cache;

  final String manifestFile;

  final ContentReleaseValidator _validator =
      ContentReleaseValidator(ContentHashService());

  Future<ContentSyncResult> sync() async {
    final cachedVersion = await cache.activeVersion();
    final hasActive = await cache.hasActive();

    String? remoteManifestRaw;
    try {
      remoteManifestRaw = await _remote.loadFile(manifestFile);
    } catch (error) {
      return _remoteFailed(cachedVersion, hasActive, error,
          remoteReached: false);
    }

    final ContentManifest remoteManifest;
    try {
      remoteManifest = ContentManifest.fromJson(
        jsonDecode(remoteManifestRaw) as Map<String, dynamic>,
      );
    } catch (_) {
      return _rejected(
        cachedVersion,
        hasActive,
        'Remote manifest could not be parsed; keeping previous bundle.',
      );
    }

    final remoteVersion = remoteManifest.contentVersion;

    if (cachedVersion != null && cachedVersion == remoteVersion && hasActive) {
      return ContentSyncResult(
        status: ContentSyncStatus.upToDate,
        currentVersion: cachedVersion,
        previousVersion: cachedVersion,
      );
    }

    final rawFiles = <String, String>{manifestFile: remoteManifestRaw};
    try {
      for (final file in remoteManifest.files) {
        rawFiles[file.path] = await _remote.loadFile(file.path);
      }
    } catch (error) {
      if (error is ContentNotFoundException && error.statusCode == 404) {
        return _rejected(
          cachedVersion,
          hasActive,
          'Remote bundle is missing files; keeping previous bundle.',
        );
      }
      return _remoteFailed(cachedVersion, hasActive, error, remoteReached: true);
    }

    final validation = await _validator.validateRelease(
      manifest: remoteManifest,
      fileLoader: (path) async => rawFiles[path],
    );

    if (!validation.compatible) {
      return _rejected(
        cachedVersion,
        hasActive,
        'Remote bundle failed validation; keeping previous bundle.',
        validation: validation,
      );
    }

    try {
      await cache.stageRelease(version: remoteVersion, files: rawFiles);
      await cache.activateVersion(remoteVersion);
      await cache.clearStaging();
    } catch (error) {
      return _rejected(
        cachedVersion,
        hasActive,
        'Could not write the remote bundle to the cache: $error',
      );
    }

    return ContentSyncResult(
      status: hasActive
          ? ContentSyncStatus.updated
          : ContentSyncStatus.firstInstall,
      currentVersion: remoteVersion,
      previousVersion: cachedVersion,
    );
  }

  ContentSyncResult _rejected(
    String? cachedVersion,
    bool hasActive,
    String message, {
    ContentReleaseValidationResult? validation,
  }) {
    return ContentSyncResult(
      status: hasActive
          ? ContentSyncStatus.rejectedInvalidUpdate
          : ContentSyncStatus.failed,
      currentVersion: cachedVersion,
      previousVersion: cachedVersion,
      message: message,
      validation: validation,
    );
  }

  ContentSyncResult _remoteFailed(
    String? cachedVersion,
    bool hasActive,
    Object error, {
    required bool remoteReached,
  }) {
    if (hasActive) {
      return ContentSyncResult(
        status: ContentSyncStatus.offlineUsingCache,
        currentVersion: cachedVersion,
        previousVersion: cachedVersion,
        message: 'Remote ${remoteReached ? 'failed' : 'unreachable'}; '
            'using cached content ($error).',
      );
    }
    return ContentSyncResult(
      status: ContentSyncStatus.failed,
      message: 'Remote ${remoteReached ? 'failed' : 'unreachable'} and no '
          'cached content ($error).',
    );
  }
}
