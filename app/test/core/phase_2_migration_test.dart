import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:training_log_app/core/db/app_database.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('training_log_migration_');
    dbFile = File(p.join(tempDir.path, 'migration_test.sqlite'));
  });

  tearDown(() async {
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('migrates v1 database to v2 and preserves phase 1 data', () async {
    final v1Executor = NativeDatabase(dbFile);
    final v1Db = AppDatabase(v1Executor);

    // Simulate a pre-phase-2 database schema at user_version=1.
    await v1Db.customStatement('DROP TABLE IF EXISTS planned_exercises;');
    await v1Db.customStatement('DROP TABLE IF EXISTS day_plans;');
    await v1Db.customStatement('DROP TABLE IF EXISTS splits;');

    await v1Db.customStatement('DROP TABLE IF EXISTS performed_sets;');
    await v1Db.customStatement('DROP TABLE IF EXISTS workout_sessions;');
    await v1Db.customStatement('DROP TABLE IF EXISTS exercise_label_links;');
    await v1Db.customStatement('DROP TABLE IF EXISTS exercise_labels;');
    await v1Db.customStatement('DROP TABLE IF EXISTS exercises;');

    await v1Db.customStatement('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        is_seeded INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
    await v1Db.customStatement('''
      CREATE TABLE exercise_labels (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL UNIQUE
      );
    ''');
    await v1Db.customStatement('''
      CREATE TABLE exercise_label_links (
        exercise_id TEXT NOT NULL REFERENCES exercises(id),
        label_id TEXT NOT NULL REFERENCES exercise_labels(id),
        PRIMARY KEY (exercise_id, label_id)
      );
    ''');
    await v1Db.customStatement('''
      CREATE TABLE workout_sessions (
        id TEXT PRIMARY KEY NOT NULL,
        session_type TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        ended_at INTEGER NOT NULL
      );
    ''');
    await v1Db.customStatement('''
      CREATE TABLE performed_sets (
        id TEXT PRIMARY KEY NOT NULL,
        session_id TEXT NOT NULL REFERENCES workout_sessions(id),
        exercise_id TEXT NOT NULL REFERENCES exercises(id),
        set_index INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        rest_seconds INTEGER NULL,
        rpe REAL NULL,
        performed_at INTEGER NOT NULL
      );
    ''');
    await v1Db.customStatement('PRAGMA user_version = 1;');

    await v1Db.customStatement('''
      INSERT INTO exercises (id, name, is_seeded, created_at, updated_at)
      VALUES ('bench_press', 'Barbell Bench Press', 1, 1000, 1000);
    ''');
    await v1Db.customStatement('''
      INSERT INTO workout_sessions (id, session_type, started_at, ended_at)
      VALUES ('session_1', 'quick', 1000, 1100);
    ''');
    await v1Db.customStatement('''
      INSERT INTO performed_sets (
        id, session_id, exercise_id, set_index, reps, weight_kg, performed_at
      ) VALUES ('set_1', 'session_1', 'bench_press', 1, 8, 60.0, 1100);
    ''');

    await v1Db.close();

    final upgradedDb = AppDatabase(NativeDatabase(dbFile));
    final versionRow = await upgradedDb
        .customSelect('PRAGMA user_version;')
        .getSingle();
    final tableRows = await upgradedDb.customSelect('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table' AND name IN ('splits', 'day_plans', 'planned_exercises');
    ''').get();
    final exercisesCountRow = await upgradedDb
        .customSelect('SELECT COUNT(*) AS c FROM exercises;')
        .getSingle();
    final setsCountRow = await upgradedDb
        .customSelect('SELECT COUNT(*) AS c FROM performed_sets;')
        .getSingle();

    expect(versionRow.read<int>('user_version'), 2);
    expect(tableRows, hasLength(3));
    expect(exercisesCountRow.read<int>('c'), 1);
    expect(setsCountRow.read<int>('c'), 1);

    await upgradedDb.close();
  });
}
