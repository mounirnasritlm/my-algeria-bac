library;

import '../models/bac_campaign.dart';
import '../models/weak_point.dart';

/// Pure, Flutter-free localized strings for engine-layer text: missions,
/// comeback plans, seasons, time management, and study-plan tasks.
///
/// Engines accept a `languageCode` defaulting to English, so existing unit
/// tests keep their base-language assertions while the UI passes the active
/// app language. `{}` placeholders are replaced in order by [args].

String _pick(String languageCode, String en, String fr, String ar) {
  switch (languageCode) {
    case 'fr':
      return fr;
    case 'ar':
      return ar;
    default:
      return en;
  }
}

String _fill(String template, List<Object?> args) {
  var text = template;
  for (final arg in args) {
    text = text.replaceFirst('{}', '$arg');
  }
  return text;
}

/// Localized title for a daily mission.
String missionTitle(DailyMissionType type, String languageCode) {
  switch (type) {
    case DailyMissionType.rescue:
      return _pick(
          languageCode, 'Rescue mission', 'Mission sauvetage', 'مهمة إنقاذ');
    case DailyMissionType.speed:
      return _pick(
          languageCode, 'Speed mission', 'Mission vitesse', 'مهمة السرعة');
    case DailyMissionType.memory:
      return _pick(
          languageCode, 'Memory mission', 'Mission mémoire', 'مهمة الذاكرة');
    case DailyMissionType.bacExercise:
      return _pick(languageCode, 'BAC exercise', 'Exercice BAC',
          'تمرين البكالوريا');
    case DailyMissionType.precision:
      return _pick(languageCode, 'Precision mission', 'Mission précision',
          'مهمة الدقة');
    case DailyMissionType.bacChallenge:
      return _pick(languageCode, 'BAC challenge', 'Défi BAC',
          'تحدّي البكالوريا');
    case DailyMissionType.foundation:
      return _pick(languageCode, 'Foundation mission', 'Mission de base',
          'مهمة الأساس');
  }
}

/// Localized description for a daily mission. [conceptId] is only used by the
/// rescue mission, which names the student's weakest concept.
String missionDescription(
  DailyMissionType type,
  String languageCode, {
  required int target,
  String? conceptId,
}) {
  switch (type) {
    case DailyMissionType.rescue:
      return _fill(
        _pick(
          languageCode,
          'Answer {} questions on your weakest concept: {}.',
          'Réponds à {} questions sur ton concept le plus faible : {}.',
          'أجب عن {} أسئلة حول أضعف مفاهيمك: {}',
        ),
        [target, conceptId ?? ''],
      );
    case DailyMissionType.speed:
      return _fill(
        _pick(
          languageCode,
          'Answer {} questions today.',
          'Réponds à {} questions aujourd’hui.',
          'أجب عن {} سؤالاً اليوم.',
        ),
        [target],
      );
    case DailyMissionType.memory:
      return _fill(
        _pick(
          languageCode,
          'Touch at least {} different concepts today.',
          'Touche au moins {} concepts différents aujourd’hui.',
          'تعرّف اليوم على {} مفاهيم مختلفة على الأقل.',
        ),
        [target],
      );
    case DailyMissionType.bacExercise:
      return _pick(
        languageCode,
        'Complete one full timed exam today.',
        'Termine un examen chronométré complet aujourd’hui.',
        'أكمل اليوم امتحاناً كاملاً بتوقيت محدد.',
      );
    case DailyMissionType.precision:
      return _fill(
        _pick(
          languageCode,
          'Answer at least {} questions with 85%+ accuracy.',
          'Réponds à au moins {} questions avec une précision de 85 %+.',
          'أجب عن {} أسئلة على الأقل بدقة 85%+.',
        ),
        [target],
      );
    case DailyMissionType.bacChallenge:
      return _pick(
        languageCode,
        'Complete a full timed exam in exam conditions.',
        'Termine un examen complet dans les conditions réelles.',
        'أكمل امتحاناً كاملاً في ظروف امتحانية حقيقية.',
      );
    case DailyMissionType.foundation:
      return _fill(
        _pick(
          languageCode,
          'Answer your first {} questions today.',
          'Réponds à tes {} premières questions aujourd’hui.',
          'أجب اليوم عن أول {} أسئلة.',
        ),
        [target],
      );
  }
}

