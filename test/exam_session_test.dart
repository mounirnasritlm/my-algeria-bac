// Widget tests for the BAC Boss exam session flow:
// intro -> start -> answer -> navigate -> flag -> submit -> report,
// plus the auto-submit path when a saved session has expired while the
// app was closed.
//
// The repositories behind the page are swapped for in-memory fakes so the
// tests exercise the real page logic without touching sqflite.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_algeria_bac/data/achievement_engine.dart';
import 'package:my_algeria_bac/data/achievement_repository.dart';
import 'package:my_algeria_bac/data/content_repository.dart';
import 'package:my_algeria_bac/data/exam_session_repository.dart';
import 'package:my_algeria_bac/data/json_content_repository.dart';
import 'package:my_algeria_bac/data/levels_engine.dart';
import 'package:my_algeria_bac/data/progress_repository.dart';
import 'package:my_algeria_bac/data/streak_repository.dart';
import 'package:my_algeria_bac/models/saved_exam_session.dart';
import 'package:my_algeria_bac/models/streak.dart';
import 'package:my_algeria_bac/screens/bac_page.dart';
import 'package:my_algeria_bac/screens/exam_session_page.dart';
import 'package:my_algeria_bac/services/gamification_service.dart';
import 'package:my_algeria_bac/services/streak_service.dart';

import 'helpers/demo_content_assets.dart';
import 'helpers/fake_asset_bundle.dart';

/// Real [GamificationService] logic would hit sqflite through the real
/// repositories, so the widget tests swap in a service whose evaluation is
/// canned. The page still exercises its own submit/report flow end to end.
class _FakeGamificationService extends GamificationService {
  _FakeGamificationService()
      : super(
          progressRepository: _NoopProgressRepository(),
          streakRepository: _NoopStreakRepository(),
          achievementRepository: _NoopAchievementRepository(),
          contentRepository: _NoopContentRepository(),
        );

  @override
  Future<GamificationResult> evaluateAfterActivity({
    required CompletedActivity activity,
    int extraXp = 0,
  }) async {
    return GamificationResult(
      newAchievements: const [],
      levelUp: null,
      levelInfo: levelInfoFor(0),
    );
  }
}

class _NoopProgressRepository extends ProgressRepository {}

class _NoopStreakRepository extends StreakRepository {}

class _NoopAchievementRepository extends AchievementRepository {}

