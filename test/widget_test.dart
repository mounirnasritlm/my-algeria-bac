// Smoke test for the Study App shell.
//
// Verifies that the app boots, the Home shell renders its key sections,
// the bottom navigation switches tabs, and learning content loads from the
// content repository (in-memory fake assets).

import 'package:flutter/material.dart';
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

    expect(find.text('جاهز للبكالوريا؟'), findsOneWidget);
    expect(find.text('مهمة اليوم'), findsOneWidget);

    await tester.tap(find.text('تعلّم'));
    await tester.pumpAndSettle();
    expect(
      find.text('اختر مادة لبدء التعلّم.'),
      findsOneWidget,
    );

    await tester.tap(find.text('الرياضيات'));
    await tester.pumpAndSettle();
    expect(find.text('مسار التعلّم'), findsOneWidget);
    expect(find.text('الدوال'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('الرئيسية'));
    await tester.pumpAndSettle();
    expect(find.text('جاهز للبكالوريا؟'), findsOneWidget);
  });
}
