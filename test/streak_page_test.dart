// Streak screen: renders the hero, today's goal card, next milestone, and
// motivation, from the deterministic streak state.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_algeria_bac/data/streak_repository.dart';
import 'package:my_algeria_bac/models/streak.dart';
import 'package:my_algeria_bac/screens/streak_page.dart';

class _FakeStreakRepository extends StreakRepository {
  _FakeStreakRepository(this.state);

  final StreakState state;

  @override
  Future<StreakState> getState() async => state;
}

void main() {
  Widget page(StreakState state) {
    return MaterialApp(
      home: StreakPage(repository: _FakeStreakRepository(state)),
    );
  }

  testWidgets('shows an active streak for today', (tester) async {
    final state = StreakState(
      currentStreak: 3,
      longestStreak: 5,
      lastQualifyingDay: DateTime.now(),
      todayMinutes: 25,
      todayXp: 80,
    );

    await tester.pumpWidget(page(state));
    await tester.pumpAndSettle();

    expect(find.text('My Streak'), findsOneWidget);
    expect(find.text('🔥'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('DAY STREAK'), findsOneWidget);
    expect(find.text('Longest: 5 days'), findsOneWidget);
    expect(find.text('25 / 10 minutes'), findsOneWidget);
    expect(find.text('🔥 You kept your streak alive today.'), findsOneWidget);
    expect(find.text('7 consecutive study days'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Chaque jour compte.'), findsOneWidget);
  });

  testWidgets('shows the daily goal when today is not yet complete',
      (tester) async {
    final state = StreakState(
      currentStreak: 0,
      longestStreak: 0,
      lastQualifyingDay: null,
      todayMinutes: 4,
      todayXp: 10,
    );

    await tester.pumpWidget(page(state));
    await tester.pumpAndSettle();

    expect(find.text('0'), findsOneWidget);
    expect(find.text('4 / 10 minutes'), findsOneWidget);
    expect(
      find.text('Complete at least 10 minutes of real study activity.'),
      findsOneWidget,
    );
    expect(find.text('3 consecutive study days'), findsOneWidget);
  });
}