/// Localized title for a comeback day (1-indexed, 1..7).
String comebackDayTitle(int day, String languageCode) {
  switch (day) {
    case 1:
      return _pick(languageCode, 'Concept review', 'Révision du concept',
          'مراجعة المفهوم');
    case 2:
      return _pick(languageCode, '10 targeted exercises', '10 exercices ciblés',
          '10 تمارين موجّهة');
    case 3:
      return _pick(
          languageCode, 'Targeted quiz', 'Quiz ciblé', 'اختبار موجّه');
    case 4:
      return _pick(languageCode, 'Timed exercise', 'Exercice chronométré',
          'تمرين بتوقيت');
    case 5:
      return _pick(languageCode, 'Review your mistakes', 'Revois tes erreurs',
          'راجع أخطاءك');
    case 6:
      return _pick(
          languageCode, 'Final review', 'Révision finale', 'مراجعة نهائية');
    case 7:
      return _pick(languageCode, 'Boss rematch', 'Revanche finale',
          'إعادة المباراة النهائية');
    default:
      return _pick(languageCode, 'Day $day', 'Jour $day', 'اليوم $day');
  }
}

/// Localized description for a comeback day (1-indexed, 1..7).
String comebackDayDescription(int day, String languageCode) {
  switch (day) {
    case 1:
      return _pick(
        languageCode,
        'Re-read the lesson for your weak concept.',
        'Relis la leçon de ton concept faible.',
        'أعد قراءة درس المفهوم الضعيف.',
      );
    case 2:
      return _pick(
        languageCode,
        'Practice questions aimed at your weak concept.',
        'Entraîne-toi sur des questions ciblant ton concept faible.',
        'تمرّن على أسئلة موجّهة لمفهومك الضعيف.',
      );
    case 3:
      return _pick(
        languageCode,
        'Re-test your weak concept in a short quiz.',
        'Re-teste ton concept faible dans un quiz court.',
        'أعد اختبار مفهومك الضعيف في اختبار قصير.',
      );
    case 4:
      return _pick(
        languageCode,
        'A timed exam section under real conditions.',
        'Une section d’examen chronométrée dans des conditions réelles.',
        'قسم امتحان بتوقيت في ظروف حقيقية.',
      );
    case 5:
      return _pick(
        languageCode,
        'Consolidate before the rematch.',
        'Consolide tes acquis avant la revanche.',
        'ثبّت معلوماتك قبل إعادة المباراة.',
      );
    case 6:
      return _pick(
        languageCode,
        'Quick refresh of the concept and its rules.',
        'Un rappel rapide du concept et de ses règles.',
        'مراجعة سريعة للمفهوم وقواعده.',
      );
    case 7:
      return _pick(
        languageCode,
        'Take the full exam again and beat your score.',
        'Repasse l’examen complet et bats ton score.',
        'أعد اجتياز الامتحان الكامل وحسّن نتيجتك.',
      );
    default:
      return _pick(
        languageCode,
        'Continue working on your plan.',
        'Continue de suivre ton plan.',
        'واصل العمل على خطتك.',
      );
  }
}

/// Localized BAC season label (shown on the home countdown).
String seasonLabel(BacSeason season, String languageCode) {
  switch (season) {
    case BacSeason.foundation:
      return _pick(languageCode, 'Foundation', 'Fondations', 'البناء');
    case BacSeason.acceleration:
      return _pick(languageCode, 'Acceleration', 'Accélération', 'التسارع');
    case BacSeason.examTraining:
      return _pick(
          languageCode, 'Exam training', 'Préparation examen', 'التحضير للامتحان');
    case BacSeason.finalSprint:
      return _pick(languageCode, 'BAC final sprint', 'Sprint final BAC',
          'الاندفاعة الأخيرة');
  }
}

