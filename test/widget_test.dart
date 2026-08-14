// Smoke test for the MY Algeria BAC app shell.
//
// Verifies that the app boots and the Home shell renders its key sections,
// and that the bottom navigation switches between tabs.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_algeria_bac/main.dart';

void main() {
  testWidgets('App shell renders and navigates', (WidgetTester tester) async {
    await tester.pumpWidget(const MyAlgeriaBacApp());

    expect(find.text('Ready for BAC?'), findsOneWidget);
    expect(find.text('TODAY\'S MISSION'), findsOneWidget);

    await tester.tap(find.text('Learn'));
    await tester.pumpAndSettle();
    expect(find.text('Your BAC learning path will live here.'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Ready for BAC?'), findsOneWidget);
  });
}
