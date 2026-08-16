import '../l10n/engine_strings.dart';
import '../models/bac_campaign.dart';
import '../models/concept_mastery.dart';

/// Pure campaign logic. No I/O, no AI: everything is derived from real
/// mastery data and the current date. Kept as a pure module so the
/// motivation layer can be unit-tested like the scoring engines.

/// Season bucket for a given time remaining until the BAC date.
/// Product heuristics, not official stages.
BacSeason seasonFor(Duration untilBac) {
  final days = untilBac.inDays;

  if (days <= 0) {
    return BacSeason.finalSprint;
  }

  if (days > 180) {
    return BacSeason.foundation;
  }

  if (days > 90) {
    return BacSeason.acceleration;
  }

  if (days > 30) {
    return BacSeason.examTraining;
  }

  return BacSeason.finalSprint;
}

/// Pure countdown data to the BAC date.
BacCountdown countdownFor({
  required DateTime bacDate,
  required DateTime today,
}) {
  final todayDay = DateTime(today.year, today.month, today.day);
  final bacDay = DateTime(bacDate.year, bacDate.month, bacDate.day);

  final days = bacDay.difference(todayDay).inDays;
  final passed = days < 0;
  final remaining = passed ? 0 : days;

  return BacCountdown(
    daysRemaining: remaining,
    weeksRemaining: remaining ~/ 7,
    hoursRemaining: remaining * 24,
    season: seasonFor(Duration(days: remaining)),
    passed: passed,
  );
}

/// Today's mission, generated from real mastery data.
///
/// The mission type rotates by day of week; the *content* (which concept to
/// fix) always comes from the student's actual weakest concept.
DailyMission missionFor({
  required DateTime today,
  required List<ConceptMastery> mastery,
  required DailyActivity activity,
  String languageCode = 'en',
}) {
  final weekday = today.weekday; // 1 = Monday .. 7 = Sunday

  switch (weekday) {
    case DateTime.monday:
      return _rescueMission(mastery, activity, languageCode);
    case DateTime.tuesday:
      return _speedMission(activity, languageCode);
    case DateTime.wednesday:
      return _memoryMission(activity, languageCode);
    case DateTime.thursday:
      return _bacExerciseMission(activity, languageCode);
    case DateTime.friday:
      return _precisionMission(activity, languageCode);
    case DateTime.saturday:
      return _bacChallengeMission(activity, languageCode);
    default:
      return _foundationMission(activity, languageCode);
  }
}

/// Calendar-day key (yyyy-MM-dd) used to track the day a mission was
/// completed and its XP awarded, so a mission is never rewarded twice.
String dateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// True when the mission is complete, has a reward, and XP has not already
/// been awarded on [todayKey]. This is what prevents double-awarding across
/// screen loads.
bool shouldAwardMissionXp({
  required DailyMission mission,
  required String? lastAwardedDate,
  required String todayKey,
}) {
  if (!mission.isComplete) {
    return false;
  }

  if (lastAwardedDate == todayKey) {
    return false;
  }

  return mission.rewardXp > 0;
}

/// The weakest attempted concept by accuracy (a documented heuristic —
/// "weakest" means lowest accuracy among concepts with at least one attempt).
ConceptMastery? weakestConcept(List<ConceptMastery> mastery) {
  final attempted = mastery.where((item) => item.attempts > 0).toList();

  if (attempted.isEmpty) {
    return null;
  }

  attempted.sort((a, b) => a.accuracy.compareTo(b.accuracy));

  return attempted.first;
}

/// Current streak: consecutive study days ending today, or ending yesterday
/// if today is not yet started (Duolingo-style grace). Longest: max run.
StreakInfo streakFor({
  required Set<DateTime> studyDays,
  required DateTime today,
}) {
  if (studyDays.isEmpty) {
    return StreakInfo.empty;
  }

  final days = studyDays
      .map((d) => DateTime(d.year, d.month, d.day))
      .toSet()
      .toList()
    ..sort();

  final todayDay = DateTime(today.year, today.month, today.day);

  int longest = 0;
  int run = 0;
  DateTime? previous;

  for (final day in days) {
    run = previous != null && day.difference(previous).inDays == 1
        ? run + 1
        : 1;
    previous = day;
    if (run > longest) {
      longest = run;
    }
  }

  final last = days.last;
  final yesterday = todayDay.subtract(const Duration(days: 1));

  var current = 0;

  if (last == todayDay || last == yesterday) {
    // The streak is alive if the last study day is today or yesterday.
    current = 0;
    run = 0;
    previous = null;

    for (final day in days) {
      if (day.isAfter(last)) {
        break;
      }
      run = previous != null && day.difference(previous).inDays == 1
          ? run + 1
          : 1;
      previous = day;
      current = run;
    }
  }

  return StreakInfo(current: current, longest: longest);
}

