import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';
import '../../core/models/logged_set_input.dart';

abstract class QuickWorkoutRepository {
  Future<String> saveQuickWorkout({
    required String exerciseId,
    required DateTime startedAt,
    required DateTime endedAt,
    required List<LoggedSetInput> sets,
  });

  Future<PerformedSet?> getBestSetForExercise(String exerciseId);

  Future<List<PerformedSet>> getRecentSetsForExercise(
    String exerciseId, {
    int limit = 30,
  });
}

class DriftQuickWorkoutRepository implements QuickWorkoutRepository {
  DriftQuickWorkoutRepository(
    this._db, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Future<String> saveQuickWorkout({
    required String exerciseId,
    required DateTime startedAt,
    required DateTime endedAt,
    required List<LoggedSetInput> sets,
  }) async {
    if (sets.isEmpty) {
      throw ArgumentError('At least one set is required.');
    }

    for (final set in sets) {
      if (set.reps <= 0) {
        throw ArgumentError('Reps must be greater than zero.');
      }
      if (set.weightKg <= 0) {
        throw ArgumentError('Weight must be greater than zero.');
      }
      if (set.restSeconds != null && set.restSeconds! < 0) {
        throw ArgumentError('Rest seconds cannot be negative.');
      }
      if (set.rpe != null && (set.rpe! < 0 || set.rpe! > 10)) {
        throw ArgumentError('RPE must be between 0 and 10.');
      }
    }

    final sessionId = _uuid.v4();
    final startedAtMs = startedAt.millisecondsSinceEpoch;
    final endedAtMs = endedAt.millisecondsSinceEpoch;

    await _db.transaction(() async {
      await _db.into(_db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              id: sessionId,
              sessionType: 'quick',
              startedAt: startedAtMs,
              endedAt: endedAtMs,
            ),
          );

      for (var index = 0; index < sets.length; index++) {
        final set = sets[index];
        await _db.into(_db.performedSets).insert(
              PerformedSetsCompanion.insert(
                id: _uuid.v4(),
                sessionId: sessionId,
                exerciseId: exerciseId,
                setIndex: index + 1,
                reps: set.reps,
                weightKg: set.weightKg,
                performedAt: endedAtMs,
                restSeconds: Value(set.restSeconds),
                rpe: Value(set.rpe),
              ),
            );
      }
    });

    return sessionId;
  }

  @override
  Future<PerformedSet?> getBestSetForExercise(String exerciseId) {
    final query = _db.select(_db.performedSets)
      ..where((tbl) => tbl.exerciseId.equals(exerciseId))
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.weightKg),
        (tbl) => OrderingTerm.desc(tbl.reps),
        (tbl) => OrderingTerm.desc(tbl.performedAt),
      ])
      ..limit(1);

    return query.getSingleOrNull();
  }

  @override
  Future<List<PerformedSet>> getRecentSetsForExercise(
    String exerciseId, {
    int limit = 30,
  }) {
    final query = _db.select(_db.performedSets)
      ..where((tbl) => tbl.exerciseId.equals(exerciseId))
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.performedAt),
        (tbl) => OrderingTerm.asc(tbl.setIndex),
      ])
      ..limit(limit);

    return query.get();
  }
}
