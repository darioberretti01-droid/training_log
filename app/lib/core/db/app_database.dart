import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Exercises extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  BoolColumn get isSeeded =>
      boolean().named('is_seeded').withDefault(const Constant(true))();

  IntColumn get createdAt => integer().named('created_at')();

  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class ExerciseLabels extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().unique()();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class ExerciseLabelLinks extends Table {
  TextColumn get exerciseId =>
      text().named('exercise_id').references(Exercises, #id)();

  TextColumn get labelId =>
      text().named('label_id').references(ExerciseLabels, #id)();

  @override
  Set<Column<Object>>? get primaryKey => {exerciseId, labelId};
}

class WorkoutSessions extends Table {
  TextColumn get id => text()();

  TextColumn get sessionType => text().named('session_type')();

  IntColumn get startedAt => integer().named('started_at')();

  IntColumn get endedAt => integer().named('ended_at')();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class PerformedSets extends Table {
  TextColumn get id => text()();

  TextColumn get sessionId =>
      text().named('session_id').references(WorkoutSessions, #id)();

  TextColumn get exerciseId =>
      text().named('exercise_id').references(Exercises, #id)();

  IntColumn get setIndex => integer().named('set_index')();

  IntColumn get reps => integer()();

  RealColumn get weightKg => real().named('weight_kg')();

  IntColumn get restSeconds => integer().named('rest_seconds').nullable()();

  RealColumn get rpe => real().nullable()();

  IntColumn get performedAt => integer().named('performed_at')();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Exercises,
    ExerciseLabels,
    ExerciseLabelLinks,
    WorkoutSessions,
    PerformedSets,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(p.join(directory.path, 'training_log.sqlite'));
      return NativeDatabase.createInBackground(file);
    } catch (_) {
      // Widget tests and non-Flutter contexts can miss path_provider plugins.
      return NativeDatabase.memory();
    }
  });
}
