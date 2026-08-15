import '../data/achievement_engine.dart';
import '../data/achievement_repository.dart';
import '../data/bac_ranks.dart';
import '../data/content_repository.dart';
import '../data/levels_engine.dart';
import '../data/progress_repository.dart';
import '../data/streak_repository.dart';
import '../models/achievement.dart';
import '../models/level_info.dart';

/// Result of an achievement evaluation: what was just unlocked, whether the
/// reward pushed the student into a new level, and the updated level view.
class GamificationResult {
  /// Achievements that were just unlocked (null when none).
  final List<Achievement> newAchievements;

  /// Set when the student crossed into a new level.
  final LevelUpEvent? levelUp;

  final LevelInfo levelInfo;

  const GamificationResult({
    required this.newAchievements,
    required this.levelUp,
    required this.levelInfo,
  });

  bool get hasNewAchievements => newAchievements.isNotEmpty;
}

/// Coordinates XP, level, and achievement logic. Pure business logic — no
/// UI, no SQL. XP is the ONLY game currency; academic marks stay in the exam
/// attempt tables and are never mixed with XP.
class GamificationService {
  final ProgressRepository progressRepository;
  final StreakRepository streakRepository;
  final AchievementRepository achievementRepository;
  final ContentRepository contentRepository;

  GamificationService({
    required this.progressRepository,
    required this.streakRepository,
    required this.achievementRepository,
    required this.contentRepository,
  });

  /// Current level view (derived from total XP).
  Future<LevelInfo> getLevelInfo() async {
    final totalXp = await progressRepository.getTotalXp();
    return levelInfoFor(totalXp);
  }

  /// Current BAC rank (derived from level, never from academic score).
  Future<BacRankView> getRankView() async {
    final info = await getLevelInfo();
    return BacRankView.fromLevel(info.level);
  }

  /// Awards a chunk of XP through the existing ledger and reports whether it
  /// caused a level-up. Returns the new level view.
  Future<LevelInfo> awardXp({
    required int amount,
    required String reason,
  }) async {
    final before = await getLevelInfo();
    await progressRepository.addXp(reason: reason, amount: amount);
    return levelInfoFor(before.currentXp + amount);
  }

  /// Evaluates achievements after a completed activity. Every achievement
  /// that is now earned is persisted exactly once and its XP awarded once
  /// (through the `xp_events` ledger), then the level-up moment is detected.
  ///
  /// [extraXp] is the XP of the activity itself, so the level-up detection
  /// covers the full reward (activity XP + achievement XP) in one pass.
  Future<GamificationResult> evaluateAfterActivity({
    required CompletedActivity activity,
    int extraXp = 0,
  }) async {
    final stats = await _buildStats();
    final earned = evaluateAchievements(stats: stats, activity: activity);

    final unlocked = <Achievement>[];
    var newXp = extraXp;

    for (final achievement in earned) {
      final wasNew = await achievementRepository.unlock(achievement);
      if (wasNew) {
        unlocked.add(achievement);
        newXp += achievement.xpReward;
      }
    }

    final totalBefore = await progressRepository.getTotalXp();
    final levelBefore = levelFor(totalBefore);

    if (newXp > 0) {
      await progressRepository.addXp(
        reason: unlocked.isEmpty ? 'activity' : 'achievement',
        amount: newXp,
      );
    }

    final totalAfter = totalBefore + newXp;
    final levelAfter = levelFor(totalAfter);

    return GamificationResult(
      newAchievements: unlocked,
      levelUp: levelAfter > levelBefore
          ? LevelUpEvent(oldLevel: levelBefore, newLevel: levelAfter)
          : null,
      levelInfo: levelInfoFor(totalAfter),
    );
  }

  Future<StudentStats> _buildStats() async {
    final mastery = await progressRepository.getAllConceptMastery();
    final lessonToSubject = await _lessonToSubjectMap();
    final streakState = await streakRepository.getState();

    return StudentStats(
      questionsAnswered: await progressRepository.getTotalQuestionsAnswered(),
      quizzesCompleted: await progressRepository.getSavedLessonCount(),
      examsCompleted: await progressRepository.getExamsCompleted(),
      lessonsCompleted: await progressRepository.getSavedLessonCount(),
      currentStreak: streakState.currentStreak,
      longestStreak: streakState.longestStreak,
      mastery: mastery,
      lessonToSubject: lessonToSubject,
    );
  }

  Future<Map<String, String>> _lessonToSubjectMap() async {
    final map = <String, String>{};
    final subjects = await contentRepository.getSubjects();

    for (final subject in subjects) {
      final lessons = await contentRepository
          .getLessonsForSubject(subject.id);

      for (final lesson in lessons) {
        map[lesson.id] = subject.id;
      }
    }

    return map;
  }
}

/// A BAC rank plus its derived level info, bundled for display.
class BacRankView {
  final String title;
  final String subtitle;
  final int level;

  const BacRankView({
    required this.title,
    required this.subtitle,
    required this.level,
  });

  factory BacRankView.fromLevel(int level) {
    final rank = rankForLevel(level);
    return BacRankView(
      title: rank.title,
      subtitle: rank.subtitle,
      level: level,
    );
  }
}
