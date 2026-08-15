// Pure streak rules: XP per activity, daily qualification, and the
// current/longest streak calculations over qualifying days.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_algeria_bac/data/streak_engine.dart';
import 'package:my_algeria_bac/models/streak.dart';

void main() {
  DateTime day(int d) => DateTime(2026, 8, d);
  DateTime midnight(int d) => DateTime(2026, 8, d);

  group('calculateStreakXp', () {
    test('uses a base amount per type plus a time bonus', () {
      expect(
        calculateStreakXp(type: StreakActivityType.quiz, minutes: 10),
        19,
      );
      expect(
        calculateStreakXp(type: StreakActivityType.bacBoss, minutes: 30),
        42,
      );
      expect(
        calculateStreakXp(type: StreakActivityType.lesson, minutes: 5),
        12,
      );
      expect(
        calculateStreakXp(type: StreakActivityType.practice, minutes: 0),
        15,
      );
      expect(
        calculateStreakXp(type: StreakActivityType.studySession, minutes: 25),
        30,
      );
    });
  });

  group('qualifyingDays', () {
    test('keeps only days that reached the daily minimum', () {
      final minutesByDay = <DateTime, int>{
        midnight(10): 9,
        midnight(11): 10,
        midnight(12): 15,
      };

      final days = qualifyingDays(
        minutesByDay,
        minimumDailyMinutes: 10,
      );

      expect(days, {midnight(11), midnight(12)});
    });
  });

  group('calculateCurrentStreak', () {
    final now = day(15);

    test('empty history means no streak', () {
      expect(calculateCurrentStreak([], now), 0);
    });

    test('counts consecutive qualifying days ending today', () {
      expect(calculateCurrentStreak([day(13), day(14), day(15)], now), 3);
    });

    test('keeps the streak alive when the last day is yesterday', () {
      expect(calculateCurrentStreak([day(14)], now), 1);
      expect(calculateCurrentStreak([day(13), day(14)], now), 2);
    });

    test('breaks when the last qualifying day is older than yesterday', () {
      expect(calculateCurrentStreak([day(13)], now), 0);
    });

    test('resets after a gap', () {
      expect(calculateCurrentStreak([day(12), day(15)], now), 1);
      expect(calculateCurrentStreak([day(13), day(14), day(15)], now), 3);
    });
  });

  group('calculateLongestStreak', () {
    test('empty history means zero', () {
      expect(calculateLongestStreak([]), 0);
    });

    test('counts the longest consecutive run', () {
      expect(calculateLongestStreak([day(1), day(2), day(3), day(5), day(6)]), 3);
    });

    test('a single day is a streak of one', () {
      expect(calculateLongestStreak([day(1)]), 1);
    });
  });
}
