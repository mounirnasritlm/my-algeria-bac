import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_algeria_bac/content/app_content_manager.dart';
import 'package:my_algeria_bac/content/content_coordinator.dart';
import 'package:my_algeria_bac/content/content_release_cache.dart';
import 'package:my_algeria_bac/data/json_content_repository.dart';
import 'package:my_algeria_bac/l10n/app_strings.dart';
import 'package:my_algeria_bac/screens/content_settings_page.dart';

import 'helpers/demo_content_assets.dart';
import 'helpers/fake_asset_bundle.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('content_settings_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<ContentCoordinator> coordinatorWith(
    WidgetTester tester, {
    http.Client? httpClient,
    ContentReleaseCache? cache,
  }) async {
    final coordinator = ContentCoordinator(
      manager: AppContentManager(
        assets: JsonContentRepository(
          assetBundle: FakeAssetBundle(demoContentAssets),
        ),
        cache: cache ?? ContentReleaseCache(baseDirectory: tempDir.path),
        httpClient: httpClient,
      ),
    );
    // The pipeline does real file I/O, which hangs under the widget test's
    // FakeAsync zone; run it inside runAsync instead.
    await tester.runAsync(() => coordinator.initialize());
    return coordinator;
  }

  http.Client failingClient() {
    return MockClient((request) async {
      throw Exception('connection refused');
    });
  }

  // Pumps until [finder] matches or a bounded budget is exhausted. Alternates
  // real async time (runAsync) with frame pumps so that any pending real
  // futures (file I/O) get a chance to resolve.
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

  testWidgets('shows bundled version and source when the cache is empty',
      (WidgetTester tester) async {
    final coordinator = await coordinatorWith(tester, httpClient: failingClient());

    await tester.pumpWidget(
      MaterialApp(home: ContentSettingsPage(coordinator: coordinator)),
    );
    await pumpUntilFound(tester, find.text('0.1.0'));

    final context = tester.element(find.byType(ContentSettingsPage));
    expect(
        find.text(AppStrings.t(context, 'content_version')), findsOneWidget);
    expect(find.text('0.1.0'), findsOneWidget);
    expect(find.text(AppStrings.t(context, 'content_source_bundled')),
        findsOneWidget);
    expect(find.text(AppStrings.t(context, 'content_never_checked')),
        findsOneWidget);
  });

  testWidgets('shows cached version and source when a release is active',
      (WidgetTester tester) async {
    final cache = ContentReleaseCache(baseDirectory: tempDir.path);
    await tester.runAsync(() async {
      await cache.stageRelease(version: '0.0.9', files: _demoFiles());
      await cache.activateVersion('0.0.9');
    });

    final coordinator =
        await coordinatorWith(tester, httpClient: failingClient(), cache: cache);

    await tester.pumpWidget(
      MaterialApp(home: ContentSettingsPage(coordinator: coordinator)),
    );
    await pumpUntilFound(tester, find.text('0.0.9'));

    final context = tester.element(find.byType(ContentSettingsPage));
    expect(find.text('0.0.9'), findsOneWidget);
    expect(find.text(AppStrings.t(context, 'content_source_cached')),
        findsOneWidget);
  });

  testWidgets('tapping check for updates surfaces the sync outcome',
      (WidgetTester tester) async {
    final coordinator = await coordinatorWith(tester, httpClient: failingClient());

    await tester.pumpWidget(
      MaterialApp(home: ContentSettingsPage(coordinator: coordinator)),
    );
    await pumpUntilFound(tester, find.byType(ContentSettingsPage));

    final context = tester.element(find.byType(ContentSettingsPage));
    await tester
        .tap(find.text(AppStrings.t(context, 'content_check_updates')));
    await pumpUntilFound(
        tester, find.text(AppStrings.t(context, 'content_sync_failed')));

    expect(find.text(AppStrings.t(context, 'content_sync_failed')),
        findsOneWidget);
    expect(find.text(AppStrings.t(context, 'content_never_checked')),
        findsNothing);
  });

  testWidgets('clearing the cache falls back to bundled content',
      (WidgetTester tester) async {
    final cache = ContentReleaseCache(baseDirectory: tempDir.path);
    await tester.runAsync(() async {
      await cache.stageRelease(version: '0.0.9', files: _demoFiles());
      await cache.activateVersion('0.0.9');
    });

    final coordinator =
        await coordinatorWith(tester, httpClient: failingClient(), cache: cache);

    await tester.pumpWidget(
      MaterialApp(home: ContentSettingsPage(coordinator: coordinator)),
    );
    await pumpUntilFound(tester, find.text('0.0.9'));

    final context = tester.element(find.byType(ContentSettingsPage));
    await tester.tap(find.text(AppStrings.t(context, 'content_clear_cache')));
    await tester.pump();
    await tester.tap(find.widgetWithText(
      FilledButton,
      AppStrings.t(context, 'content_clear_cache'),
    ));
    await pumpUntilFound(
        tester, find.text(AppStrings.t(context, 'content_cleared')));

    expect(find.text(AppStrings.t(context, 'content_cleared')), findsOneWidget);
    expect(find.text('0.1.0'), findsOneWidget);
    expect(find.text(AppStrings.t(context, 'content_source_bundled')),
        findsOneWidget);
  });
}

/// The content files as read from `assets/content/`, keyed by relative path.
Map<String, String> _demoFiles() {
  return {
    for (final entry in demoContentAssets.entries)
      if (entry.key.startsWith('assets/content/'))
        entry.key.replaceFirst('assets/content/', ''): entry.value,
  };
}
