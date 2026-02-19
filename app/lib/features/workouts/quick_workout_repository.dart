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

  Future<List<ExerciseSessionHistoryEntry>> getRecentSessionsForExercise(
    String exerciseId, {
    int sessionLimit = 12,
  });

  Future<List<HomeSessionOverviewEntry>> getRecentSessionsOverview({
    int sessionLimit = 8,
  });
}

class ExerciseSessionHistoryEntry {
  const ExerciseSessionHistoryEntry({
    required this.session,
    required this.sets,
  });

  final WorkoutSession session;
  final List<PerformedSet> sets;
}

class HomeSessionOverviewEntry {
  const HomeSessionOverviewEntry({
    required this.session,
    required this.exercises,
    required this.totalSets,
  });

  final WorkoutSession session;
  final List<HomeSessionExerciseSummary> exercises;
  final int totalSets;
}

class HomeSessionExerciseSummary {
  const HomeSessionExerciseSummary({
    required this.exerciseId,
    required this.exerciseName,
    required this.setCount,
  });

  final String exerciseId;
  final String exerciseName;
  final int setCount;
}

class DriftQuickWorkoutRepository implements QuickWorkoutRepository {
  DriftQuickWorkoutRepository(this._db, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

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
      await _db
          .into(_db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              id: sessionId,
              sessionType: 'quick',
              startedAt: startedAtMs,
              endedAt: endedAtMs,
            ),
          );

      for (var index = 0; index < sets.length; index++) {
        final set = sets[index];
        await _db
            .into(_db.performedSets)
            .insert(
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

  @override
  Future<List<ExerciseSessionHistoryEntry>> getRecentSessionsForExercise(
    String exerciseId, {
    int sessionLimit = 12,
  }) async {
    final query =
        _db.select(_db.performedSets).join([
            innerJoin(
              _db.workoutSessions,
              _db.workoutSessions.id.equalsExp(_db.performedSets.sessionId),
            ),
          ])
          ..where(_db.performedSets.exerciseId.equals(exerciseId))
          ..orderBy([
            OrderingTerm.desc(_db.workoutSessions.startedAt),
            OrderingTerm.asc(_db.performedSets.setIndex),
          ]);

    final rows = await query.get();
    final grouped = <String, _SessionAccumulator>{};
    final orderedSessionIds = <String>[];

    for (final row in rows) {
      final session = row.readTable(_db.workoutSessions);
      final set = row.readTable(_db.performedSets);

      if (!grouped.containsKey(session.id)) {
        if (orderedSessionIds.length >= sessionLimit) {
          break;
        }
        grouped[session.id] = _SessionAccumulator(session: session);
        orderedSessionIds.add(session.id);
      }

      grouped[session.id]!.sets.add(set);
    }

    return orderedSessionIds
        .map((id) {
          final entry = grouped[id]!;
          return ExerciseSessionHistoryEntry(
            session: entry.session,
            sets: List.unmodifiable(entry.sets),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<HomeSessionOverviewEntry>> getRecentSessionsOverview({
    int sessionLimit = 8,
  }) async {
    final query =
        _db.select(_db.performedSets).join([
            innerJoin(
              _db.workoutSessions,
              _db.workoutSessions.id.equalsExp(_db.performedSets.sessionId),
            ),
            innerJoin(
              _db.exercises,
              _db.exercises.id.equalsExp(_db.performedSets.exerciseId),
            ),
          ])
          ..where(_db.workoutSessions.sessionType.equals('quick'))
          ..orderBy([
            OrderingTerm.desc(_db.workoutSessions.startedAt),
            OrderingTerm.asc(_db.performedSets.setIndex),
            OrderingTerm.asc(_db.exercises.name),
            OrderingTerm.desc(_db.workoutSessions.id),
          ]);

    final rows = await query.get();
    final grouped = <String, _HomeSessionAccumulator>{};
    final orderedSessionIds = <String>[];

    for (final row in rows) {
      final session = row.readTable(_db.workoutSessions);
      final exercise = row.readTable(_db.exercises);

      if (!grouped.containsKey(session.id)) {
        if (orderedSessionIds.length >= sessionLimit) {
          break;
        }
        grouped[session.id] = _HomeSessionAccumulator(session: session);
        orderedSessionIds.add(session.id);
      }

      final accumulator = grouped[session.id]!;
      accumulator.totalSets += 1;
      accumulator.exerciseCounts.update(
        exercise.id,
        (existing) => existing..setCount += 1,
        ifAbsent: () => _HomeExerciseAccumulator(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          setCount: 1,
        ),
      );
    }

    return orderedSessionIds
        .map((id) {
          final entry = grouped[id]!;
          final exercises =
              entry.exerciseCounts.values
                  .map(
                    (exercise) => HomeSessionExerciseSummary(
                      exerciseId: exercise.exerciseId,
                      exerciseName: exercise.exerciseName,
                      setCount: exercise.setCount,
                    ),
                  )
                  .toList(growable: false)
                ..sort((a, b) {
                  final byCount = b.setCount.compareTo(a.setCount);
                  if (byCount != 0) {
                    return byCount;
                  }
                  return a.exerciseName.compareTo(b.exerciseName);
                });

          return HomeSessionOverviewEntry(
            session: entry.session,
            exercises: List.unmodifiable(exercises),
            totalSets: entry.totalSets,
          );
        })
        .toList(growable: false);
  }
}

class _SessionAccumulator {
  _SessionAccumulator({required this.session});

  final WorkoutSession session;
  final List<PerformedSet> sets = [];
}

class _HomeSessionAccumulator {
  _HomeSessionAccumulator({required this.session});

  final WorkoutSession session;
  final Map<String, _HomeExerciseAccumulator> exerciseCounts = {};
  int totalSets = 0;
}

class _HomeExerciseAccumulator {
  _HomeExerciseAccumulator({
    required this.exerciseId,
    required this.exerciseName,
    required this.setCount,
  });

  final String exerciseId;
  final String exerciseName;
  int setCount;
}
