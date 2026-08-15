/// 🔥 BAC Streak 2.0 models.
///
/// A streak day is earned by a real, completed learning activity — never by
/// opening the app. The streak itself is a deterministic calculation over the
/// recorded activity history (see streak_engine.dart).
enum StreakActivityType {
  lesson,
  quiz,
  practice,
  bacBoss,
  studySession,
}

class StreakActivity {
  final String id;
  final StreakActivityType type;
  final DateTime completedAt;
  final int xpEarned;
  final int minutes;

  const StreakActivity({
    required this.id,
    required this.type,
    required this.completedAt,
    required this.xpEarned,
    required this.minutes,
  });
}

class StreakState {
  final int currentStreak;
  final int longestStreak;

  /// The most recent calendar day that qualified for the streak, if any.
  final DateTime? lastQualifyingDay;

  final int todayMinutes;
  final int todayXp;

  const StreakState({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastQualifyingDay,
    required this.todayMinutes,
    required this.todayXp,
  });

  const StreakState.empty()
      : currentStreak = 0,
        longestStreak = 0,
        lastQualifyingDay = null,
        todayMinutes = 0,
        todayXp = 0;

  bool get completedToday {
    final last = lastQualifyingDay;
    if (last == null) {
      return false;
    }

    final now = DateTime.now();

    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }
}
