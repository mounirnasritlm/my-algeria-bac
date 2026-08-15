/// Campaign phases across the school year, derived purely from the distance
/// to the BAC exam date. These are product heuristics, not official stages.
enum BacSeason {
  foundation,
  acceleration,
  examTraining,
  finalSprint;

  String get label => switch (this) {
        BacSeason.foundation => 'Foundation',
        BacSeason.acceleration => 'Acceleration',
        BacSeason.examTraining => 'Exam training',
        BacSeason.finalSprint => 'BAC final sprint',
      };
}

/// Pure countdown data to the BAC date.
class BacCountdown {
  final int daysRemaining;
  final int weeksRemaining;
  final int hoursRemaining;
  final BacSeason season;

  /// True when the configured BAC date is in the past.
  final bool passed;

  const BacCountdown({
    required this.daysRemaining,
    required this.weeksRemaining,
    required this.hoursRemaining,
    required this.season,
    required this.passed,
  });
}

/// Today's measurable study activity, derived from the attempt tables.
class DailyActivity {
  final int questionsToday;
  final int correctToday;

  /// conceptId -> number of attempts today on that concept.
  final Map<String, int> conceptAttemptsToday;

  final bool examCompletedToday;

  const DailyActivity({
    required this.questionsToday,
    required this.correctToday,
    required this.conceptAttemptsToday,
    required this.examCompletedToday,
  });

  static const DailyActivity empty = DailyActivity(
    questionsToday: 0,
    correctToday: 0,
    conceptAttemptsToday: {},
    examCompletedToday: false,
  );

  double get accuracyToday =>
      questionsToday == 0 ? 0 : correctToday / questionsToday;

  int get distinctConceptsToday => conceptAttemptsToday.length;

  int attemptsOnConcept(String conceptId) =>
      conceptAttemptsToday[conceptId] ?? 0;
}

/// The daily mission types.
enum DailyMissionType {
  rescue,
  speed,
  memory,
  bacExercise,
  precision,
  bacChallenge,
  foundation,
}

/// Today's mission, generated deterministically from real mastery data.
class DailyMission {
  final DailyMissionType type;

  final String title;

  final String description;

  final int progress;

  final int target;

  /// For [DailyMissionType.rescue]: the weakest concept to fix.
  final String? conceptId;

  /// XP awarded once when the mission completes (single accounting via the
  /// xp_events ledger, guarded by the completion date).
  final int rewardXp;

  final bool isComplete;

  const DailyMission({
    required this.type,
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
    this.conceptId,
    required this.rewardXp,
    required this.isComplete,
  });
}

/// Current and longest study streak derived from attempt days.
class StreakInfo {
  final int current;
  final int longest;

  const StreakInfo({required this.current, required this.longest});

  static const StreakInfo empty = StreakInfo(current: 0, longest: 0);
}
