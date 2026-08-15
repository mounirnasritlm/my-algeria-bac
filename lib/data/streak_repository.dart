import '../config/gamification_config.dart';
import '../models/streak.dart';
import 'app_database.dart';
import 'streak_engine.dart';

/// Persists streak-qualifying activities and derives the deterministic
/// [StreakState]. Best-effort like every persistence layer here: a failed
/// write must never break a study flow.
class StreakRepository {
  final ProgressDatabase _database;

  StreakRepository({
    ProgressDatabase? database,
  }) : _database = database ?? ProgressDatabase.instance;

  /// Records one completed activity. Returns `true` when the activity was
  /// actually new (the unique activity id was not seen before), which is the
  /// signal callers use to award XP exactly once.
  Future<bool> recordActivity({
    required String activityId,
    required StreakActivityType type,
    required int xpEarned,
    required int minutes,
  }) async {
    try {
      final db = await _database.database;

      final existing = await db.query(
        'streak_activities',
        columns: ['id'],
        where: 'activity_id = ?',
        whereArgs: [activityId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        return false;
      }

      await db.insert(
        'streak_activities',
        {
          'activity_id': activityId,
          'activity_type': type.name,
          'completed_at': DateTime.now().millisecondsSinceEpoch,
          'xp_earned': xpEarned,
          'minutes': minutes,
        },
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<StreakState> getState() async {
    try {
      final db = await _database.database;

      final rows = await db.query(
        'streak_activities',
        orderBy: 'completed_at ASC',
      );

      final now = DateTime.now();
      final todayDay = DateTime(now.year, now.month, now.day);

      var todayMinutes = 0;
      var todayXp = 0;
      final minutesByDay = <DateTime, int>{};

      for (final row in rows) {
        final completedAt = DateTime.fromMillisecondsSinceEpoch(
          (row['completed_at'] as num).toInt(),
        );
        final day = DateTime(completedAt.year, completedAt.month, completedAt.day);
        final minutes = (row['minutes'] as num).toInt();
        final xp = (row['xp_earned'] as num).toInt();

        minutesByDay[day] = (minutesByDay[day] ?? 0) + minutes;

        if (day == todayDay) {
          todayMinutes += minutes;
          todayXp += xp;
        }
      }

      final days = qualifyingDays(
        minutesByDay,
        minimumDailyMinutes: GamificationConfig.minimumDailyMinutes,
      ).toList()
        ..sort();

      return StreakState(
        currentStreak: calculateCurrentStreak(days, now),
        longestStreak: calculateLongestStreak(days),
        lastQualifyingDay: days.isEmpty ? null : days.last,
        todayMinutes: todayMinutes,
        todayXp: todayXp,
      );
    } catch (_) {
      return StreakState.empty();
    }
  }
}