/// Localized label for an exam time-management result. [code] is the internal
/// token produced by the scoring engine ('Good' | 'Fair' | 'Tight' | other).
String timeManagementLabelFor(String code, String languageCode) {
  switch (code) {
    case 'Good':
      return _pick(languageCode, 'Good', 'Bonne', 'جيّد');
    case 'Fair':
      return _pick(languageCode, 'Fair', 'Correcte', 'مقبول');
    case 'Tight':
      return _pick(languageCode, 'Tight', 'Tendue', 'ضيّق');
    default:
      return _pick(languageCode, 'Unknown', 'Inconnu', 'غير معروف');
  }
}

/// Localized weak-point study task title: `Fix <concept>`.
String fixConceptTask(String languageCode, String name) {
  return _fill(
    _pick(languageCode, 'Fix {}', 'Corriger {}', 'عالج {}'),
    [name],
  );
}

/// Localized lesson study task title: `Study <lesson>`.
String studyLessonTask(String languageCode, String title) {
  return _fill(
    _pick(languageCode, 'Study {}', 'Étudier {}', 'ادرس {}'),
    [title],
  );
}

/// Localized daily-practice task title and description.
String quickPracticeTask(String languageCode) {
  return _pick(
      languageCode, 'Quick Practice', 'Entraînement rapide', 'تمرين سريع');
}

String quickPracticeDescription(String languageCode) {
  return _pick(
    languageCode,
    'Answer a focused set of questions from today\'s topics.',
    'Réponds à une série ciblée de questions sur les sujets du jour.',
    'أجب عن مجموعة موجّهة من الأسئلة حول مواضيع اليوم.',
  );
}

/// Localized starter task (empty plan fallback) title and description.
String starterPracticeTask(String languageCode) {
  return _pick(
    languageCode,
    'Start a practice session',
    'Commencer une séance d’entraînement',
    'ابدأ جلسة تمرين',
  );
}

String starterPracticeDescription(String languageCode) {
  return _pick(
    languageCode,
    'Begin with a short practice session to generate useful learning data.',
    'Commence par une courte séance d’entraînement pour générer des données '
        'utiles.',
    'ابدأ بجلسة تمرين قصيرة لتوليد بيانات تعلّم مفيدة.',
  );
}

/// Localized weak-point mastery line, e.g. "58% mastery. ...".
String weakPointDescription(
  String languageCode,
  WeakPointPriority priority,
  int percent,
) {
  switch (priority) {
    case WeakPointPriority.critical:
      return _fill(
        _pick(
          languageCode,
          '{}% mastery. This should be your top priority.',
          '{}% de maîtrise. C’est ta priorité absolue.',
          'إتقان {}%. هذا يجب أن يكون أولويتك القصوى.',
        ),
        [percent],
      );
    case WeakPointPriority.high:
      return _fill(
        _pick(
          languageCode,
          '{}% mastery. More targeted practice is needed.',
          '{}% de maîtrise. Un entraînement plus ciblé est nécessaire.',
          'إتقان {}%. مطلوب مزيد من التمرين الموجّه.',
        ),
        [percent],
      );
    case WeakPointPriority.medium:
      return _fill(
        _pick(
          languageCode,
          '{}% mastery. Keep developing this concept.',
          '{}% de maîtrise. Continue de développer ce concept.',
          'إتقان {}%. واصل تطوير هذا المفهوم.',
        ),
        [percent],
      );
    case WeakPointPriority.low:
      return _fill(
        _pick(
          languageCode,
          '{}% mastery. A quick review will keep it fresh.',
          '{}% de maîtrise. Une révision rapide le gardera frais.',
          'إتقان {}%. مراجعة سريعة ستحافظ على حداثته.',
        ),
        [percent],
      );
  }
}
