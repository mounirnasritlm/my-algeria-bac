import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../config/content_config.dart';

/// On-device store for validated content releases.
///
/// Layout:
/// ```
/// <root>/
///   active/                 the release currently in use
///   staging/<version>/      a fully downloaded, verified release awaiting activation
///   _active_version.txt     version marker, written atomically
///   active_old/             the previous release during a swap
/// ```
///
/// A release is only ever promoted into `active/` by an atomic directory swap:
/// the staging directory is renamed into place and the previous `active/` is
/// dropped afterwards. A crash mid-activation never leaves a half-written
/// release readable as the active one. Individual files are also written
/// atomically (temp file, then rename) while staging.
///
/// In production the root lives under the app documents directory; tests
/// inject a plain directory so no plugin is needed.
class ContentReleaseCache {
  ContentReleaseCache({
    this.baseDirectory,
    String? cacheDirectoryName,
  }) : cacheDirectoryName =
            cacheDirectoryName ?? const ContentConfig().cacheDirectory;

  /// When null, the app documents directory is used (via path_provider).
  final String? baseDirectory;

  final String cacheDirectoryName;

  Future<String> _rootPath() async {
    final String basePath;
    if (baseDirectory != null) {
      basePath = baseDirectory!;
    } else {
      final docs = await getApplicationDocumentsDirectory();
      basePath = docs.path;
    }
    final root = Directory(p.join(basePath, cacheDirectoryName));
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root.path;
  }

  Future<String> _activePath() async {
    return p.join(await _rootPath(), 'active');
  }

  Future<String> _stagingPath(String version) async {
    if (version.isEmpty ||
        version.contains('/') ||
        version.contains('\\') ||
        version.contains('..')) {
      throw ArgumentError.value(version, 'version', 'unsafe release version');
    }
    return p.join(await _rootPath(), 'staging', version);
  }

  Future<String> _markerPath() async {
    return p.join(await _rootPath(), '_active_version.txt');
  }

  /// Version of the release currently in `active/`, or null when nothing has
  /// been activated yet.
  Future<String?> activeVersion() async {
    final marker = File(await _markerPath());
    if (!await marker.exists()) {
      return null;
    }
    return marker.readAsString();
  }

  /// Whether a validated release is present in `active/`.
  Future<bool> hasActive() async {
    return Directory(await _activePath()).exists();
  }

  /// Reads one file of the active release, or null when the file is absent.
  Future<String?> readActiveFile(String relativePath) async {
    final active = Directory(await _activePath());
    if (!await active.exists()) {
      return null;
    }
    final file = File(p.join(active.path, relativePath));
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  /// Writes a fully downloaded release into `staging/<version>`, replacing any
  /// previous staged release of the same version. Nothing is promoted to
  /// `active/` yet; call [activateVersion] once validation passes.
  Future<void> stageRelease({
    required String version,
    required Map<String, String> files,
  }) async {
    final staging = Directory(await _stagingPath(version));
    if (await staging.exists()) {
      await staging.delete(recursive: true);
    }
    await staging.create(recursive: true);

    for (final entry in files.entries) {
      await _writeStagedFile(staging, entry.key, entry.value);
    }
  }

  Future<void> _writeStagedFile(
    Directory staging,
    String relativePath,
    String content,
  ) async {
    final target = File(p.join(staging.path, relativePath));
    await target.parent.create(recursive: true);
    final temp = File('${target.path}.tmp');
    await temp.writeAsString(content, flush: true);
    await temp.rename(target.path);
  }

  /// Promotes the staged release of [version] into `active/` via an atomic
  /// directory swap, then removes the previously active release.
  ///
  /// Throws [StateError] when nothing was staged for [version]. If the swap
  /// itself fails, the previous release is restored and the error rethrown.
  Future<void> activateVersion(String version) async {
    final root = await _rootPath();
    final staging = Directory(await _stagingPath(version));
    final active = Directory(p.join(root, 'active'));
    final backup = Directory(p.join(root, 'active_old'));

    if (!await staging.exists()) {
      throw StateError('No staged release for version $version');
    }

    final marker = File(await _markerPath());
    final markerTemp = File(p.join(root, '_active_version.txt.tmp'));

    await markerTemp.writeAsString(version, flush: true);

    if (await backup.exists()) {
      await backup.delete(recursive: true);
    }
    if (await active.exists()) {
      await active.rename(backup.path);
    }

    try {
      await staging.rename(active.path);
    } catch (_) {
      if (await backup.exists() && !await active.exists()) {
        await backup.rename(active.path);
      }
      rethrow;
    }

    if (await marker.exists()) {
      await marker.delete();
    }
    await markerTemp.rename(marker.path);

    if (await backup.exists()) {
      await backup.delete(recursive: true);
    }
  }

  /// Deletes a directory tree, retrying briefly on transient failures
  /// (Windows can briefly hold file locks right after writes).
  Future<void> _deleteDirectory(Directory directory) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
        return;
      } on FileSystemException {
        if (attempt == 4) {
          rethrow;
        }
        await Future<void>.delayed(
          Duration(milliseconds: 50 * (attempt + 1)),
        );
      }
    }
  }

  /// Removes all staged (not yet activated) releases.
  Future<void> clearStaging() async {
    final staging = Directory(p.join(await _rootPath(), 'staging'));
    await _deleteDirectory(staging);
  }

  /// Deletes the whole cache root.
  Future<void> clear() async {
    final root = Directory(await _rootPath());
    await _deleteDirectory(root);
  }
}
