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

  TextColumn get splitId => text().named('split_id').nullable()();

  IntColumn get dayIndex => integer().named('day_index').nullable()();

  TextColumn get sessionName => text().named('session_name').nullable()();

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

class Splits extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get scheduleMode =>
      text().named('schedule_mode').withDefault(const Constant('sequence'))();

  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(false))();

  IntColumn get createdAt => integer().named('created_at')();

  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class DayPlans extends Table {
  TextColumn get id => text()();

  TextColumn get splitId => text()
      .named('split_id')
      .references(Splits, #id, onDelete: KeyAction.cascade)();

  IntColumn get dayIndex => integer().named('day_index')();

  TextColumn get title => text()();

  IntColumn get createdAt => integer().named('created_at')();

  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column<Object>>? get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE(split_id, day_index)'];
}

class PlannedExercises extends Table {
  TextColumn get id => text()();

  TextColumn get dayPlanId => text()
      .named('day_plan_id')
      .references(DayPlans, #id, onDelete: KeyAction.cascade)();

  TextColumn get exerciseId =>
      text().named('exercise_id').references(Exercises, #id)();

  IntColumn get orderIndex => integer().named('order_index')();

  IntColumn get targetSets => integer().named('target_sets')();

  IntColumn get repMin => integer().named('rep_min')();

  IntColumn get repMax => integer().named('rep_max')();

  IntColumn get restSeconds => integer().named('rest_seconds').nullable()();

  RealColumn get targetRpe => real().named('target_rpe').nullable()();

  IntColumn get createdAt => integer().named('created_at')();

  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column<Object>>? get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'UNIQUE(day_plan_id, order_index)',
    'CHECK (target_sets > 0)',
    'CHECK (rep_min > 0)',
    'CHECK (rep_max >= rep_min)',
    'CHECK (rest_seconds IS NULL OR rest_seconds >= 0)',
    'CHECK (target_rpe IS NULL OR (target_rpe >= 0 AND target_rpe <= 10))',
  ];
}

@DriftDatabase(
  tables: [
    Exercises,
    ExerciseLabels,
    ExerciseLabelLinks,
    WorkoutSessions,
    PerformedSets,
    Splits,
    DayPlans,
    PlannedExercises,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(splits);
        await m.createTable(dayPlans);
        await m.createTable(plannedExercises);
      }
      if (from < 3) {
        await m.addColumn(workoutSessions, workoutSessions.splitId);
        await m.addColumn(workoutSessions, workoutSessions.dayIndex);
        await m.addColumn(workoutSessions, workoutSessions.sessionName);
        if (from >= 2) {
          await m.addColumn(splits, splits.scheduleMode);
        }
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );
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
