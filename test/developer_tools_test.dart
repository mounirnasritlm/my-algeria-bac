// Developer tools panel: renders runtime state, storage version, and feature
// flags, and copies a diagnostics snapshot to the clipboard.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

import 'package:my_algeria_bac/content/app_content_manager.dart';
import 'package:my_algeria_bac/content/content_coordinator.dart';
import 'package:my_algeria_bac/content/content_release_cache.dart';
import 'package:my_algeria_bac/data/app_database.dart';
import 'package:my_algeria_bac/data/json_content_repository.dart';
import 'package:my_algeria_bac/dev/developer_menu.dart';

import 'helpers/demo_content_assets.dart';
import 'helpers/fake_asset_bundle.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('developer_menu_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  testWidgets('renders runtime, storage, and feature flag sections',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DeveloperMenu()),
    );

    expect(find.text('Developer tools'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Profile saved'), findsOneWidget);
    expect(find.text('Onboarding needed'), findsOneWidget);
    expect(find.text('DB schema version'), findsOneWidget);
    expect(
      find.text('${ProgressDatabase.databaseVersion}'),
      findsOneWidget,
    );
    expect(find.text('remoteContentSync'), findsOneWidget);
    expect(find.text('studyPreferences'), findsOneWidget);
    expect(find.text('developerTools'), findsOneWidget);
    expect(find.text('onboarding'), findsOneWidget);
    expect(find.text('true'), findsWidgets);
    expect(find.text('false'), findsWidgets);
    expect(find.text('Copy diagnostics'), findsOneWidget);
  });

  testWidgets('copy button writes diagnostics to the clipboard',
      (WidgetTester tester) async {
    final clipboard = <String, Object?>{};
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard['text'] = (call.arguments as Map)['text'];
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DeveloperMenu())),
    );

    await tester.ensureVisible(find.text('Copy diagnostics'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy diagnostics'));
    await tester.pump();

    final text = clipboard['text'] as String?;
    expect(text, isNotNull);
    expect(
      text,
      contains('DB schema version: ${ProgressDatabase.databaseVersion}'),
    );
    expect(text, contains('developerTools'));
  });

  testWidgets('content actions are disabled without a coordinator',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DeveloperMenu())),
    );

    await tester.ensureVisible(find.text('Force content sync'));
    await tester.tap(find.text('Force content sync'));
    await tester.pumpAndSettle();

    expect(find.text('Sync finished:'), findsNothing);
  });

  testWidgets('force content sync runs and reports the outcome',
      (WidgetTester tester) async {
    final coordinator = ContentCoordinator(
      manager: AppContentManager(
        assets: JsonContentRepository(
          assetBundle: FakeAssetBundle(demoContentAssets),
        ),
        cache: ContentReleaseCache(baseDirectory: tempDir.path),
        httpClient: MockClient((request) async {
          throw Exception('connection refused');
        }),
      ),
    );
    await tester.runAsync(() => coordinator.initialize());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeveloperMenu(coordinator: coordinator),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Force content sync'));
    await tester.tap(find.text('Force content sync'));
    await pumpUntilFound(tester, find.text('Sync finished: failed'));

    expect(find.text('Sync finished: failed'), findsOneWidget);
    expect(coordinator.lastSync?.status.name, 'failed');

    coordinator.dispose();
  });
}

// Pumps until [finder] matches or a bounded budget is exhausted. Alternates
// real async time (runAsync) with frame pumps so that pending real futures
// (file I/O) get a chance to resolve.
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
