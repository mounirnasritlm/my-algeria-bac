import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_algeria_bac/content/app_content_manager.dart';
import 'package:my_algeria_bac/content/content_coordinator.dart';
import 'package:my_algeria_bac/content/content_release_cache.dart';
import 'package:my_algeria_bac/data/app_database.dart';
import 'package:my_algeria_bac/data/json_content_repository.dart';
import 'package:my_algeria_bac/screens/home_page.dart';

import 'helpers/demo_content_assets.dart';
import 'helpers/fake_asset_bundle.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('home_page_banner_test');
    ProgressDatabase.resetForTesting();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // The banner renders coordinator state only, so the widget gets the
  // in-memory assets repository (whose I/O completes under FakeAsync) while
  // the coordinator reflects the real pipeline state.
  Widget buildHome(ContentCoordinator coordinator) {
    return MaterialApp(
      home: HomePage(
        contentRepository: JsonContentRepository(
          assetBundle: FakeAssetBundle(demoContentAssets),
        ),
        contentCoordinator: coordinator,
      ),
    );
  }

  // Pumps until [finder] matches or a bounded budget is exhausted. Alternates
  // real async time (runAsync) with frame pumps so that any pending real
  // futures (platform channel, DB) get a chance to resolve.
  Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
  }

  testWidgets('shows the offline banner when the remote is unreachable',
      (WidgetTester tester) async {
    final coordinator = _coordinator(tempDir, (request) async {
      throw Exception('connection refused');
    });

    // The pipeline does real file I/O, which hangs under the widget test's
    // FakeAsync zone; run it inside runAsync instead.
    await tester.runAsync(() async {
      await coordinator.initialize();
      await coordinator.syncNow();
    });

    await tester.pumpWidget(buildHome(coordinator));
    await pumpUntilFound(tester, find.text('Using bundled content'));

    expect(find.text('Using bundled content'), findsOneWidget);
  });

  testWidgets('shows the updated banner after a healthy remote install',
      (WidgetTester tester) async {
    final files = _hashedDemoFiles();
    final coordinator = _coordinator(tempDir, (request) async {
      final path = request.url.pathSegments.last;
      return _jsonResponse(files[path]!);
    });

    await tester.runAsync(() async {
      await coordinator.initialize();
      await coordinator.syncNow();
    });

    await tester.pumpWidget(buildHome(coordinator));
    await pumpUntilFound(tester, find.text('Content v0.1.0 downloaded'));

    expect(find.text('Content v0.1.0 downloaded'), findsOneWidget);
  });

  testWidgets('tapping the banner retries the sync',
      (WidgetTester tester) async {
    var calls = 0;
    final coordinator = _coordinator(tempDir, (request) async {
      calls++;
      throw Exception('connection refused');
    });

    await tester.runAsync(() async {
      await coordinator.initialize();
      await coordinator.syncNow();
    });

    await tester.pumpWidget(buildHome(coordinator));
    await pumpUntilFound(tester, find.text('Using bundled content'));

    // The retry sync touches the file system, so drive it inside runAsync and
    // wait for it to finish there.
    await tester.runAsync(() async {
      await tester.tap(find.text('Using bundled content'));
      await tester.pump();
      while (coordinator.syncing) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await pumpUntilFound(tester, find.text('Using bundled content'));

    expect(calls, greaterThanOrEqualTo(2));
  });
}

ContentCoordinator _coordinator(
  Directory tempDir,
  Future<http.Response> Function(http.Request) handler,
) {
  return ContentCoordinator(
    manager: AppContentManager(
      assets: JsonContentRepository(
        assetBundle: FakeAssetBundle(demoContentAssets),
      ),
      cache: ContentReleaseCache(baseDirectory: tempDir.path),
      httpClient: MockClient(handler),
    ),
  );
}

/// Recomputes every digest in the manifest from the actual demo contents.
Map<String, String> _hashedDemoFiles() {
  final files = <String, String>{
    for (final entry in demoContentAssets.entries)
      if (entry.key.startsWith('assets/content/'))
        entry.key.replaceFirst('assets/content/', ''): entry.value,
  };
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
