import '../models/achievement.dart';

/// Authoritative achievement catalog. Every achievement is defined once here
/// with its title, description, icon, and one-time XP reward. The unlock
/// CONDITIONS are evaluated by `data/achievement_engine.dart` from real
/// activity — no random or fabricated unlocks.
///
/// `title`/`description` are English (base copy); `titles`/`descriptions`
/// carry the French and Arabic variants used by the UI.
class Achievements {
  const Achievements._();

  static const Achievement firstLesson = Achievement(
    type: AchievementType.firstLesson,
    title: 'First Step',
    description: 'Complete your first lesson quiz.',
    icon: '📚',
    xpReward: 25,
    titles: {
      'fr': 'Premier pas',
      'ar': 'الخطوة الأولى',
    },
    descriptions: {
      'fr': 'Termine le quiz de ta première leçon.',
      'ar': 'أكمل اختبار درسك الأول.',
    },
  );

  static const Achievement firstQuiz = Achievement(
    type: AchievementType.firstQuiz,
    title: 'Quiz Started',
    description: 'Complete your first quiz.',
    icon: '🧠',
    xpReward: 25,
    titles: {
      'fr': 'Quiz commencé',
      'ar': 'بدأت الاختبار',
    },
    descriptions: {
      'fr': 'Termine ton premier quiz.',
      'ar': 'أكمل اختبارك الأول.',
    },
  );

  static const Achievement firstExam = Achievement(
    type: AchievementType.firstExam,
    title: 'BAC Mode',
    description: 'Complete your first full BAC exam.',
    icon: '📝',
    xpReward: 50,
    titles: {
      'fr': 'Mode BAC',
      'ar': 'وضع البكالوريا',
    },
    descriptions: {
      'fr': 'Termine ton premier examen BAC complet.',
      'ar': 'أكمل أول امتحان بكالوريا كامل.',
    },
  );

  static const Achievement questions100 = Achievement(
    type: AchievementType.questions100,
    title: '100 Questions',
    description: 'Answer 100 questions.',
    icon: '💯',
    xpReward: 50,
    titles: {
      'fr': '100 Questions',
      'ar': '100 سؤال',
    },
    descriptions: {
      'fr': 'Réponds à 100 questions.',
      'ar': 'أجب عن 100 سؤال.',
    },
  );

  static const Achievement questions500 = Achievement(
    type: AchievementType.questions500,
    title: 'Question Machine',
    description: 'Answer 500 questions.',
    icon: '🔥',
    xpReward: 100,
    titles: {
      'fr': 'Machine à questions',
      'ar': 'آلة الأسئلة',
    },
    descriptions: {
      'fr': 'Réponds à 500 questions.',
      'ar': 'أجب عن 500 سؤال.',
    },
  );

  static const Achievement streak3 = Achievement(
    type: AchievementType.streak3,
    title: '3-Day Run',
    description: 'Study for 3 consecutive days.',
    icon: '🔥',
    xpReward: 30,
    titles: {
      'fr': '3 jours de suite',
      'ar': '3 أيام متتالية',
    },
    descriptions: {
      'fr': 'Étudie 3 jours consécutifs.',
      'ar': 'ادرس 3 أيام متتالية.',
    },
  );

  static const Achievement streak7 = Achievement(
    type: AchievementType.streak7,
    title: 'One Week Strong',
    description: 'Maintain a 7-day study streak.',
    icon: '⚡',
    xpReward: 75,
    titles: {
      'fr': 'Une semaine solide',
      'ar': 'أسبوع كامل',
    },
    descriptions: {
      'fr': 'Maintiens une série de 7 jours.',
      'ar': 'حافظ على سلسلة دراسة 7 أيام.',
    },
  );

  static const Achievement streak30 = Achievement(
    type: AchievementType.streak30,
    title: '30-Day Warrior',
    description: 'Maintain a 30-day study streak.',
    icon: '🏆',
    xpReward: 250,
    titles: {
      'fr': 'Guerrier des 30 jours',
      'ar': 'محارب 30 يوماً',
    },
    descriptions: {
      'fr': 'Maintiens une série de 30 jours.',
      'ar': 'حافظ على سلسلة دراسة 30 يوماً.',
    },
  );

  static const Achievement perfectQuiz = Achievement(
    type: AchievementType.perfectQuiz,
    title: 'Perfect Quiz',
    description: 'Get every question in a quiz correct.',
    icon: '🎯',
    xpReward: 75,
    titles: {
      'fr': 'Quiz parfait',
      'ar': 'اختبار مثالي',
    },
    descriptions: {
      'fr': 'Réponds correctement à toutes les questions d’un quiz.',
      'ar': 'أجب عن جميع أسئلة الاختبار بشكل صحيح.',
    },
  );

  static const Achievement physicsMaster = Achievement(
    type: AchievementType.physicsMaster,
    title: 'Physique Solide',
    description: 'Master a physics concept.',
    icon: '⚡',
    xpReward: 75,
    subjectId: 'physics',
    titles: {
      'fr': 'Physique Solide',
      'ar': 'فيزياء صلبة',
    },
    descriptions: {
      'fr': 'Maîtrise un concept de physique.',
      'ar': 'أتقن مفهوماً في الفيزياء.',
    },
  );

  static const Achievement mathematicsMaster = Achievement(
    type: AchievementType.mathematicsMaster,
    title: 'Maître des Maths',
    description: 'Master a mathematics concept.',
    icon: '🧮',
    xpReward: 75,
    subjectId: 'math',
    titles: {
      'fr': 'Maître des Maths',
      'ar': 'سيد الرياضيات',
    },
    descriptions: {
      'fr': 'Maîtrise un concept de mathématiques.',
      'ar': 'أتقن مفهوماً في الرياضيات.',
    },
  );

  static const Achievement scienceMaster = Achievement(
    type: AchievementType.scienceMaster,
    title: 'Bio Warrior',
    description: 'Master a natural-science concept.',
    icon: '🧬',
    xpReward: 75,
    subjectId: 'science',
    titles: {
      'fr': 'Guerrier de la bio',
      'ar': 'محارب العلوم',
    },
    descriptions: {
      'fr': 'Maîtrise un concept de sciences naturelles.',
      'ar': 'أتقن مفهوماً في العلوم الطبيعية.',
    },
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
