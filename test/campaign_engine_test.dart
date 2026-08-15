import 'package:flutter_test/flutter_test.dart';

import 'package:my_algeria_bac/data/campaign_engine.dart';
import 'package:my_algeria_bac/models/bac_campaign.dart';
import 'package:my_algeria_bac/models/concept_mastery.dart';

ConceptMastery mastery(String id, {int attempts = 0, int correct = 0}) {
  final accuracy = attempts == 0 ? 0.0 : correct / attempts;
  return ConceptMastery(
    conceptId: id,
    lessonId: 'lesson_$id',
    attempts: attempts,
    correct: correct,
    mastery: accuracy,
    accuracy: accuracy,
    status: masteryStatusFromAccuracy(accuracy, attempts),
    lastAttemptAt: null,
  );
}

void main() {
  group('seasonFor', () {
    test('buckets by months remaining', () {
      expect(seasonFor(const Duration(days: 200)), BacSeason.foundation);
      expect(seasonFor(const Duration(days: 100)), BacSeason.acceleration);
      expect(seasonFor(const Duration(days: 45)), BacSeason.examTraining);
      expect(seasonFor(const Duration(days: 20)), BacSeason.finalSprint);
      expect(seasonFor(const Duration(days: 0)), BacSeason.finalSprint);
      expect(seasonFor(const Duration(days: -5)), BacSeason.finalSprint);
    });
  });

  group('countdownFor', () {
    final bacDate = DateTime(2027, 6, 10);

    test('computes days, weeks, and hours', () {
      final countdown =
          countdownFor(bacDate: bacDate, today: DateTime(2026, 9, 1));

      expect(countdown.daysRemaining, 282); // Jun 10 2027 - Sep 1 2026
      expect(countdown.weeksRemaining, 40);
      expect(countdown.hoursRemaining, 282 * 24);
      expect(countdown.passed, isFalse);
    });

    test('handles a past date', () {
      final countdown =
          countdownFor(bacDate: bacDate, today: DateTime(2027, 7, 1));

      expect(countdown.passed, isTrue);
      expect(countdown.daysRemaining, 0);
      expect(countdown.season, BacSeason.finalSprint);
    });
  });

  group('weakestConcept', () {
    test('returns the lowest-accuracy attempted concept', () {
      final concepts = [
        mastery('a', attempts: 5, correct: 5),
        mastery('b', attempts: 5, correct: 1),
        mastery('c', attempts: 5, correct: 3),
      ];

      expect(weakestConcept(concepts)?.conceptId, 'b');
    });

    test('ignores un-attempted concepts', () {
      final concepts = [mastery('a'), mastery('b', attempts: 2, correct: 2)];

      expect(weakestConcept(concepts)?.conceptId, 'b');
    });

    test('returns null when nothing attempted', () {
      expect(weakestConcept([mastery('a'), mastery('b')]), isNull);
    });
  });

  group('streakFor', () {
    DateTime day(int month, int day) => DateTime(2026, month, day);

    test('returns empty for no study days', () {
      final streak = streakFor(studyDays: {}, today: day(1, 10));

      expect(streak.current, 0);
      expect(streak.longest, 0);
    });

    test('counts current consecutive days ending today', () {
      final streak = streakFor(
        studyDays: {
          day(1, 8),
          day(1, 9),
          day(1, 10),
        },
        today: day(1, 10),
      );

      expect(streak.current, 3);
      expect(streak.longest, 3);
    });

    test('keeps the streak alive when today not yet studied', () {
      final streak = streakFor(
        studyDays: {
          day(1, 8),
          day(1, 9),
        },
        today: day(1, 10),
      );

      expect(streak.current, 2);
    });

    test('resets when a day was skipped', () {
      final streak = streakFor(
        studyDays: {
          day(1, 7),
          day(1, 8),
          day(1, 10),
        },
        today: day(1, 10),
      );

      expect(streak.current, 1);
      expect(streak.longest, 2);
    });

    test('finds the longest run in the middle', () {
      final streak = streakFor(
        studyDays: {
          day(1, 1),
          day(1, 2),
          day(1, 3),
          day(1, 20),
        },
        today: day(1, 20),
      );

      expect(streak.current, 1);
      expect(streak.longest, 3);
    });
  });

  group('missionFor', () {
    test('Monday rescue targets the weakest concept', () {
      final mission = missionFor(
        today: DateTime(2026, 1, 5), // Monday
        mastery: [
          mastery('good', attempts: 5, correct: 5),
          mastery('weak', attempts: 5, correct: 1),
        ],
        activity: const DailyActivity(
          questionsToday: 0,
          correctToday: 0,
          conceptAttemptsToday: {},
          examCompletedToday: false,
        ),
      );

      expect(mission.type, DailyMissionType.rescue);
      expect(mission.conceptId, 'weak');
      expect(mission.isComplete, isFalse);
    });

    test('rescue completes after enough attempts on the weak concept', () {
      final mission = missionFor(
        today: DateTime(2026, 1, 5), // Monday
        mastery: [mastery('weak', attempts: 5, correct: 1)],
        activity: const DailyActivity(
          questionsToday: 5,
          correctToday: 2,
          conceptAttemptsToday: {'weak': 5},
          examCompletedToday: false,
        ),
      );

      expect(mission.isComplete, isTrue);
    });

    test('Tuesday is a speed mission', () {
      final mission = missionFor(
        today: DateTime(2026, 1, 6), // Tuesday
        mastery: const [],
        activity: const DailyActivity(
          questionsToday: 3,
          correctToday: 3,
          conceptAttemptsToday: {},
          examCompletedToday: false,
        ),
      );

      expect(mission.type, DailyMissionType.speed);
      expect(mission.progress, 3);
      expect(mission.target, 15);
    });

    test('Wednesday counts distinct concepts', () {
      final mission = missionFor(
        today: DateTime(2026, 1, 7), // Wednesday
        mastery: const [],
        activity: const DailyActivity(
          questionsToday: 10,
          correctToday: 8,
          conceptAttemptsToday: {'a': 3, 'b': 4, 'c': 3},
          examCompletedToday: false,
        ),
      );

      expect(mission.type, DailyMissionType.memory);
      expect(mission.progress, 3);
      expect(mission.target, 5);
    });

    test('Thursday completes with a timed exam', () {
      final mission = missionFor(
        today: DateTime(2026, 1, 8), // Thursday
        mastery: const [],
        activity: const DailyActivity(
          questionsToday: 0,
          correctToday: 0,
          conceptAttemptsToday: {},
          examCompletedToday: true,
        ),
      );

      expect(mission.type, DailyMissionType.bacExercise);
      expect(mission.isComplete, isTrue);
    });

    test('Friday precision requires accuracy too', () {
      final incomplete = missionFor(
        today: DateTime(2026, 1, 9), // Friday
        mastery: const [],
        activity: const DailyActivity(
          questionsToday: 6,
          correctToday: 3,
          conceptAttemptsToday: {},
          examCompletedToday: false,
        ),
      );

      expect(incomplete.type, DailyMissionType.precision);
      expect(incomplete.isComplete, isFalse);

      final complete = missionFor(
        today: DateTime(2026, 1, 9),
        mastery: const [],
        activity: const DailyActivity(
          questionsToday: 6,
          correctToday: 6,
          conceptAttemptsToday: {},
          examCompletedToday: false,
        ),
      );

      expect(complete.isComplete, isTrue);
    });

    test('Saturday is a full-exam challenge', () {
      final mission = missionFor(
        today: DateTime(2026, 1, 10), // Saturday
        mastery: const [],
        activity: const DailyActivity(
          questionsToday: 0,
          correctToday: 0,
          conceptAttemptsToday: {},
          examCompletedToday: false,
        ),
      );

      expect(mission.type, DailyMissionType.bacChallenge);
      expect(mission.isComplete, isFalse);
    });

    test('Sunday foundation with no data yet', () {
      final mission = missionFor(
        today: DateTime(2026, 1, 11), // Sunday
        mastery: const [],
        activity: DailyActivity.empty,
      );

      expect(mission.type, DailyMissionType.foundation);
      expect(mission.isComplete, isFalse);
    });
  });

  group('mission rewards', () {
    test('every mission type carries a positive XP reward', () {
      final saturday = DateTime(2026, 1, 10); // Saturday
      const emptyActivity = DailyActivity.empty;

      final missions = [
        missionFor(today: DateTime(2026, 1, 5), mastery: [], activity: emptyActivity),
        missionFor(today: DateTime(2026, 1, 6), mastery: [], activity: emptyActivity),
        missionFor(today: DateTime(2026, 1, 7), mastery: [], activity: emptyActivity),
        missionFor(today: DateTime(2026, 1, 8), mastery: [], activity: emptyActivity),
        missionFor(today: DateTime(2026, 1, 9), mastery: [], activity: emptyActivity),
        missionFor(today: saturday, mastery: [], activity: emptyActivity),
        missionFor(today: DateTime(2026, 1, 11), mastery: [], activity: emptyActivity),
      ];

      for (final mission in missions) {
        expect(mission.rewardXp, greaterThan(0),
            reason: '${mission.type} should reward XP');
      }
    });

    test('rescue rewards more than foundation', () {
      final rescue = missionFor(
        today: DateTime(2026, 1, 5), // Monday
        mastery: [mastery('weak', attempts: 2, correct: 0)],
        activity: DailyActivity.empty,
      );
      final foundation = missionFor(
        today: DateTime(2026, 1, 11), // Sunday
        mastery: const [],
        activity: DailyActivity.empty,
      );

      expect(rescue.rewardXp, greaterThan(foundation.rewardXp));
    });
  });

  group('dateKey', () {
    test('formats as yyyy-MM-dd with padding', () {
      expect(dateKey(DateTime(2026, 1, 5)), '2026-01-05');
      expect(dateKey(DateTime(2026, 12, 31)), '2026-12-31');
    });
  });

  group('shouldAwardMissionXp', () {
    DailyMission mission({int rewardXp = 50, bool isComplete = true}) {
      return DailyMission(
        type: DailyMissionType.foundation,
        title: 't',
        description: 'd',
        progress: isComplete ? 5 : 3,
        target: 5,
        rewardXp: rewardXp,
        isComplete: isComplete,
      );
    }

    test('refuses an incomplete mission', () {
      expect(
        shouldAwardMissionXp(
          mission: mission(isComplete: false),
          lastAwardedDate: null,
          todayKey: '2026-01-05',
        ),
        isFalse,
      );
    });

    test('awards a complete mission once', () {
      expect(
        shouldAwardMissionXp(
          mission: mission(),
          lastAwardedDate: null,
          todayKey: '2026-01-05',
        ),
        isTrue,
      );
    });

    test('does not re-award on the same day', () {
      expect(
        shouldAwardMissionXp(
          mission: mission(),
          lastAwardedDate: '2026-01-05',
          todayKey: '2026-01-05',
        ),
        isFalse,
      );
    });

    test('awards again on a new day', () {
      expect(
        shouldAwardMissionXp(
          mission: mission(),
          lastAwardedDate: '2026-01-04',
          todayKey: '2026-01-05',
        ),
        isTrue,
      );
    });

    test('refuses a zero-XP mission', () {
      expect(
        shouldAwardMissionXp(
          mission: mission(rewardXp: 0),
          lastAwardedDate: null,
          todayKey: '2026-01-05',
        ),
        isFalse,
      );
    });
  });
}
