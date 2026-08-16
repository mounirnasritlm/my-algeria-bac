import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_algeria_bac/content/app_content_manager.dart';
import 'package:my_algeria_bac/content/content_coordinator.dart';
import 'package:my_algeria_bac/content/content_release_cache.dart';
import 'package:my_algeria_bac/content/content_sync_result.dart';
import 'package:my_algeria_bac/data/json_content_repository.dart';

import 'helpers/demo_content_assets.dart';
import 'helpers/fake_asset_bundle.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('content_coordinator_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  AppContentManager manager({
    http.Client? httpClient,
    ContentReleaseCache? cache,
  }) {
    return AppContentManager(
      assets: JsonContentRepository(
        assetBundle: FakeAssetBundle(demoContentAssets),
      ),
      cache: cache ?? ContentReleaseCache(baseDirectory: tempDir.path),
      httpClient: httpClient,
    );
  }

  test('initialize falls back to bundled assets when the cache is empty',
      () async {
    final coordinator = ContentCoordinator(manager: manager());

    await coordinator.initialize();

    expect(coordinator.repository, isNotNull);
    expect(await coordinator.repository.getContentVersion(), '0.1.0');
    expect(coordinator.status?.usingCachedContent, isFalse);
    expect(coordinator.lastSync, isNull);
    expect(coordinator.syncing, isFalse);
  });

  test('syncNow installs a healthy remote and notifies listeners twice',
      () async {
    final files = _hashedDemoFiles();
    final client = MockClient((request) async {
      final path = request.url.pathSegments.last;
      return _jsonResponse(files[path]!);
    });

    final coordinator = ContentCoordinator(manager: manager(httpClient: client));
    await coordinator.initialize();

    var notifications = 0;
    coordinator.addListener(() => notifications++);

    final result = await coordinator.syncNow();

    expect(result.status, ContentSyncStatus.firstInstall);
    expect(result.currentVersion, '0.1.0');
    expect(coordinator.lastSync?.status, ContentSyncStatus.firstInstall);
    expect(coordinator.status?.hasCachedContent, isTrue);
    expect(coordinator.status?.usingCachedContent, isTrue);
    expect(coordinator.status?.version, '0.1.0');
    expect(coordinator.syncing, isFalse);
    // syncing=true then final false + repository/status swap.
    expect(notifications, greaterThanOrEqualTo(2));
  });

  test('syncNow reports failed when the remote is unreachable', () async {
    final client = MockClient((request) async {
      throw Exception('connection refused');
    });

    final coordinator = ContentCoordinator(manager: manager(httpClient: client));
    await coordinator.initialize();

    final result = await coordinator.syncNow();

    expect(result.status, ContentSyncStatus.failed);
    expect(coordinator.lastSync?.status, ContentSyncStatus.failed);
    expect(coordinator.status?.hasCachedContent, isFalse);
    expect(coordinator.status?.usingCachedContent, isFalse);
  });

  test('syncNow keeps the previous cache when the remote bundle is rejected',
      () async {
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

    final coordinator =
        ContentCoordinator(manager: manager(httpClient: client, cache: cache));
    await coordinator.initialize();

    final result = await coordinator.syncNow();

    expect(result.status, ContentSyncStatus.rejectedInvalidUpdate);
    expect(coordinator.status?.usingCachedContent, isTrue);
    expect(coordinator.status?.version, '0.0.9');
    expect(await cache.activeVersion(), '0.0.9');
  });

  test('a second sync while one is running is ignored', () async {
    final files = _hashedDemoFiles();
    final client = MockClient((request) async {
      final path = request.url.pathSegments.last;
      return _jsonResponse(files[path]!);
    });

    final coordinator = ContentCoordinator(manager: manager(httpClient: client));
    await coordinator.initialize();

    final first = coordinator.syncNow();
    final second = coordinator.syncNow();

    final firstResult = await first;
    final secondResult = await second;

    expect(firstResult.status, ContentSyncStatus.firstInstall);
    expect(secondResult.status, ContentSyncStatus.firstInstall);
  });

  test('notifyListeners after dispose is safe', () async {
    final client = MockClient((request) async {
      throw Exception('connection refused');
    });

    final coordinator =
        ContentCoordinator(manager: manager(httpClient: client));
    await coordinator.initialize();

    coordinator.dispose();

    await coordinator.syncNow();
    expect(coordinator.lastSync?.status, ContentSyncStatus.failed);
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

/// Recomputes every digest in the manifest from the actual demo contents.
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

/// Wraps JSON in a response that decodes as UTF-8.
http.Response _jsonResponse(String body) {
  return http.Response(
    body,
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
