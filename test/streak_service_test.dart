// StreakService: ignores zero-minute activity, records qualifying activity,
// computes XP, and awards it to the XP ledger exactly once per activity id.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_algeria_bac/data/progress_repository.dart';
import 'package:my_algeria_bac/data/streak_repository.dart';
import 'package:my_algeria_bac/models/streak.dart';
import 'package:my_algeria_bac/services/streak_service.dart';

class _FakeStreakRepository extends StreakRepository {
  final List<StreakActivity> recorded = [];
  bool inserted = true;

  @override
  Future<bool> recordActivity({
    required String activityId,
    required StreakActivityType type,
    required int xpEarned,
    required int minutes,
  }) async {
    if (inserted) {
      recorded.add(
        StreakActivity(
          id: activityId,
          type: type,
          completedAt: DateTime(2026, 8, 15),
          xpEarned: xpEarned,
          minutes: minutes,
        ),
      );
    }

    return inserted;
  }
}

class _FakeProgressRepository extends ProgressRepository {
  final List<int> awardedXp = [];

  @override
  Future<void> addXp({
    required String reason,
    required int amount,
  }) async {
    awardedXp.add(amount);
  }
}

void main() {
  late _FakeStreakRepository repository;
  late _FakeProgressRepository progress;
  late StreakService service;

  setUp(() {
    repository = _FakeStreakRepository();
    progress = _FakeProgressRepository();
    service = StreakService(
      repository: repository,
      progressRepository: progress,
    );
  });

  test('zero-minute activity is ignored entirely', () async {
    final result = await service.recordLearningActivity(
      activityId: 'quiz_1',
      type: StreakActivityType.quiz,
      minutes: 0,
    );

    expect(result, isFalse);
    expect(repository.recorded, isEmpty);
    expect(progress.awardedXp, isEmpty);
  });

  test('a new activity is recorded and its XP awarded once', () async {
    final result = await service.recordLearningActivity(
      activityId: 'quiz_1',
      type: StreakActivityType.quiz,
      minutes: 10,
    );

    expect(result, isTrue);
    expect(repository.recorded.single.id, 'quiz_1');
    expect(repository.recorded.single.xpEarned, 19);
    expect(progress.awardedXp, [19]);
  });

  test('a duplicate activity id is ignored and awards no XP', () async {
    repository.inserted = false;

    final result = await service.recordLearningActivity(
      activityId: 'bac_boss_s1',
      type: StreakActivityType.bacBoss,
      minutes: 120,
    );

    expect(result, isFalse);
    expect(repository.recorded, isEmpty);
    expect(progress.awardedXp, isEmpty);
  });

  test('BAC Boss awards more XP than a lesson', () async {
    await service.recordLearningActivity(
      activityId: 'bac_boss_s1',
      type: StreakActivityType.bacBoss,
      minutes: 120,
    );
    await service.recordLearningActivity(
      activityId: 'lesson_l1',
      type: StreakActivityType.lesson,
      minutes: 20,
    );

    expect(repository.recorded[0].xpEarned, 78);
    expect(repository.recorded[1].xpEarned, 18);
    expect(progress.awardedXp, [78, 18]);
  });
}
