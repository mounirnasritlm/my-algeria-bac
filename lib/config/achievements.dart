import '../models/achievement.dart';

/// Authoritative achievement catalog. Every achievement is defined once here
/// with its title, description, icon, and one-time XP reward. The unlock
/// CONDITIONS are evaluated by `data/achievement_engine.dart` from real
/// activity — no random or fabricated unlocks.
class Achievements {
  const Achievements._();

  static const Achievement firstLesson = Achievement(
    type: AchievementType.firstLesson,
    title: 'First Step',
    description: 'Complete your first lesson quiz.',
    icon: '📚',
    xpReward: 25,
  );

  static const Achievement firstQuiz = Achievement(
    type: AchievementType.firstQuiz,
    title: 'Quiz Started',
    description: 'Complete your first quiz.',
    icon: '🧠',
    xpReward: 25,
  );

  static const Achievement firstExam = Achievement(
    type: AchievementType.firstExam,
    title: 'BAC Mode',
    description: 'Complete your first full BAC exam.',
    icon: '📝',
    xpReward: 50,
  );

  static const Achievement questions100 = Achievement(
    type: AchievementType.questions100,
    title: '100 Questions',
    description: 'Answer 100 questions.',
    icon: '💯',
    xpReward: 50,
  );

  static const Achievement questions500 = Achievement(
    type: AchievementType.questions500,
    title: 'Question Machine',
    description: 'Answer 500 questions.',
    icon: '🔥',
    xpReward: 100,
  );

  static const Achievement streak3 = Achievement(
    type: AchievementType.streak3,
    title: '3-Day Run',
    description: 'Study for 3 consecutive days.',
    icon: '🔥',
    xpReward: 30,
  );

  static const Achievement streak7 = Achievement(
    type: AchievementType.streak7,
    title: 'One Week Strong',
    description: 'Maintain a 7-day study streak.',
    icon: '⚡',
    xpReward: 75,
  );

  static const Achievement streak30 = Achievement(
    type: AchievementType.streak30,
    title: '30-Day Warrior',
    description: 'Maintain a 30-day study streak.',
    icon: '🏆',
    xpReward: 250,
  );

  static const Achievement perfectQuiz = Achievement(
    type: AchievementType.perfectQuiz,
    title: 'Perfect Quiz',
    description: 'Get every question in a quiz correct.',
    icon: '🎯',
    xpReward: 75,
  );

  static const Achievement physicsMaster = Achievement(
    type: AchievementType.physicsMaster,
    title: 'Physique Solide',
    description: 'Master a physics concept.',
    icon: '⚡',
    xpReward: 75,
    subjectId: 'physics',
  );

  static const Achievement mathematicsMaster = Achievement(
    type: AchievementType.mathematicsMaster,
    title: 'Maître des Maths',
    description: 'Master a mathematics concept.',
    icon: '🧮',
    xpReward: 75,
    subjectId: 'math',
  );

  static const Achievement scienceMaster = Achievement(
    type: AchievementType.scienceMaster,
    title: 'Bio Warrior',
    description: 'Master a natural-science concept.',
    icon: '🧬',
    xpReward: 75,
    subjectId: 'science',
  );

  static const List<Achievement> all = [
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
  ];

  /// The achievement definition for a type, if it exists.
  static Achievement? forType(AchievementType type) {
    for (final achievement in all) {
      if (achievement.type == type) {
        return achievement;
      }
    }

    return null;
  }
}
