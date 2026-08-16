import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_algeria_bac/app/app_controller.dart';
import 'package:my_algeria_bac/app/app_scope.dart';
import 'package:my_algeria_bac/l10n/app_strings.dart';
import 'package:my_algeria_bac/models/student_profile.dart';

void main() {
  StudentProfile profile(String languageCode) => StudentProfile(
        stream: BacStream.experimentalSciences,
        bacYear: DateTime.now().year + 1,
        targetAverage: 14,
        languageCode: languageCode,
        dailyGoalMinutes: 45,
      );

  /// Renders the catalog string for [key] inside the app scope (real app
  /// wiring) or without it (standalone widget), returning the resolved text.
  Future<String> lookup(
    WidgetTester tester, {
    required String key,
    AppController? controller,
    List<Object?> args = const [],
  }) async {
    String? result;
    final home = Builder(
      builder: (context) {
        result = AppStrings.t(context, key, args: args);
        return const SizedBox.shrink();
      },
    );

    await tester.pumpWidget(
      controller == null
          ? MaterialApp(home: home)
          : AppScope(
              controller: controller,
              child: MaterialApp(home: home),
            ),
    );

    return result!;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('falls back to English without an app scope',
      (WidgetTester tester) async {
    expect(await lookup(tester, key: 'nav_home'), 'Home');
    expect(await lookup(tester, key: 'ready_for_bac'), 'Ready for BAC?');
    expect(await lookup(tester, key: 'unknown_key'), 'unknown_key');
  });

  testWidgets('resolves French when the profile prefers French',
      (WidgetTester tester) async {
    final controller = AppController();
    await controller.saveStudentProfile(profile('fr'));

    expect(await lookup(tester, key: 'nav_home', controller: controller),
        'Accueil');
    expect(await lookup(tester, key: 'ready_for_bac', controller: controller),
        'Prêt pour le BAC ?');
    controller.dispose();
  });

  testWidgets('resolves Arabic when the profile prefers Arabic',
      (WidgetTester tester) async {
    final controller = AppController();
    await controller.saveStudentProfile(profile('ar'));

    expect(await lookup(tester, key: 'nav_home', controller: controller),
        'الرئيسية');
    controller.dispose();
  });

  testWidgets('normalizes an unsupported profile language to Arabic',
      (WidgetTester tester) async {
    final controller = AppController();
    await controller.saveStudentProfile(profile('zz'));

    expect(controller.languageCode, 'ar');
    expect(await lookup(tester, key: 'nav_home', controller: controller),
        'الرئيسية');
    controller.dispose();
  });

  testWidgets('substitutes positional args in the resolved language',
      (WidgetTester tester) async {
    expect(
      await lookup(
        tester,
        key: 'minutes_per_day',
        args: [30],
      ),
      '30 minutes per day',
    );

    final controller = AppController();
    await controller.saveStudentProfile(profile('fr'));
    expect(
      await lookup(
        tester,
        key: 'minutes_per_day',
        args: [30],
        controller: controller,
      ),
      '30 minutes par jour',
    );
    controller.dispose();
  });
}
