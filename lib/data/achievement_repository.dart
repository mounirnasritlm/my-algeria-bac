import '../config/achievements.dart';
import '../models/achievement.dart';
import 'app_database.dart';

/// Persists unlocked achievements. Best-effort like every persistence layer
/// here: a failed write must never break a study flow, and the unique
/// `type` column guarantees an achievement is awarded exactly once.
class AchievementRepository {
  final ProgressDatabase _database;

  AchievementRepository({
    ProgressDatabase? database,
  }) : _database = database ?? ProgressDatabase.instance;

  /// Persists one unlock. Returns `true` when it was genuinely new (the
  /// achievement was not already unlocked).
  Future<bool> unlock(Achievement achievement) async {
    try {
      return await _database.insertAchievement(
        type: achievement.type.name,
        title: achievement.title,
        description: achievement.description,
        icon: achievement.icon,
        xpReward: achievement.xpReward,
      );
    } catch (_) {
      return false;
    }
  }

  /// Every achievement ever unlocked, in unlock order.
  Future<List<Achievement>> getUnlocked() async {
    try {
      final rows = await _database.getAllAchievements();
      final unlocked = <Achievement>[];

      for (final row in rows) {
        final type = AchievementType.values
            .where((t) => t.name == row['type'])
            .firstOrNull;

        if (type == null) {
          continue;
        }

        final achievement = Achievements.forType(type);
        if (achievement != null) {
          unlocked.add(achievement);
        }
      }

      return unlocked;
    } catch (_) {
      return const [];
    }
  }

  /// Whether a specific achievement has been unlocked.
  Future<bool> isUnlocked(AchievementType type) async {
    final unlocked = await getUnlocked();
    return unlocked.any((achievement) => achievement.type == type);
  }
}
