// Smoke test for the Study App shell.
//
// Verifies that the app boots, the Home shell renders its key sections,
// the bottom navigation switches tabs, and learning content loads from the
// content repository (in-memory fake assets).

import 'package:flutter_test/flutter_test.dart';

import 'package:my_algeria_bac/data/json_content_repository.dart';
import 'package:my_algeria_bac/main.dart';

import 'helpers/demo_content_assets.dart';
import 'helpers/fake_asset_bundle.dart';

void main() {
  testWidgets('App shell renders, navigates, and loads subjects',
      (WidgetTester tester) async {
    final repository = JsonContentRepository(
      assetBundle: FakeAssetBundle(demoContentAssets),
    );

    await tester.pumpWidget(StudyApp(contentRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Ready for BAC?'), findsOneWidget);
    expect(find.text('TODAY\'S MISSION'), findsOneWidget);

    await tester.tap(find.text('Learn'));
    await tester.pumpAndSettle();
    expect(
      find.text('Choose a subject to start learning.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Mathematics'));
    await tester.pumpAndSettle();
    expect(find.text('Learning path'), findsOneWidget);
    expect(find.text('Functions'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Ready for BAC?'), findsOneWidget);
  });
}
