import 'package:drift/drift.dart';

import '../../core/db/app_database.dart';
import '../../core/db/seed_data.dart';
import '../../core/models/exercise_with_labels.dart';

abstract class ExerciseRepository {
  Stream<List<ExerciseWithLabels>> watchExercises();

  Future<ExerciseWithLabels?> getById(String id);

  Future<void> seedIfEmpty();
}

class DriftExerciseRepository implements ExerciseRepository {
  DriftExerciseRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<ExerciseWithLabels>> watchExercises() {
    final query =
        _db.select(_db.exercises).join([
            leftOuterJoin(
              _db.exerciseLabelLinks,
              _db.exerciseLabelLinks.exerciseId.equalsExp(_db.exercises.id),
            ),
            leftOuterJoin(
              _db.exerciseLabels,
              _db.exerciseLabels.id.equalsExp(_db.exerciseLabelLinks.labelId),
            ),
          ])
          ..orderBy([
            OrderingTerm(expression: _db.exercises.name),
            OrderingTerm(expression: _db.exerciseLabels.name),
          ]);

    return query.watch().map(_mapJoinedRows);
  }

  @override
  Future<ExerciseWithLabels?> getById(String id) async {
    final query =
        _db.select(_db.exercises).join([
            leftOuterJoin(
              _db.exerciseLabelLinks,
              _db.exerciseLabelLinks.exerciseId.equalsExp(_db.exercises.id),
            ),
            leftOuterJoin(
              _db.exerciseLabels,
              _db.exerciseLabels.id.equalsExp(_db.exerciseLabelLinks.labelId),
            ),
          ])
          ..where(_db.exercises.id.equals(id))
          ..orderBy([
            OrderingTerm(expression: _db.exerciseLabels.name),
          ]);

    final rows = await query.get();
    if (rows.isEmpty) {
      return null;
    }

    return _mapJoinedRows(rows).first;
  }

  @override
  Future<void> seedIfEmpty() async {
    final countExpression = _db.exercises.id.count();
    final countRow =
        await (_db.selectOnly(_db.exercises)..addColumns([countExpression]))
            .getSingle();
    final count = countRow.read(countExpression) ?? 0;
    if (count > 0) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final uniqueLabels = <String>{};
    for (final exercise in seededExercises) {
      uniqueLabels.addAll(exercise.labels);
    }

    await _db.transaction(() async {
      for (final labelName in uniqueLabels.toList()..sort()) {
        await _db.into(_db.exerciseLabels).insert(
              ExerciseLabelsCompanion.insert(
                id: labelIdFromName(labelName),
                name: labelName,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }

      for (final exercise in seededExercises) {
        await _db.into(_db.exercises).insert(
              ExercisesCompanion.insert(
                id: exercise.id,
                name: exercise.name,
                createdAt: now,
                updatedAt: now,
                isSeeded: const Value(true),
              ),
              mode: InsertMode.insertOrIgnore,
            );

        for (final labelName in exercise.labels) {
          await _db.into(_db.exerciseLabelLinks).insert(
                ExerciseLabelLinksCompanion.insert(
                  exerciseId: exercise.id,
                  labelId: labelIdFromName(labelName),
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
      }
    });
  }

  List<ExerciseWithLabels> _mapJoinedRows(
    List<TypedResult> rows,
  ) {
    final grouped = <String, _ExerciseAccumulator>{};

    for (final row in rows) {
      final exercise = row.readTable(_db.exercises);
      final label = row.readTableOrNull(_db.exerciseLabels);

      final entry = grouped.putIfAbsent(
        exercise.id,
        () => _ExerciseAccumulator(id: exercise.id, name: exercise.name),
      );

      if (label != null && !entry.labels.contains(label.name)) {
        entry.labels.add(label.name);
      }
    }

    return grouped.values
        .map(
          (entry) => ExerciseWithLabels(
            id: entry.id,
            name: entry.name,
            labels: List.unmodifiable(entry.labels),
          ),
        )
        .toList(growable: false);
  }
}

class _ExerciseAccumulator {
  _ExerciseAccumulator({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
  final List<String> labels = [];
}
