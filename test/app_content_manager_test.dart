import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_algeria_bac/content/app_content_manager.dart';
import 'package:my_algeria_bac/content/content_release_cache.dart';
import 'package:my_algeria_bac/content/content_sync_result.dart';
import 'package:my_algeria_bac/data/json_content_repository.dart';

import 'helpers/demo_content_assets.dart';
import 'helpers/fake_asset_bundle.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('content_manager_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('falls back to the bundled assets when the cache is empty', () async {
    final manager = AppContentManager(
      assets: JsonContentRepository(
        assetBundle: FakeAssetBundle(demoContentAssets),
      ),
      cache: ContentReleaseCache(baseDirectory: tempDir.path),
    );

    final repository = await manager.activeRepository();

    expect(await repository.getContentVersion(), '0.1.0');
    expect((await manager.status()).usingCachedContent, isFalse);
  });

  test('prefers the cached bundle once it exists', () async {
    final cache = ContentReleaseCache(baseDirectory: tempDir.path);
    await cache.stageRelease(
      version: '9.9.9',
      files: _withVersion(_demoFiles(), '9.9.9'),
    );
    await cache.activateVersion('9.9.9');

    final manager = AppContentManager(
      assets: JsonContentRepository(
        assetBundle: FakeAssetBundle(demoContentAssets),
      ),
      cache: cache,
    );

    final repository = await manager.activeRepository();

    expect(await repository.getContentVersion(), '9.9.9');
    final status = await manager.status();
    expect(status.hasCachedContent, isTrue);
    expect(status.usingCachedContent, isTrue);
    expect(status.version, '9.9.9');
  });

  test('syncNow installs a healthy remote bundle end to end', () async {
    final files = _hashedDemoFiles();
    final client = MockClient((request) async {
      final path = request.url.pathSegments.last;
      return _jsonResponse(files[path]!);
    });

    final manager = AppContentManager(
      assets: JsonContentRepository(
        assetBundle: FakeAssetBundle(demoContentAssets),
      ),
      cache: ContentReleaseCache(baseDirectory: tempDir.path),
      httpClient: client,
    );

    final result = await manager.syncNow();

    expect(result.status, ContentSyncStatus.firstInstall);
    expect(result.currentVersion, '0.1.0');
    expect((await manager.status()).hasCachedContent, isTrue);
  });

  test('syncNow rejects a corrupt remote and keeps the cache', () async {
    final cache = ContentReleaseCache(baseDirectory: tempDir.path);
    await cache.stageRelease(
      version: '0.0.9',
      files: _withVersion(_demoFiles(), '0.0.9'),
    );
    await cache.activateVersion('0.0.9');

    final files = _hashedDemoFiles();
    files['subjects.json'] = files['subjects.json']!.replaceFirst(
      '"order": 1',
      '"order": 99',
    );

    final client = MockClient((request) async {
      final path = request.url.pathSegments.last;
      return _jsonResponse(files[path]!);
    });

    final manager = AppContentManager(
      assets: JsonContentRepository(
        assetBundle: FakeAssetBundle(demoContentAssets),
      ),
      cache: cache,
      httpClient: client,
    );

    final result = await manager.syncNow();

    expect(result.status, ContentSyncStatus.rejectedInvalidUpdate);
    expect(result.validation, isNotNull);
    expect(result.validation!.compatible, isFalse);
    expect(await cache.activeVersion(), '0.0.9');
    expect(await cache.readActiveFile('manifest.json'), contains('0.0.9'));
  });
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

/// Recomputes every digest in the manifest from the actual demo contents, so
/// hash verification passes for a healthy remote.
Map<String, String> _hashedDemoFiles() {
  final files = _demoFiles();
  final manifest = jsonDecode(files['manifest.json']!) as Map<String, dynamic>;

  final updated = <Map<String, dynamic>>[];
  for (final entry in manifest['files'] as List) {
    final file = Map<String, dynamic>.from(entry as Map);
    file['sha256'] = sha256
        .convert(utf8.encode(files[file['path'] as String]!))
        .toString();
    updated.add(file);
  }
  manifest['files'] = updated;
  files['manifest.json'] = jsonEncode(manifest);
  return files;
}

/// Wraps JSON in a response that decodes as UTF-8; the plain [http.Response]
/// constructor would latin-1 encode the body and choke on Arabic/emoji.
http.Response _jsonResponse(String body) {
  return http.Response(
    body,
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
