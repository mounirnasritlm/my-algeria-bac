// Study preferences screen: loads stored values, saves on demand, and keeps
// preferences separate from learning data.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_algeria_bac/data/study_preferences_repository.dart';
import 'package:my_algeria_bac/screens/study_settings_page.dart';

void main() {
  testWidgets('defaults load and saving persists the toggles',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: StudySettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text('45 minutes'), findsOneWidget);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Practice'));
    await tester.tap(find.widgetWithText(SwitchListTile, 'Weak points'));
    await tester.pump();

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Study preferences saved.'), findsOneWidget);

    final saved = await StudyPreferencesRepository().load();
    expect(saved.dailyMinutes, 45);
    expect(saved.includePractice, isFalse);
    expect(saved.includeWeakPoints, isFalse);
    expect(saved.includeLessons, isTrue);
  });

  testWidgets('stored values are shown when the screen opens',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'study_daily_minutes': 30,
      'study_include_practice': false,
    });

    await tester.pumpWidget(const MaterialApp(home: StudySettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text('30 minutes'), findsOneWidget);

    final practiceSwitch = tester.widget<Switch>(
      find.descendant(
        of: find.widgetWithText(SwitchListTile, 'Practice'),
        matching: find.byType(Switch),
      ),
    );
    expect(practiceSwitch.value, isFalse);
  });
}
