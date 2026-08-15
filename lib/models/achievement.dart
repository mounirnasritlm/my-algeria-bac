/// Types of achievements the app can award. Definitions and their XP rewards
/// live in `config/achievements.dart`; the unlock conditions live in
/// `data/achievement_engine.dart`.
enum AchievementType {
  firstLesson,
  firstQuiz,
  firstExam,
  questions100,
  questions500,
  streak3,
  streak7,
  streak30,
  perfectQuiz,
  physicsMaster,
  mathematicsMaster,
  scienceMaster,
}

/// A concrete, unlockable achievement. `subjectId` is only set for
/// subject-mastery achievements (physics/mathematics/science).
class Achievement {
  final AchievementType type;
  final String title;
  final String description;
  final String icon;

  /// XP awarded once when unlocked, through the `xp_events` ledger.
  final int xpReward;

  final String? subjectId;

  const Achievement({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
    this.subjectId,
  });
}
