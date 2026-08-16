// Schema and migration tests for ProgressDatabase (v8).
//
// Run against a real SQLite engine through sqflite_common_ffi, so the
// CREATE/upgrade SQL actually executes. "Old version" states are built from
// the current v8 schema by dropping the tables that later versions added and
// downgrading PRAGMA user_version — this exercises the real upgrade branches
// without hand-recreating historical schemas.

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:my_algeria_bac/data/app_database.dart';

void main() {
  Future<String> dbPath() async =>
      p.join(await getDatabasesPath(), 'user_progress.db');

  Future<void> wipe() async {
    final db = await ProgressDatabase.instance.database;
    await db.close();
    ProgressDatabase.resetForTesting();
    await deleteDatabase(await dbPath());
  }

  Future<List<String>> tableNames(Database db) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
    );
    return rows.map((r) => r['name'] as String).toList();
  }

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    final db = await ProgressDatabase.instance.database;
    await db.close();
    ProgressDatabase.resetForTesting();
    await deleteDatabase(await dbPath());
  });

  const expectedTables = <String>[
    'lessons',
    'question_attempts',
    'concept_attempts',
    'app_settings',
    'exam_attempts',
    'xp_events',
    'exam_sessions',
    'exam_session_answers',
    'streak_activities',
    'achievements',
  ];

  test('fresh open creates the full v8 schema', () async {
    await wipe();

    final db = await ProgressDatabase.instance.database;
    expect(await db.getVersion(), 8);

    final tables = await tableNames(db);
    for (final table in expectedTables) {
      expect(tables, contains(table), reason: 'missing table: $table');
    }
  });

  test('upgrade from v1 preserves lessons and adds every later table',
      () async {
    await wipe();

    // Build a v1 state: only `lessons` remains, with a real row to prove data
    // survives the upgrade.
    final db = await ProgressDatabase.instance.database;
    for (final table in [
      'achievements',
      'streak_activities',
      'exam_session_answers',
      'exam_sessions',
      'xp_events',
      'exam_attempts',
      'app_settings',
      'concept_attempts',
      'question_attempts',
    ]) {
      await db.execute('DROP TABLE $table');
    }
    await db.insert('lessons', {
      'id': 'lesson_1',
      'title': 'Lesson 1',
      'questions_answered': 4,
      'questions_correct': 3,
      'xp_earned': 30,
      'accuracy': 0.75,
      'updated_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
    });
    await db.setVersion(1);
    await db.close();
    ProgressDatabase.resetForTesting();

    final reopened = await ProgressDatabase.instance.database;
    expect(await reopened.getVersion(), 8);

    final tables = await tableNames(reopened);
    for (final table in expectedTables) {
      expect(tables, contains(table), reason: 'missing table after v1 upgrade: $table');
    }

    final progress = await ProgressDatabase.instance.getOrCreate();
    expect(progress.lessons, hasLength(1));
    expect(progress.lessons.single.id, 'lesson_1');
    expect(progress.lessons.single.accuracy, 0.75);
  });

  test('upgrade from v7 adds only the achievements table', () async {
    await wipe();

    final db = await ProgressDatabase.instance.database;
    await db.execute('DROP TABLE achievements');
    await db.setVersion(7);
    await db.close();
    ProgressDatabase.resetForTesting();

    final reopened = await ProgressDatabase.instance.database;
    expect(await reopened.getVersion(), 8);

    final tables = await tableNames(reopened);
    expect(tables, contains('achievements'));

    // The restored table is fully usable.
    final inserted = await ProgressDatabase.instance.insertAchievement(
      type: 'first_exam',
      title: 'First exam',
      description: 'Finished a full paper.',
      icon: '🏆',
      xpReward: 50,
    );
    expect(inserted, isTrue);
  });
}
