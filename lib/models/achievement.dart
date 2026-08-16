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
///
/// `title`/`description` are the base (English) copy kept for tests and
/// persistence; the per-language overrides in `titles`/`descriptions` let the
/// UI render the active language through [titleForLanguage].
class Achievement {
  final AchievementType type;
  final String title;
  final String description;
  final String icon;

  /// Per-language title overrides, keyed by language code.
  final Map<String, String> titles;

  /// Per-language description overrides, keyed by language code.
  final Map<String, String> descriptions;

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
    this.titles = const {},
    this.descriptions = const {},
  });

  String titleForLanguage(String languageCode) {
    return titles[languageCode] ?? title;
  }

  String descriptionForLanguage(String languageCode) {
    return descriptions[languageCode] ?? description;
  }
}
