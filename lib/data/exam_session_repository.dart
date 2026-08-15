import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/saved_exam_session.dart';
import 'app_database.dart';

/// Persists exam sessions so an interrupted paper can be resumed.
class ExamSessionRepository {
  final ProgressDatabase _database;

  ExamSessionRepository({
    ProgressDatabase? database,
  }) : _database = database ?? ProgressDatabase.instance;

  Future<SavedExamSession> createSession({
    required String examId,
    required int durationSeconds,
  }) async {
    final db = await _database.database;
    final now = DateTime.now();

    final session = SavedExamSession(
      id: 'session_${now.microsecondsSinceEpoch}',
      examId: examId,
      startedAt: now,
      durationSeconds: durationSeconds,
      status: SavedExamSessionStatus.inProgress,
      currentIndex: 0,
      answers: const {},
      flaggedQuestionIds: const {},
    );

    await db.insert('exam_sessions', session.toMap());

    return session;
  }

  /// The most recent in-progress session for an exam, or null.
  Future<SavedExamSession?> getInProgressSession(String examId) async {
    final db = await _database.database;

    final rows = await db.query(
      'exam_sessions',
      where: 'exam_id = ? AND status = ?',
      whereArgs: [examId, 'in_progress'],
      orderBy: 'started_at DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    final answers = await _loadAnswers(db, row['id'] as String);

    return SavedExamSession.fromMap(row, answers: answers);
  }

  Future<void> saveAnswer({
    required String sessionId,
    required String questionId,
    required int? selectedIndex,
  }) async {
    final db = await _database.database;

    await db.insert(
      'exam_session_answers',
      {
        'session_id': sessionId,
        'question_id': questionId,
        'selected_index': selectedIndex,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setCurrentIndex({
    required String sessionId,
    required int index,
  }) async {
    final db = await _database.database;

    await db.update(
      'exam_sessions',
      {'current_index': index},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> setFlags({
    required String sessionId,
    required Set<String> flaggedQuestionIds,
  }) async {
    final db = await _database.database;

    await db.update(
      'exam_sessions',
      {
        'flagged': jsonEncode(flaggedQuestionIds.toList()),
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> markSubmitted({required String sessionId}) async {
    final db = await _database.database;

    await db.update(
      'exam_sessions',
      {
        'status': 'submitted',
        'completed_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<Map<String, int>> _loadAnswers(
    Database db,
    String sessionId,
  ) async {
    final rows = await db.query(
      'exam_session_answers',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    final answers = <String, int>{};

    for (final row in rows) {
      final index = row['selected_index'] as int?;
      if (index != null) {
        answers[row['question_id'] as String] = index;
      }
    }

    return answers;
  }
}
