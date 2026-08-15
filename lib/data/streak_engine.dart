/// Pure streak logic. No I/O: everything is derived from the recorded
/// qualifying days and the current date, so the rules are unit-testable.
library;

import '../models/streak.dart';

/// XP earned by one qualifying activity: a base amount per activity type plus
/// a small time bonus, so longer real study sessions are worth more.
int calculateStreakXp({
  required StreakActivityType type,
  required int minutes,
}) {
  final baseXp = switch (type) {
    StreakActivityType.lesson => 10,
    StreakActivityType.quiz => 15,
    StreakActivityType.practice => 15,
    StreakActivityType.bacBoss => 30,
    StreakActivityType.studySession => 20,
  };

  return baseXp + (minutes ~/ 5) * 2;
}

/// Calendar days (midnight) whose recorded minutes reached the daily goal.
/// A "study day" that matters for the streak must actually qualify.
Set<DateTime> qualifyingDays(
  Map<DateTime, int> minutesByDay, {
  required int minimumDailyMinutes,
}) {
  final days = <DateTime>{};

  for (final entry in minutesByDay.entries) {
    if (entry.value >= minimumDailyMinutes) {
      days.add(_day(entry.key));
    }
  }

  return days;
}

/// Current streak: consecutive qualifying days ending today — or ending
/// yesterday if today has not been started yet (grace day). Any earlier
/// qualifying day means the active streak is broken.
int calculateCurrentStreak(
  List<DateTime> qualifyingDays,
  DateTime now,
) {
  final days = _sortedUniqueDays(qualifyingDays);

  if (days.isEmpty) {
    return 0;
  }

  final today = _day(now);
  final yesterday = today.subtract(const Duration(days: 1));
  final last = days.last;

  if (last != today && last != yesterday) {
    return 0;
  }

  var streak = 1;
  for (var i = days.length - 1; i > 0; i--) {
    if (days[i].difference(days[i - 1]).inDays != 1) {
      break;
    }
    streak++;
  }

  return streak;
}

/// Longest consecutive run of qualifying days ever recorded.
int calculateLongestStreak(List<DateTime> qualifyingDays) {
  final days = _sortedUniqueDays(qualifyingDays);

  if (days.isEmpty) {
    return 0;
  }

  var longest = 1;
  var run = 1;

  for (var i = 1; i < days.length; i++) {
    if (days[i].difference(days[i - 1]).inDays == 1) {
      run++;
      if (run > longest) {
        longest = run;
      }
    } else {
      run = 1;
    }
  }

  return longest;
}

List<DateTime> _sortedUniqueDays(List<DateTime> days) {
  final unique = days.map(_day).toSet().toList()..sort();
  return unique;
}

DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);
