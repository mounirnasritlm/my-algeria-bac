import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_algeria_bac/content/content_loader.dart';
import 'package:my_algeria_bac/content/content_release_cache.dart';
import 'package:my_algeria_bac/content/content_sync_result.dart';
import 'package:my_algeria_bac/content/content_sync_service.dart';

import 'helpers/demo_content_assets.dart';

void main() {
  late Directory tempDir;
  late _FakeRemote remote;
  late ContentReleaseCache cache;
  late ContentSyncService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('content_sync_test');
    remote = _FakeRemote(_hashedFiles(_withVersion(_demoFiles(), '0.1.0')));
    cache = ContentReleaseCache(baseDirectory: tempDir.path);
    service = ContentSyncService(remoteLoader: remote, cache: cache);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('first install downloads, verifies and activates the bundle', () async {
    final result = await service.sync();

    expect(result.status, ContentSyncStatus.firstInstall);
    expect(result.currentVersion, '0.1.0');
    expect(result.previousVersion, isNull);
    expect(await cache.hasActive(), isTrue);
    expect(await cache.readActiveFile('manifest.json'), _hasVersion('0.1.0'));
    expect(await cache.readActiveFile('subjects.json'), isNotNull);
    expect(await cache.readActiveFile('questions.json'), isNotNull);
  });

  test('up-to-date cache is left untouched', () async {
    await cache.stageRelease(version: '0.1.0', files: remote.files);
    await cache.activateVersion('0.1.0');

    final result = await service.sync();

    expect(result.status, ContentSyncStatus.upToDate);
    expect(result.currentVersion, '0.1.0');
    expect(await cache.readActiveFile('manifest.json'), _hasVersion('0.1.0'));
  });

  test('a newer remote bundle replaces the cached one', () async {
    await cache.stageRelease(
      version: '0.0.9',
      files: _hashedFiles(_withVersion(_demoFiles(), '0.0.9')),
    );
    await cache.activateVersion('0.0.9');
    remote.files = _hashedFiles(_withVersion(_demoFiles(), '0.1.0'));

    final result = await service.sync();

    expect(result.status, ContentSyncStatus.updated);
    expect(result.previousVersion, '0.0.9');
    expect(result.currentVersion, '0.1.0');
    expect(await cache.activeVersion(), '0.1.0');
    expect(await cache.readActiveFile('manifest.json'), _hasVersion('0.1.0'));
  });

  test('an unreachable remote keeps the previous release', () async {
    await cache.stageRelease(
      version: '0.0.9',
      files: _hashedFiles(_withVersion(_demoFiles(), '0.0.9')),
    );
    await cache.activateVersion('0.0.9');
    remote.failWith = const SocketException('no network');

    final result = await service.sync();

    expect(result.status, ContentSyncStatus.offlineUsingCache);
    expect(result.currentVersion, '0.0.9');
    expect(await cache.activeVersion(), '0.0.9');
  });

  test('a corrupt remote update is rejected and the previous release is kept',
      () async {
    await cache.stageRelease(
      version: '0.0.9',
      files: _hashedFiles(_withVersion(_demoFiles(), '0.0.9')),
    );
    await cache.activateVersion('0.0.9');
    remote.files = _corrupted(_hashedFiles(_withVersion(_demoFiles(), '0.1.0')));

    final result = await service.sync();

    expect(result.status, ContentSyncStatus.rejectedInvalidUpdate);
    expect(result.validation, isNotNull);
    expect(result.validation!.compatible, isFalse);
    expect(result.previousVersion, '0.0.9');
    expect(await cache.activeVersion(), '0.0.9');
    expect(await cache.readActiveFile('manifest.json'), _hasVersion('0.0.9'));
  });

  test('a schema-incompatible remote bundle is rejected', () async {
    remote.files = _withSchemaVersion(
      _hashedFiles(_withVersion(_demoFiles(), '0.2.0')),
      '2.0.0',
    );

    final result = await service.sync();

    expect(result.status, ContentSyncStatus.failed);
    expect(result.validation, isNotNull);
    expect(result.validation!.compatible, isFalse);
    expect(await cache.hasActive(), isFalse);
  });

  test('a missing required file on first install is rejected', () async {
    final files = _hashedFiles(_withVersion(_demoFiles(), '0.1.0'));
    files.remove('subjects.json');
    remote.files = files;

    final result = await service.sync();

    expect(result.status, ContentSyncStatus.failed);
    expect(await cache.hasActive(), isFalse);
  });

  test('a failed first install reports failed', () async {
    remote.failWith = const SocketException('no network');

    final result = await service.sync();

    expect(result.status, ContentSyncStatus.failed);
    expect(await cache.hasActive(), isFalse);
  });
}

Matcher _hasVersion(String version) {
  return predicate<String>(
    (raw) {
      final manifest = jsonDecode(raw) as Map<String, dynamic>;
      return manifest['contentVersion'] == version;
    },
    'content version $version',
  );
}

/// Builds the demo bundle keyed by content-relative paths.
Map<String, String> _demoFiles() {
  return {
    for (final entry in demoContentAssets.entries)
      if (entry.key.startsWith('assets/content/'))
        entry.key.replaceFirst('assets/content/', ''): entry.value,
  };
}

/// Returns a copy of [files] whose manifest reports [version].
Map<String, String> _withVersion(Map<String, String> files, String version) {
  final clone = Map<String, String>.from(files);
  final manifest = jsonDecode(clone['manifest.json']!) as Map<String, dynamic>;
  manifest['contentVersion'] = version;
  clone['manifest.json'] = jsonEncode(manifest);
  return clone;
}

/// Returns a copy of [files] whose manifest reports [schemaVersion].
Map<String, String> _withSchemaVersion(
    Map<String, String> files, String schemaVersion) {
  final clone = Map<String, String>.from(files);
  final manifest = jsonDecode(clone['manifest.json']!) as Map<String, dynamic>;
  manifest['schemaVersion'] = schemaVersion;
  clone['manifest.json'] = jsonEncode(manifest);
  return clone;
}

/// Recomputes every digest in the manifest from the actual file contents, so
/// hash verification passes for a valid bundle.
Map<String, String> _hashedFiles(Map<String, String> files) {
  final clone = Map<String, String>.from(files);
  final manifest = jsonDecode(clone['manifest.json']!) as Map<String, dynamic>;

  final updated = <Map<String, dynamic>>[];
  for (final entry in manifest['files'] as List) {
    final file = Map<String, dynamic>.from(entry as Map);
    file['sha256'] = sha256
        .convert(utf8.encode(clone[file['path'] as String]!))
        .toString();
    updated.add(file);
  }
  manifest['files'] = updated;
  clone['manifest.json'] = jsonEncode(manifest);
  return clone;
}

/// Returns a copy of [files] where one file's bytes no longer match its
/// declared digest.
Map<String, String> _corrupted(Map<String, String> files) {
  final clone = Map<String, String>.from(files);
  clone['subjects.json'] = clone['subjects.json']!.replaceFirst(
    '"order": 1',
    '"order": 99',
  );
  return clone;
}

class _FakeRemote implements ContentLoader {
  _FakeRemote(this.files);

  Map<String, String> files;

  Object? failWith;

  @override
  Future<bool> exists(String path) async {
    final failure = failWith;
    if (failure != null) {
      throw failure;
    }
    return files.containsKey(path);
  }

  @override
  Future<String> loadFile(String path) async {
    final failure = failWith;
    if (failure != null) {
      throw failure;
    }
    final content = files[path];
    if (content == null) {
      throw ContentNotFoundException(path);
    }
    return content;
  }
}
