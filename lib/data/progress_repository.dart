import '../models/bac_campaign.dart';
import '../models/comeback.dart';
import '../models/concept_mastery.dart';
import '../models/revision_recommendation.dart';
import '../models/user_progress.dart';
import '../models/weak_point.dart';
import 'app_database.dart';
import 'campaign_engine.dart';
import 'mastery_engine.dart';

class ProgressRepository {
  UserProgress? _cached;
  bool _loaded = false;

  Future<UserProgress?> _loadCached() async {
    if (!_loaded) {
      try {
        _cached = await ProgressDatabase.instance.getOrCreate();
      } catch (_) {
        _cached = UserProgress.empty();
      }

      _loaded = true;
    }

    return _cached;
  }

  Future<void> saveLessonResult({
    required String lessonId,
    required String lessonTitle,
    required int questionsAnswered,
    required int questionsCorrect,
    required int xpEarned,
  }) async {
    final current = await _loadCached();

    if (current == null) {
      return;
    }

    final next = current.copyWithProgress(
      lessonId: lessonId,
      title: lessonTitle,
      questionsAnswered: questionsAnswered,
      questionsCorrect: questionsCorrect,
      xpEarned: xpEarned,
    );

    try {
      final updated = await ProgressDatabase.instance.updateOrInsert(
        progress: next,
      );

      _cached = updated;
    } catch (_) {
      _cached = next;
    }
  }

  Future<String?> getLessonTitle(String lessonId) async {
    final progress = await _loadCached();

    if (progress == null) {
      return null;
    }

    for (final lesson in progress.lessons) {
      if (lesson.id == lessonId) {
        return lesson.title;
      }
    }

    return null;
  }

  Future<int> getTotalXp() async {
    final progress = await _loadCached();

    int total = 0;

    if (progress != null) {
      for (final lesson in progress.lessons) {
        total += lesson.xpEarned;
      }
    }

    try {
      total += await ProgressDatabase.instance.getTotalXpEvents();
    } catch (_) {
      // Best-effort.
    }

    return total;
  }

  // ---------------------------------------------------------------------
  // XP ledger (single accounting for every XP source).
  // ---------------------------------------------------------------------

  /// Records one XP award. All sources (quiz, mission, later streak/badges)
  /// go through here so total XP is a plain ledger sum.
  Future<void> addXp({
    required String reason,
    required int amount,
  }) async {
    if (amount <= 0) {
      return;
    }

    try {
      await ProgressDatabase.instance.insertXpEvent(
        reason: reason,
        amount: amount,
      );
    } catch (_) {
      // Best-effort; XP loss must never break a screen.
    }
  }

  /// Awards mission XP exactly once per calendar day (guarded by the
  /// completion date in app_settings). Safe to call from any screen load.
  Future<void> awardMissionXp(DailyMission mission, DateTime today) async {
    final key = dateKey(today);
    final lastAwarded = await getSetting('mission_completed_date');

    final shouldAward = shouldAwardMissionXp(
      mission: mission,
      lastAwardedDate: lastAwarded,
      todayKey: key,
    );

    if (!shouldAward) {
      return;
    }

    await addXp(reason: 'daily_mission', amount: mission.rewardXp);
    await setSetting('mission_completed_date', key);
  }

  Future<int> getCurrentStreak() async {
    final progress = await _loadCached();

    if (progress == null) {
      return 0;
    }

    return progress.currentStreak;
  }

  Future<int> getLongestStreak() async {
    final progress = await _loadCached();

    if (progress == null) {
      return 0;
    }

    return progress.longestStreak;
  }

  Future<double> getOverallAccuracy() async {
    final progress = await _loadCached();

    if (progress == null) {
      return 0;
    }

    final totalAnswered = progress.lessons.fold(0, (total, lesson) {
      return total + lesson.questionsAnswered;
    });

    if (totalAnswered == 0) {
      return 0;
    }

    final totalCorrect = progress.lessons.fold(0, (total, lesson) {
      return total + lesson.questionsCorrect;
    });

    return totalCorrect / totalAnswered;
  }

  Future<List<LessonProgress>> getAllLessonProgress() async {
    final progress = await _loadCached();

    if (progress == null) {
      return [];
    }

    return progress.lessons;
  }

  // ---------------------------------------------------------------------
  // Settings (persisted per device).
  // ---------------------------------------------------------------------