DailyMission _rescueMission(
  List<ConceptMastery> mastery,
  DailyActivity activity,
  String languageCode,
) {
  const target = 5;
  final weakest = weakestConcept(mastery);

  if (weakest == null) {
    return _foundationMission(activity, languageCode);
  }

  final progress = activity.attemptsOnConcept(weakest.conceptId);

  return DailyMission(
    type: DailyMissionType.rescue,
    title: missionTitle(DailyMissionType.rescue, languageCode),
    description: missionDescription(
      DailyMissionType.rescue,
      languageCode,
      target: target,
      conceptId: weakest.conceptId,
    ),
    progress: progress,
    target: target,
    conceptId: weakest.conceptId,
    rewardXp: 50,
    isComplete: progress >= target,
  );
}

DailyMission _speedMission(DailyActivity activity, String languageCode) {
  const target = 15;

  return DailyMission(
    type: DailyMissionType.speed,
    title: missionTitle(DailyMissionType.speed, languageCode),
    description:
        missionDescription(DailyMissionType.speed, languageCode, target: target),
    progress: activity.questionsToday,
    target: target,
    rewardXp: 40,
    isComplete: activity.questionsToday >= target,
  );
}

DailyMission _memoryMission(DailyActivity activity, String languageCode) {
  const target = 5;

  return DailyMission(
    type: DailyMissionType.memory,
    title: missionTitle(DailyMissionType.memory, languageCode),
    description: missionDescription(
        DailyMissionType.memory, languageCode, target: target),
    progress: activity.distinctConceptsToday,
    target: target,
    rewardXp: 45,
    isComplete: activity.distinctConceptsToday >= target,
  );
}

DailyMission _bacExerciseMission(DailyActivity activity, String languageCode) {
  const target = 1;

  return DailyMission(
    type: DailyMissionType.bacExercise,
    title: missionTitle(DailyMissionType.bacExercise, languageCode),
    description:
        missionDescription(DailyMissionType.bacExercise, languageCode,
            target: target),
    progress: activity.examCompletedToday ? 1 : 0,
    target: target,
    rewardXp: 80,
    isComplete: activity.examCompletedToday,
  );
}

DailyMission _precisionMission(DailyActivity activity, String languageCode) {
  const target = 6;
  final complete =
      activity.questionsToday >= target && activity.accuracyToday >= 0.85;

  return DailyMission(
    type: DailyMissionType.precision,
    title: missionTitle(DailyMissionType.precision, languageCode),
    description: missionDescription(DailyMissionType.precision, languageCode,
        target: target),
    progress: activity.questionsToday,
    target: target,
    rewardXp: 60,
    isComplete: complete,
  );
}

DailyMission _bacChallengeMission(DailyActivity activity, String languageCode) {
  const target = 1;

  return DailyMission(
    type: DailyMissionType.bacChallenge,
    title: missionTitle(DailyMissionType.bacChallenge, languageCode),
    description:
        missionDescription(DailyMissionType.bacChallenge, languageCode,
            target: target),
    progress: activity.examCompletedToday ? 1 : 0,
    target: target,
    rewardXp: 100,
    isComplete: activity.examCompletedToday,
  );
}

DailyMission _foundationMission(DailyActivity activity, String languageCode) {
  const target = 5;

  return DailyMission(
    type: DailyMissionType.foundation,
    title: missionTitle(DailyMissionType.foundation, languageCode),
    description: missionDescription(DailyMissionType.foundation, languageCode,
        target: target),
    progress: activity.questionsToday,
    target: target,
    rewardXp: 30,
    isComplete: activity.questionsToday >= target,
  );
}
