// Achievement engine: unlock conditions are derived from real activity stats
// and the just-completed activity — never random, never guessed.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_algeria_bac/data/achievement_engine.dart';
import 'package:my_algeria_bac/models/achievement.dart';
import 'package:my_algeria_bac/models/concept_mastery.dart';

ConceptMastery mastery({
  required String lessonId,
  double accuracy = 0.9,
  int attempts = 3,
}) {
  return ConceptMastery(
    conceptId: 'concept_of_$lessonId',
    lessonId: lessonId,
    attempts: attempts,
    correct: (accuracy * attempts).round(),
    mastery: accuracy,
    accuracy: accuracy,
    status: accuracy >= 0.9
        ? MasteryStatus.mastered
        : accuracy >= 0.75
            ? MasteryStatus.strong
            : MasteryStatus.developing,
    lastAttemptAt: DateTime(2026, 8, 15),
  );
}

StudentStats stats({
  int questionsAnswered = 0,
  int quizzesCompleted = 0,
  int examsCompleted = 0,
  int lessonsCompleted = 0,
  int currentStreak = 0,
  int longestStreak = 0,
  List<ConceptMastery> mastery = const [],
  Map<String, String> lessonToSubject = const {},
}) {
  return StudentStats(
    questionsAnswered: questionsAnswered,
    quizzesCompleted: quizzesCompleted,
    examsCompleted: examsCompleted,
    lessonsCompleted: lessonsCompleted,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    mastery: mastery,
    lessonToSubject: lessonToSubject,
  );
}

CompletedActivity quiz({bool perfect = false}) {
  return CompletedActivity(
    type: AchievementActivityType.quiz,
    wasPerfect: perfect,
  );
}

Set<AchievementType> evaluate({
  required CompletedActivity activity,
  StudentStats? student,
}) {
  return evaluateAchievements(
    stats: student ?? stats(),
    activity: activity,
  ).map((a) => a.type).toSet();
}

void main() {
  test('a fresh student unlocks nothing', () {
    expect(evaluate(activity: quiz()), isEmpty);
  });

  test('first lesson and first quiz unlock with one completed quiz', () {
    final unlocked = evaluate(
      activity: quiz(),
      student: stats(lessonsCompleted: 1, quizzesCompleted: 1),
    );

    expect(unlocked, contains(AchievementType.firstLesson));
    expect(unlocked, contains(AchievementType.firstQuiz));
  });

  test('first exam unlocks after an exam completes', () {
    final unlocked = evaluate(
      activity: CompletedActivity(
        type: AchievementActivityType.exam,
        wasPerfect: false,
      ),
      student: stats(examsCompleted: 1),
    );

    expect(unlocked, contains(AchievementType.firstExam));
  });

  test('question milestones unlock at 100 and 500', () {
    expect(
      evaluate(activity: quiz(), student: stats(questionsAnswered: 100)),
      contains(AchievementType.questions100),
    );
    expect(
      evaluate(activity: quiz(), student: stats(questionsAnswered: 500)),
      containsAll([
        AchievementType.questions100,
        AchievementType.questions500,
      ]),
    );
  });

  test('streak achievements unlock from current or longest streak', () {
    expect(
      evaluate(activity: quiz(), student: stats(currentStreak: 3)),
      contains(AchievementType.streak3),
    );
    expect(
      evaluate(activity: quiz(), student: stats(longestStreak: 7)),
      contains(AchievementType.streak7),
    );
    expect(
      evaluate(activity: quiz(), student: stats(longestStreak: 30)),
      contains(AchievementType.streak30),
    );
  });

  test('perfect quiz unlocks only from a perfect quiz activity', () {
    final perfect = evaluate(
      activity: quiz(perfect: true),
      student: stats(lessonsCompleted: 1, quizzesCompleted: 1),
    );
    final imperfect = evaluate(
      activity: quiz(perfect: false),
      student: stats(lessonsCompleted: 1, quizzesCompleted: 1),
    );

    expect(perfect, contains(AchievementType.perfectQuiz));
    expect(imperfect, isNot(contains(AchievementType.perfectQuiz)));
  });

  test('a strong concept unlocks its subject achievement', () {
    final unlocked = evaluate(
      activity: quiz(),
      student: stats(
        lessonsCompleted: 1,
        quizzesCompleted: 1,
        mastery: [mastery(lessonId: 'physics_motion')],
        lessonToSubject: {'physics_motion': 'physics'},
      ),
    );

    expect(unlocked, contains(AchievementType.physicsMaster));
  });

  test('a weak concept in a subject unlocks nothing for that subject', () {
    final unlocked = evaluate(
      activity: quiz(),
      student: stats(
        mastery: [mastery(lessonId: 'math_functions', accuracy: 0.5)],
        lessonToSubject: {'math_functions': 'math'},
      ),
    );

    expect(unlocked, isNot(contains(AchievementType.mathematicsMaster)));
  });

  test('results come back in catalog order', () {
    final unlocked = evaluateAchievements(
      stats: stats(
        questionsAnswered: 500,
        lessonsCompleted: 1,
        quizzesCompleted: 1,
        longestStreak: 30,
      ),
      activity: quiz(perfect: true),
    );

    final types = unlocked.map((a) => a.type).toList();
    expect(types, [
      AchievementType.firstLesson,
      AchievementType.firstQuiz,
      AchievementType.questions100,
      AchievementType.questions500,
      AchievementType.streak3,
      AchievementType.streak7,
      AchievementType.streak30,
      AchievementType.perfectQuiz,
    ]);
  });
}