  Future<String?> getSetting(String key) async {
    try {
      return await ProgressDatabase.instance.getSetting(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> setSetting(String key, String value) async {
    try {
      await ProgressDatabase.instance.setSetting(key, value);
    } catch (_) {
      // Best-effort persistence.
    }
  }

  Future<DateTime?> getBacDate() async {
    final raw = await getSetting('bac_date');

    if (raw == null) {
      return null;
    }

    return DateTime.tryParse(raw);
  }

  Future<void> saveBacDate(DateTime date) async {
    await setSetting('bac_date', date.toIso8601String());
  }

  // ---------------------------------------------------------------------
  // Exam attempts.
  // ---------------------------------------------------------------------

  Future<void> saveExamAttempt({
    required String examId,
    required double scoreOn20,
    required int correctCount,
    required int totalQuestions,
    required int timeUsedSeconds,
  }) async {
    try {
      final db = await ProgressDatabase.instance.database;

      await db.insert(
        'exam_attempts',
        {
          'exam_id': examId,
          'score_on_20': scoreOn20,
          'correct_count': correctCount,
          'total_questions': totalQuestions,
          'time_used_seconds': timeUsedSeconds,
          'completed_at': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (_) {
      // Persistence is best-effort.
    }
  }

  /// Previous exam attempts for one exam, most recent first.
  Future<List<ExamAttemptSummary>> getExamAttemptHistory(
    String examId,
  ) async {
    try {
      final db = await ProgressDatabase.instance.database;

      final result = await db.query(
        'exam_attempts',
        where: 'exam_id = ?',
        whereArgs: [examId],
        orderBy: 'completed_at DESC',
      );

      return result
          .map(ExamAttemptSummary.fromMap)
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------
  // Campaign / study activity.
  // ---------------------------------------------------------------------

  /// Set of calendar days (midnight) on which at least one question was
  /// attempted. Derived from the attempt table, so streaks are honest.
  Future<Set<DateTime>> getStudyDays() async {
    try {
      final db = await ProgressDatabase.instance.database;

      final result = await db.rawQuery(
        '''
        SELECT DISTINCT attempted_at
        FROM question_attempts
        ''',
      );

      final days = <DateTime>{};

      for (final row in result) {
        final epoch = (row['attempted_at'] as num).toInt();
        final date = DateTime.fromMillisecondsSinceEpoch(epoch);
        days.add(DateTime(date.year, date.month, date.day));
      }

      return days;
    } catch (_) {
      return {};
    }
  }

  /// Today's measurable activity (calendar-day buckets).
  Future<DailyActivity> getDailyActivity(DateTime today) async {
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));

    try {
      final db = await ProgressDatabase.instance.database;

      final attempts = await db.query(
        'question_attempts',
        columns: ['concept_id', 'is_correct'],
        where: 'attempted_at >= ? AND attempted_at < ?',
        whereArgs: [
          start.millisecondsSinceEpoch,
          end.millisecondsSinceEpoch,
        ],
      );

      var questions = 0;
      var correct = 0;
      final byConcept = <String, int>{};

      for (final row in attempts) {
        questions++;
        if ((row['is_correct'] as num).toInt() == 1) {
          correct++;
        }

        final conceptId = row['concept_id'] as String;
        byConcept[conceptId] = (byConcept[conceptId] ?? 0) + 1;
      }

      final exams = await db.query(
        'exam_attempts',
        columns: ['id'],
        where: 'completed_at >= ? AND completed_at < ?',
        whereArgs: [
          start.millisecondsSinceEpoch,
          end.millisecondsSinceEpoch,
        ],
      );

      return DailyActivity(
        questionsToday: questions,
        correctToday: correct,
        conceptAttemptsToday: byConcept,
        examCompletedToday: exams.isNotEmpty,
      );
    } catch (_) {
      return DailyActivity.empty;
    }
  }

  /// Total number of questions ever answered (from the attempt table).
  Future<int> getTotalQuestionsAnswered() async {
    try {
      final db = await ProgressDatabase.instance.database;

      final result = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM question_attempts',
      );

      return (result.first['count'] as num).toInt();
    } catch (_) {
      return 0;
    }
  }

  /// Number of lessons with a saved result (a finished lesson quiz).
  Future<int> getSavedLessonCount() async {
    try {
      final db = await ProgressDatabase.instance.database;

      final result = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM lessons',
      );

      return (result.first['count'] as num).toInt();
    } catch (_) {
      return 0;
    }
  }

  /// Number of full BAC exams ever completed.
  Future<int> getExamsCompleted() async {
    try {
      final db = await ProgressDatabase.instance.database;

      final result = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM exam_attempts',
      );

      return (result.first['count'] as num).toInt();
    } catch (_) {
      return 0;
    }
  }

  Future<void> saveQuestionAttempt({
    required String questionId,
    required String lessonId,
    required String conceptId,
    required int? selectedAnswer,
    required int? correctAnswer,
    required bool isCorrect,
  }) async {
    try {
      final db = await ProgressDatabase.instance.database;

      await db.insert(
        'question_attempts',
        {
          'question_id': questionId,
          'lesson_id': lessonId,
          'concept_id': conceptId,
          'selected_answer': selectedAnswer,
          'correct_answer': correctAnswer,
          'is_correct': isCorrect ? 1 : 0,
          'attempted_at': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (_) {
      // Persistence is best-effort; a failed write must not break a quiz.
    }
  }

  Future<void> saveConceptAttempt({
    required String conceptId,
    required String lessonId,
    required String questionId,
    required bool isCorrect,
    String sourceType = 'quiz',
    int? responseTimeSeconds,
  }) async {
    try {
      final db = await ProgressDatabase.instance.database;

      await db.insert(
        'concept_attempts',
        {
          'concept_id': conceptId,
          'lesson_id': lessonId,
          'question_id': questionId,
          'is_correct': isCorrect ? 1 : 0,
          'source_type': sourceType,
          'response_time_seconds': responseTimeSeconds,
          'attempted_at': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (_) {
      // Persistence is best-effort; a failed write must not break a quiz.
    }
  }

  Future<ConceptMastery?> getConceptMastery(String conceptId) async {
    try {
      final db = await ProgressDatabase.instance.database;

      final rows = await db.query(
        'concept_attempts',
        columns: ['lesson_id', 'is_correct', 'attempted_at'],
        where: 'concept_id = ?',
        whereArgs: [conceptId],
        orderBy: 'attempted_at ASC',
      );

      if (rows.isEmpty) {
        return null;
      }

      return _masteryFromRows(conceptId, rows);
    } catch (_) {
      return null;
    }
  }

  Future<List<ConceptMastery>> getAllConceptMastery() async {
    try {
      final db = await ProgressDatabase.instance.database;

      final rows = await db.query(
        'concept_attempts',
        columns: ['concept_id', 'lesson_id', 'is_correct', 'attempted_at'],
        orderBy: 'attempted_at ASC',
      );

      final grouped = <String, List<Map<String, Object?>>>{};
      for (final row in rows) {
        grouped.putIfAbsent(row['concept_id'] as String, () => []).add(row);
      }

      final result = <ConceptMastery>[];
      for (final entry in grouped.entries) {
        result.add(_masteryFromRows(entry.key, entry.value));
      }

      // Weakest first, so "most urgent" leads the list.
      result.sort((a, b) => a.mastery.compareTo(b.mastery));

      return result;
    } catch (_) {
      return [];
    }
  }

  /// Evidence-backed weak points, worst first. Only concepts with enough
  /// attempts are candidates — a single fluke answer never marks a concept
  /// weak, and classification uses recency-weighted mastery, not raw accuracy.
  Future<List<WeakPoint>> getWeakPoints() async {
    final mastery = await getAllConceptMastery();
    return weakPointsFromMastery(mastery);
  }

  /// Weakest-first, reviewed-ready list of concepts ordered by priority.
  Future<List<RevisionRecommendation>> getRevisionRecommendations() async {
    final mastery = await getAllConceptMastery();

    final recommendations = <RevisionRecommendation>[];

    for (final item in mastery) {
      if (item.attempts == 0) {
        continue;
      }

      final priority = revisionPriority(
        accuracy: item.accuracy,
        lastAttemptAt: item.lastAttemptAt,
        attempts: item.attempts,
      );

      recommendations.add(
        RevisionRecommendation(
          conceptId: item.conceptId,
          lessonId: item.lessonId,
          title: item.conceptId,
          priority: priority,
          status: item.status,
          reason: recommendationReason(item),
        ),
      );
    }

    recommendations.sort((a, b) => b.priority.compareTo(a.priority));

    return recommendations;
  }

  ConceptMastery _masteryFromRows(
    String conceptId,
    List<Map<String, Object?>> rows,
  ) {
    var correctCount = 0;
    final correctResults = <bool>[];
    DateTime? lastAttemptAt;

    for (final row in rows) {
      final isCorrect = row['is_correct'] == 1;
      correctResults.add(isCorrect);
      if (isCorrect) {
        correctCount++;
      }

      final attemptedAt = row['attempted_at'] as int?;
      if (attemptedAt != null) {
        lastAttemptAt = DateTime.fromMillisecondsSinceEpoch(attemptedAt);
      }
    }

    final attempts = rows.length;
    final lessonId = rows.isEmpty ? '' : rows.last['lesson_id'] as String;
    final accuracy = attempts == 0 ? 0.0 : correctCount / attempts;
    final mastery = weightedMastery(correctResults);

    return ConceptMastery(
      conceptId: conceptId,
      lessonId: lessonId,
      attempts: attempts,
      correct: correctCount,
      mastery: mastery,
      accuracy: accuracy,
      status: masteryStatusFromAccuracy(accuracy, attempts),
      lastAttemptAt: lastAttemptAt,
    );
  }
}
