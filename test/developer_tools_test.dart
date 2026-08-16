// Developer tools panel: renders runtime state, storage version, and feature
// flags, and copies a diagnostics snapshot to the clipboard.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_algeria_bac/data/app_database.dart';
import 'package:my_algeria_bac/dev/developer_menu.dart';

void main() {
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
}
