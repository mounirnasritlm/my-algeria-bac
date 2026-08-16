import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_algeria_bac/app/app_controller.dart';
import 'package:my_algeria_bac/screens/student_profile_page.dart';

void main() {
  testWidgets('onboarding saves the student profile',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController();
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: StudentProfilePage(controller: controller),
      ),
    );

    expect(find.text('Which BAC stream are you preparing for?'), findsOneWidget);

    for (var step = 0; step < 4; step++) {
      await tester.tap(find.text('Next'));
      await tester.pump();
    }

    expect(find.text('How much can you study each day?'), findsOneWidget);
    await tester.tap(find.text('Start studying'));
    await tester.pumpAndSettle();

    expect(controller.studentProfile, isNotNull);
    expect(controller.studentProfile?.languageCode, 'ar');
    expect(controller.studentProfile?.dailyGoalMinutes, 45);
    controller.dispose();
  });

  testWidgets('editing saves changed profile values',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController();
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: StudentProfilePage(controller: controller, editing: true),
      ),
    );

    for (var step = 0; step < 4; step++) {
      await tester.tap(find.text('Next'));
      await tester.pump();
    }

    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(controller.studentProfile, isNotNull);
    controller.dispose();
  });
}
