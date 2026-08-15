// GamificationService: XP flows through the existing ledger, achievements are
// unlocked exactly once with their XP, and level-ups are detected from the
// level DERIVED from total XP.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_algeria_bac/data/achievement_engine.dart';
import 'package:my_algeria_bac/data/achievement_repository.dart';
import 'package:my_algeria_bac/data/content_repository.dart';
import 'package:my_algeria_bac/data/progress_repository.dart';
import 'package:my_algeria_bac/data/streak_repository.dart';
import 'package:my_algeria_bac/models/achievement.dart';
import 'package:my_algeria_bac/models/concept_mastery.dart';
import 'package:my_algeria_bac/models/lesson.dart';
import 'package:my_algeria_bac/models/source.dart';
import 'package:my_algeria_bac/models/streak.dart';
import 'package:my_algeria_bac/models/subject.dart';
import 'package:my_algeria_bac/services/gamification_service.dart';

class _FakeProgress extends ProgressRepository {
  int totalXp = 0;
  int questionsAnswered = 0;
  int lessonsCompleted = 0;
  int examsCompleted = 0;
  List<ConceptMastery> mastery = const [];
  final List<String> xpReasons = [];

  @override
  Future<int> getTotalXp() async => totalXp;

  @override
  Future<void> addXp({required String reason, required int amount}) async {
    totalXp += amount;
    xpReasons.add(reason);
  }

  @override
  Future<int> getTotalQuestionsAnswered() async => questionsAnswered;

  @override
  Future<int> getSavedLessonCount() async => lessonsCompleted;

  @override
  Future<int> getExamsCompleted() async => examsCompleted;

  @override
  Future<List<ConceptMastery>> getAllConceptMastery() async => mastery;
}

class _FakeStreak extends StreakRepository {
  int currentStreak = 0;
  int longestStreak = 0;

  @override
  Future<StreakState> getState() async {
    return StreakState(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastQualifyingDay: null,
      todayMinutes: 0,
      todayXp: 0,
    );
  }
}

class _FakeAchievements extends AchievementRepository {
  final List<AchievementType> unlocked = [];

  @override
  Future<bool> unlock(Achievement achievement) async {
    if (unlocked.contains(achievement.type)) {
      return false;
    }
    unlocked.add(achievement.type);
    return true;
  }

  @override
  Future<List<Achievement>> getUnlocked() async {
    return const [];
  }
}

class _FakeContent extends ContentRepository {
  final Map<String, List<String>> lessonToSubject = {};

  @override
  Future<List<Subject>> getSubjects() async {
    return _getSubjectIds().map((id) {
      return Subject(
        id: id,
        name: id,
        language: 'en',
        icon: '',
        lessonIds: const [],
      );
    }).toList();
  }

  List<String> _getSubjectIds() =>
      lessonToSubject.values.expand((e) => e).toSet().toList();

  @override
  Future<List<Lesson>> getLessonsForSubject(String subjectId) async {
    final ids = <String>[];
    for (final entry in lessonToSubject.entries) {
      if (entry.value.contains(subjectId)) {
        ids.addAll(entry.key.split(','));
      }
    }
    return [
      for (final id in ids)
        Lesson(
          id: id,
          title: id,
          subjectId: subjectId,
          description: '',
          conceptIds: const [],
          estimatedMinutes: 0,
          source: ContentSource(
            sourceType: 'demo_content',
            sourceName: 'demo',
            verified: false,
          ),
        ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future.value();
  }
}

void main() {
  late _FakeProgress progress;
  late _FakeStreak streak;
  late _FakeAchievements achievements;
  late GamificationService service;

  setUp(() {
    progress = _FakeProgress();
    streak = _FakeStreak();
    achievements = _FakeAchievements();
    service = GamificationService(
      progressRepository: progress,
      streakRepository: streak,
      achievementRepository: achievements,
      contentRepository: _FakeContent(),
    );
  });

  test('awardXp routes through the XP ledger', () async {
    progress.totalXp = 50;

    final info = await service.awardXp(amount: 50, reason: 'test');

    expect(progress.totalXp, 100);
    expect(progress.xpReasons, ['test']);
    expect(info.level, 2);
  });

  test('level-up is reported when XP crosses a threshold', () async {
    progress.totalXp = 95;

    final result = await service.evaluateAfterActivity(
      activity: CompletedActivity(
        type: AchievementActivityType.quiz,
        wasPerfect: false,
      ),
      extraXp: 15,
    );

    expect(result.levelUp, isNotNull);
    expect(result.levelUp!.oldLevel, 1);
    expect(result.levelUp!.newLevel, 2);
    expect(progress.totalXp, 110);
  });

  test('an achievement unlocks once and awards its XP once', () async {
    progress.lessonsCompleted = 1;

    final first = await service.evaluateAfterActivity(
      activity: CompletedActivity(
        type: AchievementActivityType.quiz,
        wasPerfect: false,
      ),
    );

    final second = await service.evaluateAfterActivity(
      activity: CompletedActivity(
        type: AchievementActivityType.quiz,
        wasPerfect: false,
      ),
    );

    expect(first.newAchievements.map((a) => a.type),
        containsAll([AchievementType.firstLesson, AchievementType.firstQuiz]));
    expect(first.newAchievements.map((a) => a.xpReward).fold(0, (a, b) => a + b),
        50);

    expect(second.newAchievements, isEmpty);
    expect(achievements.unlocked.length, 2);
  });

  test('no level-up when XP stays inside one level', () async {
    progress.totalXp = 10;
    progress.lessonsCompleted = 1;

    final result = await service.evaluateAfterActivity(
      activity: CompletedActivity(
        type: AchievementActivityType.quiz,
        wasPerfect: false,
      ),
      extraXp: 25,
    );

    expect(result.levelUp, isNull);
    expect(result.levelInfo.level, 1);
  });

  test('rank view derives from level', () async {
    progress.totalXp = 300;

    final view = await service.getRankView();

    expect(view.level, 3);
    expect(view.title, 'Candidat Sérieux');
  });
}
