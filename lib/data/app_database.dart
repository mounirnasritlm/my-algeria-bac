import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user_progress.dart';

class ProgressDatabase {
  ProgressDatabase._();

  static final ProgressDatabase instance = ProgressDatabase._();

  static const _databaseName = 'user_progress.db';
  static const _databaseVersion = 8;

  /// Current schema version, exposed for diagnostics (developer tools).
  static const int databaseVersion = _databaseVersion;

  Future<Database>? _database;

  Future<Database> get database {
    return _database ??= _open();
  }

  /// Drops the cached database future so tests can re-open against a fresh
  /// FakeAsync zone between cases.
  @visibleForTesting
  static void resetForTesting() {
    instance._database = null;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute(
      '''
      CREATE TABLE lessons (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        questions_answered INTEGER NOT NULL,
        questions_correct INTEGER NOT NULL,
        xp_earned INTEGER NOT NULL,
        accuracy REAL NOT NULL,
        updated_at INTEGER NOT NULL
      )
      ''',
    );
    await _createAttemptTables(db);
    await _createV3Tables(db);
    await _createV4Tables(db);
    await _createV5Tables(db);
    await _createV7Tables(db);
    await _createV8Tables(db);
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createAttemptTables(db);
    }
    if (oldVersion < 3) {
      await _createV3Tables(db);
    }
    if (oldVersion < 4) {
      await _createV4Tables(db);
    }
    if (oldVersion < 5) {
      await _createV5Tables(db);
    }
    if (oldVersion < 6) {
      await _addColumnIfMissing(
        db,
        'concept_attempts',
        'source_type',
        "TEXT NOT NULL DEFAULT 'quiz'",
      );
      await _addColumnIfMissing(
        db,
        'concept_attempts',
        'response_time_seconds',
        'INTEGER',
      );
    }
    if (oldVersion < 7) {
      await _createV7Tables(db);
    }
    if (oldVersion < 8) {
      await _createV8Tables(db);
    }
  }

  /// Adds a column only if it does not already exist, so upgrades that also
  /// recreate the table (oldVersion < 2) do not crash on a duplicate column.
  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final names = columns.map((c) => c['name']).toSet();
    if (!names.contains(column)) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future<void> _createAttemptTables(Database db) async {
    await db.execute(
      '''
      CREATE TABLE question_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id TEXT NOT NULL,
        lesson_id TEXT NOT NULL,
        concept_id TEXT NOT NULL,
        selected_answer INTEGER,
        correct_answer INTEGER,
        is_correct INTEGER NOT NULL,
        attempted_at INTEGER NOT NULL
      )
      ''',
    );
    await db.execute(
      '''
      CREATE TABLE concept_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        concept_id TEXT NOT NULL,
        lesson_id TEXT NOT NULL,
        question_id TEXT NOT NULL,
        is_correct INTEGER NOT NULL,
        source_type TEXT NOT NULL DEFAULT 'quiz',
        response_time_seconds INTEGER,
        attempted_at INTEGER NOT NULL
      )
      ''',
    );
  }

  Future<void> _createV3Tables(Database db) async {
    await db.execute(
      '''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
      ''',
    );
    await db.execute(
      '''
      CREATE TABLE exam_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id TEXT NOT NULL,
        score_on_20 REAL NOT NULL,
        correct_count INTEGER NOT NULL,
        total_questions INTEGER NOT NULL,
        time_used_seconds INTEGER NOT NULL,
        completed_at INTEGER NOT NULL
      )
      ''',
    );
  }

  /// Single XP ledger: every XP award (quiz, mission, streak, badge) is an
  /// immutable event, so total XP is a sum — never stored ambiguously.
  Future<void> _createV4Tables(Database db) async {
    await db.execute(
      '''
      CREATE TABLE xp_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reason TEXT NOT NULL,
        amount INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
      ''',
    );
  }

  Future<void> insertXpEvent({
    required String reason,
    required int amount,
  }) async {
    final db = await database;

    await db.insert(
      'xp_events',
      {
        'reason': reason,
        'amount': amount,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<int> getTotalXpEvents() async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM xp_events',
    );

    return (result.first['total'] as num).toInt();
  }

  /// Autosave for exam sessions: a running session can be resumed after the
  /// app is closed. Answers live per (session, question).
  Future<void> _createV5Tables(Database db) async {
    await db.execute(
      '''
      CREATE TABLE exam_sessions (
        id TEXT PRIMARY KEY,
        exam_id TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        status TEXT NOT NULL,
        current_index INTEGER NOT NULL,
        flagged TEXT NOT NULL,
        completed_at INTEGER
      )
      ''',
    );
    await db.execute(
      '''
      CREATE TABLE exam_session_answers (
        session_id TEXT NOT NULL,
        question_id TEXT NOT NULL,
        selected_index INTEGER,
        PRIMARY KEY (session_id, question_id)
      )
      ''',
    );
  }

  /// Streak 2.0: one row per completed qualifying activity. The unique
  /// activity id prevents the same finished session from ever being recorded
  /// twice (double taps, rebuilds, auto-resubmits).
  Future<void> _createV7Tables(Database db) async {
    await db.execute(
      '''
      CREATE TABLE streak_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_id TEXT NOT NULL UNIQUE,
        activity_type TEXT NOT NULL,
        completed_at INTEGER NOT NULL,
        xp_earned INTEGER NOT NULL,
        minutes INTEGER NOT NULL
      )
      ''',
    );
  }

  /// Achievements: one row per unlocked achievement, so an achievement is
  /// awarded exactly once (unique type) and never loses its XP.
  Future<void> _createV8Tables(Database db) async {
    await db.execute(
      '''
      CREATE TABLE achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        icon TEXT NOT NULL,
        xp_reward INTEGER NOT NULL,
        unlocked_at INTEGER NOT NULL
      )
      ''',
    );
  }

  Future<bool> insertAchievement({
    required String type,
    required String title,
    required String description,
    required String icon,
    required int xpReward,
  }) async {
    final db = await database;

    final result = await db.insert(
      'achievements',
      {
        'type': type,
        'title': title,
        'description': description,
        'icon': icon,
        'xp_reward': xpReward,
        'unlocked_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    // 0 means the row already existed (unique type) and was ignored.
    return result != 0;
  }

  Future<List<Map<String, Object?>>> getAllAchievements() async {
    final db = await database;
    return db.query('achievements', orderBy: 'unlocked_at ASC');
  }

  Future<String?> getSetting(String key) async {
    final db = await database;

    final result = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;

    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProgress> getOrCreate() async {
    final db = await database;

    final result = await db.query(
      'lessons',
      columns: [
        'id',
        'title',
        'questions_answered',
        'questions_correct',
        'xp_earned',
        'accuracy',
        'updated_at',
      ],
      orderBy: 'updated_at DESC',
    );

    if (result.isEmpty) {
      return UserProgress.empty();
    }

    return _userProgressFromMap(result);
  }

  Future<UserProgress> updateOrInsert({
    required UserProgress progress,
  }) async {
    final db = await database;

    final batch = db.batch();

    for (final lesson in progress.lessons) {
      final lessonResult = await db.query(
        'lessons',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [lesson.id],
      );

      final map = _lessonToMap(lesson);

      if (lessonResult.isEmpty) {
        batch.insert('lessons', map);
      } else {
        batch.update(
          'lessons',
          map,
          where: 'id = ?',
          whereArgs: [lesson.id],
        );
      }
    }

    await batch.commit(noResult: true);

    return progress;
  }

  Map<String, Object?> _lessonToMap(LessonProgress lesson) {
    return {
      'id': lesson.id,
      'title': lesson.title,
      'questions_answered': lesson.questionsAnswered,
      'questions_correct': lesson.questionsCorrect,
      'xp_earned': lesson.xpEarned,
      'accuracy': lesson.accuracy,
      'updated_at': lesson.updatedAt.millisecondsSinceEpoch,
    };
  }

  UserProgress _userProgressFromMap(List<Map<String, Object?>> rows) {
    final lessons = rows.map(_lessonFromMap).toList();

    return UserProgress.fromLessons(
      lessons: lessons,
    );
  }

  LessonProgress _lessonFromMap(Map<String, Object?> map) {
    final answered = (map['questions_answered'] as num).toInt();
    final correct = (map['questions_correct'] as num).toInt();
    final accuracy = (map['accuracy'] as num).toDouble();

    return LessonProgress(
      id: map['id'] as String,
      title: map['title'] as String,
      questionsAnswered: answered,
      questionsCorrect: correct,
      xpEarned: (map['xp_earned'] as num).toInt(),
      accuracy: accuracy,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updated_at'] as num).toInt(),
      ),
    );
  }
}
