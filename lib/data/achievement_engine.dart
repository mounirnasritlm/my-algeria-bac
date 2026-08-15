/// 🏅 Pure achievement logic. No I/O: given a snapshot of real activity and
/// the just-completed activity, it returns every achievement the student now
/// qualifies for. Whether an achievement was ALREADY unlocked (and whether to
/// award its XP) is the caller's job — this engine never reads or writes.
library;

import '../config/achievements.dart';
import '../models/achievement.dart';
import '../models/concept_mastery.dart';

/// Snapshot of the student's real accumulated activity. Built by the service
/// from the progress repositories; the engine only reads it.
class StudentStats {
  /// Total questions ever answered.
  final int questionsAnswered;

  /// Number of completed quizzes (lesson quiz results saved).
  final int quizzesCompleted;

  /// Number of completed full BAC exams.
  final int examsCompleted;

  /// Number of lessons with a saved result.
  final int lessonsCompleted;

  /// Current day streak.
  final int currentStreak;

  /// Longest recorded streak.
  final int longestStreak;

  /// Recency-weighted mastery per concept.
  final List<ConceptMastery> mastery;

  /// lessonId -> subjectId, so subject achievements are derived from real
  /// mastery data instead of guessing.
  final Map<String, String> lessonToSubject;

  const StudentStats({
    required this.questionsAnswered,
    required this.quizzesCompleted,
    required this.examsCompleted,
    required this.lessonsCompleted,
    required this.currentStreak,
    required this.longestStreak,
    required this.mastery,
    required this.lessonToSubject,
  });
}

/// The activity that just finished, giving the engine event-level signals
/// (a perfect quiz, an exam subject) that accumulated stats cannot express.
class CompletedActivity {
  final AchievementActivityType type;
  final bool wasPerfect;

  /// Set for exam activities: the exam's subject id.
  final String? subjectId;

  const CompletedActivity({
    required this.type,
    required this.wasPerfect,
    this.subjectId,
  });
}

enum AchievementActivityType { lesson, quiz, exam }

/// The achievements the student qualifies for right now, in catalog order.
List<Achievement> evaluateAchievements({
  required StudentStats stats,
  required CompletedActivity activity,
}) {
  final unlocked = <AchievementType>[];

  if (stats.lessonsCompleted >= 1) {
    unlocked.add(AchievementType.firstLesson);
  }

  if (stats.quizzesCompleted >= 1) {
    unlocked.add(AchievementType.firstQuiz);
  }

  if (stats.examsCompleted >= 1) {
    unlocked.add(AchievementType.firstExam);
  }

  if (stats.questionsAnswered >= 100) {
    unlocked.add(AchievementType.questions100);
  }

  if (stats.questionsAnswered >= 500) {
    unlocked.add(AchievementType.questions500);
  }

  if (stats.currentStreak >= 3 || stats.longestStreak >= 3) {
    unlocked.add(AchievementType.streak3);
  }

  if (stats.currentStreak >= 7 || stats.longestStreak >= 7) {
    unlocked.add(AchievementType.streak7);
  }

  if (stats.currentStreak >= 30 || stats.longestStreak >= 30) {
    unlocked.add(AchievementType.streak30);
  }

  if (activity.type == AchievementActivityType.quiz && activity.wasPerfect) {
    unlocked.add(AchievementType.perfectQuiz);
  }

  for (final achievement in Achievements.all) {
    final subjectId = achievement.subjectId;
    if (subjectId == null) {
      continue;
    }

    if (_hasMasteredSubject(subjectId, stats)) {
      unlocked.add(achievement.type);
    }
  }

  return _inCatalogOrder(unlocked);
}

bool _hasMasteredSubject(String subjectId, StudentStats stats) {
  final lessonIds = <String>{
    for (final entry in stats.lessonToSubject.entries)
      if (entry.value == subjectId) entry.key,
  };

  for (final concept in stats.mastery) {
    if (!concept.isStrong) {
      continue;
    }
    if (lessonIds.contains(concept.lessonId)) {
      return true;
    }
  }

  return false;
}

List<Achievement> _inCatalogOrder(List<AchievementType> types) {
  return [
    for (final achievement in Achievements.all)
      if (types.contains(achievement.type)) achievement,
  ];
}
