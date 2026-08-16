import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_algeria_bac/app/app_controller.dart';
import 'package:my_algeria_bac/app/app_theme.dart';
import 'package:my_algeria_bac/screens/profile_page.dart';

void main() {
  testWidgets('appearance setting changes the active theme',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController();
    await controller.initialize();

    await tester.pumpWidget(
      AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: controller.themeMode,
            home: ProfilePage(appController: controller),
          );
        },
      ),
    );

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    expect(find.text('Dark'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(controller.themeMode, ThemeMode.dark);
    expect(find.text('Dark'), findsOneWidget);
    controller.dispose();
  });
}
