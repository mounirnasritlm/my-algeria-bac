import '../data/progress_repository.dart';
import '../data/streak_engine.dart';
import '../data/streak_repository.dart';
import '../models/streak.dart';

/// The standard way every feature contributes to the student's learning
/// streak: record one completed activity, award its XP once.
class StreakService {
  final StreakRepository repository;
  final ProgressRepository progressRepository;

  StreakService({
    StreakRepository? repository,
    ProgressRepository? progressRepository,
  })  : repository = repository ?? StreakRepository(),
        progressRepository = progressRepository ?? ProgressRepository();

  /// Records a qualifying learning activity. Activities with no measurable
  /// time (`minutes <= 0`) are ignored — a flash answer is not a study day.
  ///
  /// Returns `true` when the activity was new and its XP was awarded.
  /// Duplicates (same `activityId`) are silently ignored so rebuilt screens
  /// or double taps cannot double-count.
  Future<bool> recordLearningActivity({
    required String activityId,
    required StreakActivityType type,
    required int minutes,
  }) async {
    if (minutes <= 0) {
      return false;
    }

    final xp = calculateStreakXp(type: type, minutes: minutes);

    final inserted = await repository.recordActivity(
      activityId: activityId,
      type: type,
      xpEarned: xp,
      minutes: minutes,
    );

    if (inserted) {
      await progressRepository.addXp(reason: 'streak', amount: xp);
    }

    return inserted;
  }
}