class _NoopContentRepository extends ContentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('BAC Arena lists exams and opens the Boss',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final content = JsonContentRepository(
      assetBundle: FakeAssetBundle(demoContentAssets),
    );
    final progress = _FakeProgressRepository();
    final sessions = _FakeExamSessionRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: BacPage(
          contentRepository: content,
          progressRepository: progress,
          sessionRepository: sessions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BAC Arena'), findsOneWidget);
    expect(find.text('⚔️ BAC BOSS'), findsOneWidget);
    expect(find.text('Available exams'), findsOneWidget);
    expect(find.text('الرياضيات'), findsOneWidget);
    expect(find.text('5 questions • 180 min'), findsOneWidget);

    await tester.tap(find.text('الرياضيات'));
    await tester.pumpAndSettle();

    expect(find.text('BAC BOSS'), findsOneWidget);
    expect(find.text('Enter the Boss'), findsOneWidget);
  });

  testWidgets('BAC Boss full run: answer, navigate, flag, submit, report',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final content = JsonContentRepository(
      assetBundle: FakeAssetBundle(demoContentAssets),
    );
    final progress = _FakeProgressRepository();
    final sessions = _FakeExamSessionRepository();
    final streak = _FakeStreakService();

    await tester.pumpWidget(
      MaterialApp(
        home: ExamSessionPage(
          contentRepository: content,
          examId: 'e_math_001',
          progressRepository: progress,
          sessionRepository: sessions,
          streakService: streak,
          gamificationService: _FakeGamificationService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BAC BOSS'), findsOneWidget);
    expect(find.text('الرياضيات'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Enter the Boss'), findsOneWidget);

    await tester.tap(find.text('Enter the Boss'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Question 1 of 5'), findsOneWidget);
    expect(find.text('Demo exercise 1'), findsOneWidget);

    await tester.tap(find.text('f'));
    await tester.pump();
    expect(find.text('1/5 answered'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('Question 2 of 5'), findsOneWidget);
    expect(sessions.flags, isEmpty);

    await tester.tap(find.text('Flag'));
    await tester.pump();
    expect(find.text('Flagged'), findsOneWidget);
    expect(sessions.flags, contains('q_math_002'));

    await tester.tap(find.text('Question navigator'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Unanswered'), findsOneWidget);
    expect(find.text('Answered'), findsOneWidget);

    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Question 5 of 5'), findsOneWidget);
    expect(find.text('Demo exercise 2'), findsOneWidget);

    await tester.tap(find.text('0'));
    await tester.pump();

    await tester.tap(find.text('Submit exam'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Submit exam?'), findsOneWidget);
    expect(find.textContaining('3 unanswered'), findsOneWidget);

    await tester.tap(find.text('Submit'));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Exam report'), findsOneWidget);
    expect(find.textContaining('2/5 correct'), findsOneWidget);
    expect(progress.examAttempts, 1);
    expect(progress.questionAttempts, 2);
    expect(progress.conceptAttempts, 2);
    expect(progress.conceptSources, everyElement('bac_boss'));
    expect(sessions.submitted, isTrue);
  });

  testWidgets('Expired in-progress session auto-submits on open',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final content = JsonContentRepository(
      assetBundle: FakeAssetBundle(demoContentAssets),
    );
    final startedAt = DateTime.now().subtract(const Duration(minutes: 200));
    final progress = _FakeProgressRepository();
    final sessions = _FakeExamSessionRepository(
      initialSession: SavedExamSession(
        id: 's_expired',
        examId: 'e_math_001',
        startedAt: startedAt,
        durationSeconds: 180 * 60,
        status: SavedExamSessionStatus.inProgress,
        currentIndex: 2,
        answers: const {},
        flaggedQuestionIds: const {},
      ),
      initialAnswers: const {'q_math_001': 0},
      initialFlags: const {'q_math_003'},
      initialIndex: 2,
    );
    final streak = _FakeStreakService();

    await tester.pumpWidget(
      MaterialApp(
        home: ExamSessionPage(
          contentRepository: content,
          examId: 'e_math_001',
          progressRepository: progress,
          sessionRepository: sessions,
          streakService: streak,
          gamificationService: _FakeGamificationService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Exam report'), findsOneWidget);
    expect(
      find.text('Time ran out — your exam was submitted automatically.'),
      findsOneWidget,
    );
    expect(sessions.submitted, isTrue);
    expect(progress.questionAttempts, 1);
    expect(streak.recorded.single.id, 'bac_boss_s_expired');
  });
}

class _FakeStreakService extends StreakService {
  final List<StreakActivity> recorded = [];

  @override
  Future<bool> recordLearningActivity({
    required String activityId,
    required StreakActivityType type,
    required int minutes,
  }) async {
    recorded.add(
      StreakActivity(
        id: activityId,
        type: type,
        completedAt: DateTime.now(),
        xpEarned: 0,
        minutes: minutes,
      ),
    );
    return true;
  }
}

class _FakeProgressRepository extends ProgressRepository {
  int examAttempts = 0;
  int questionAttempts = 0;
  int conceptAttempts = 0;
  final List<String> conceptSources = [];
  @override
  Future<void> saveExamAttempt({
    required String examId,
    required double scoreOn20,
    required int correctCount,
    required int totalQuestions,
    required int timeUsedSeconds,
  }) async {
    examAttempts++;
  }

  @override
  Future<void> saveQuestionAttempt({
    required String questionId,
    required String lessonId,
    required String conceptId,
    required int? selectedAnswer,
    required int? correctAnswer,
    required bool isCorrect,
  }) async {
    questionAttempts++;
  }

  @override
  Future<void> saveConceptAttempt({
    required String conceptId,
    required String lessonId,
    required String questionId,
    required bool isCorrect,
    String sourceType = 'quiz',
    int? responseTimeSeconds,
  }) async {
    conceptAttempts++;
    conceptSources.add(sourceType);
  }
}

class _FakeExamSessionRepository extends ExamSessionRepository {
  _FakeExamSessionRepository({
    SavedExamSession? initialSession,
    Map<String, int> initialAnswers = const {},
    Set<String> initialFlags = const {},
    int initialIndex = 0,
    SavedExamSessionStatus initialStatus = SavedExamSessionStatus.inProgress,
  })  : _active = initialSession,
        _answers = Map.of(initialAnswers),
        _flags = Set.of(initialFlags),
        _currentIndex = initialIndex,
        _status = initialStatus;

  SavedExamSession? _active;
  final Map<String, int> _answers;
  final Set<String> _flags;
  int _currentIndex;
  SavedExamSessionStatus _status;

  bool submitted = false;

  Set<String> get flags => Set.of(_flags);

  SavedExamSession? get _snapshot {
    final active = _active;
    if (active == null) {
      return null;
    }
    return SavedExamSession(
      id: active.id,
      examId: active.examId,
      startedAt: active.startedAt,
      durationSeconds: active.durationSeconds,
      status: _status,
      currentIndex: _currentIndex,
      answers: Map.of(_answers),
      flaggedQuestionIds: Set.of(_flags),
    );
  }

  @override
  Future<SavedExamSession> createSession({
    required String examId,
    required int durationSeconds,
  }) async {
    _active = SavedExamSession(
      id: 'fake_session_${DateTime.now().microsecondsSinceEpoch}',
      examId: examId,
      startedAt: DateTime.now(),
      durationSeconds: durationSeconds,
      status: SavedExamSessionStatus.inProgress,
      currentIndex: 0,
      answers: const {},
      flaggedQuestionIds: const {},
    );
    _answers.clear();
    _flags.clear();
    _currentIndex = 0;
    _status = SavedExamSessionStatus.inProgress;
    return _snapshot!;
  }

  @override
  Future<SavedExamSession?> getInProgressSession(String examId) async {
    final snapshot = _snapshot;
    if (snapshot == null ||
        snapshot.status != SavedExamSessionStatus.inProgress) {
      return null;
    }
    return snapshot;
  }

  @override
  Future<void> saveAnswer({
    required String sessionId,
    required String questionId,
    required int? selectedIndex,
  }) async {
    _answers[questionId] = selectedIndex!;
  }

  @override
  Future<void> setCurrentIndex({
    required String sessionId,
    required int index,
  }) async {
    _currentIndex = index;
  }

  @override
  Future<void> setFlags({
    required String sessionId,
    required Set<String> flaggedQuestionIds,
  }) async {
    _flags
      ..clear()
      ..addAll(flaggedQuestionIds);
  }

  @override
  Future<void> markSubmitted({required String sessionId}) async {
    submitted = true;
    _status = SavedExamSessionStatus.submitted;
  }
}
