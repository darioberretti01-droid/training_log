import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'user_exercise_database.g.dart';

class UserExercises extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  BoolColumn get isOverride =>
      boolean().named('is_override').withDefault(const Constant(false))();

  TextColumn get standardExerciseId =>
      text().named('standard_exercise_id').nullable().unique()();

  IntColumn get createdAt => integer().named('created_at')();

  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class UserExerciseLabels extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().unique()();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class UserExerciseLabelLinks extends Table {
  TextColumn get exerciseId => text()
      .named('exercise_id')
      .references(UserExercises, #id, onDelete: KeyAction.cascade)();

  TextColumn get labelId => text()
      .named('label_id')
      .references(UserExerciseLabels, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>>? get primaryKey => {exerciseId, labelId};
}

class HiddenStandardLabels extends Table {
  TextColumn get labelName => text().named('label_name')();

  @override
  Set<Column<Object>>? get primaryKey => {labelName};
}

class HiddenStandardExercises extends Table {
  TextColumn get standardExerciseId =>
      text().named('standard_exercise_id')();

  @override
  Set<Column<Object>>? get primaryKey => {standardExerciseId};
}

@DriftDatabase(
  tables: [
    UserExercises,
    UserExerciseLabels,
    UserExerciseLabelLinks,
    HiddenStandardLabels,
    HiddenStandardExercises,
  ],
)
class UserExerciseDatabase extends _$UserExerciseDatabase {
  UserExerciseDatabase([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(hiddenStandardLabels);
      }
      if (from < 3) {
        await m.createTable(hiddenStandardExercises);
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
      final file = File(p.join(directory.path, 'training_log_user_exercises.sqlite'));
      return NativeDatabase.createInBackground(file);
    } catch (_) {
      return NativeDatabase.memory();
    }
  });
}
