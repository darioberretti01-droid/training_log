import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';
import '../../core/models/logged_set_input.dart';

class WorkoutSessionMode {
  static const String quick = 'quick';
  static const String splitDay = 'split_day';
  static const String free = 'free';

  static bool isSupported(String mode) {
    return mode == quick || mode == splitDay || mode == free;
  }
}

class WorkoutExerciseLogInput {
  const WorkoutExerciseLogInput({required this.exerciseId, required this.sets});

  final String exerciseId;
  final List<LoggedSetInput> sets;
}

abstract class QuickWorkoutRepository {
  Future<String> saveQuickWorkout({
    required String exerciseId,
    required DateTime startedAt,
    required DateTime endedAt,
    required List<LoggedSetInput> sets,
  });

  Future<String> saveWorkoutSession({
    required String mode,
    required DateTime startedAt,
    required DateTime endedAt,
    required List<WorkoutExerciseLogInput> exercises,
    String? splitId,
    int? dayIndex,
    String? sessionName,
  });

  Future<PerformedSet?> getBestSetForExercise(String exerciseId);

  Future<PerformedSet?> getBestSetForExercises(List<String> exerciseIds);

  Future<PerformedSet?> getLastSetForExercises(List<String> exerciseIds);

  Future<List<PerformedSet>> getRecentSetsForExercise(
    String exerciseId, {
    int limit = 30,
  });

  Future<List<ExerciseSessionHistoryEntry>> getRecentSessionsForExercise(
    String exerciseId, {
    int sessionLimit = 12,
  });

  Future<List<ExerciseSessionHistoryEntry>> getRecentSessionsForExercises(
    List<String> exerciseIds, {
    int sessionLimit = 12,
  });

  Future<List<HomeSessionOverviewEntry>> getRecentSessionsOverview({
    int sessionLimit = 8,
    String? sessionType,
    String? splitId,
  });

  Future<HomeSessionOverviewEntry?> getLastSession({
    String? sessionType,
    String? splitId,
  });

  Future<WorkoutSessionDetails?> getSessionDetails(String sessionId);

  Future<void> updateWorkoutSession({
    required String sessionId,
    required DateTime endedAt,
    required List<WorkoutExerciseLogInput> exercises,
    String? sessionName,
  });

  Future<void> deleteWorkoutSession(String sessionId);
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
    this.sessionName,
    this.splitId,
    this.dayIndex,
  });

  final WorkoutSession session;
  final List<HomeSessionExerciseSummary> exercises;
  final int totalSets;
  final String? sessionName;
  final String? splitId;
  final int? dayIndex;
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

class WorkoutSessionDetails {
  const WorkoutSessionDetails({required this.session, required this.exercises});

  final WorkoutSession session;
  final List<WorkoutSessionExerciseDetails> exercises;

  int get totalSets {
    var total = 0;
    for (final exercise in exercises) {
      total += exercise.sets.length;
    }
    return total;
  }
}

class WorkoutSessionExerciseDetails {
  const WorkoutSessionExerciseDetails({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });

  final String exerciseId;
  final String exerciseName;
  final List<WorkoutSessionSetDetails> sets;
}

class WorkoutSessionSetDetails {
  const WorkoutSessionSetDetails({
    required this.setIndex,
    required this.reps,
    required this.weightKg,
    this.restSeconds,
    this.rpe,
  });

  final int setIndex;
  final int reps;
  final double weightKg;
  final int? restSeconds;
  final double? rpe;
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
    return saveWorkoutSession(
      mode: WorkoutSessionMode.quick,
      startedAt: startedAt,
      endedAt: endedAt,
      sessionName: null,
      exercises: [WorkoutExerciseLogInput(exerciseId: exerciseId, sets: sets)],
    );
  }

  @override
  Future<String> saveWorkoutSession({
    required String mode,
    required DateTime startedAt,
    required DateTime endedAt,
    required List<WorkoutExerciseLogInput> exercises,
    String? splitId,
    int? dayIndex,
    String? sessionName,
  }) async {
    final normalizedMode = mode.trim();
    if (!WorkoutSessionMode.isSupported(normalizedMode)) {
      throw ArgumentError('Unsupported workout session mode: $mode');
    }
    if (endedAt.isBefore(startedAt)) {
      throw ArgumentError('End time cannot be before start time.');
    }
    if (normalizedMode == WorkoutSessionMode.splitDay) {
      if (splitId == null || splitId.trim().isEmpty) {
        throw ArgumentError('splitId is required for split_day mode.');
      }
      if (dayIndex == null || dayIndex <= 0) {
        throw ArgumentError(
          'dayIndex must be greater than zero for split_day mode.',
        );
      }
    }

    final normalizedExercises = <WorkoutExerciseLogInput>[];
    for (final exercise in exercises) {
      final normalizedExerciseId = exercise.exerciseId.trim();
      if (normalizedExerciseId.isEmpty) {
        throw ArgumentError('exerciseId cannot be empty.');
      }
      if (exercise.sets.isEmpty) {
        continue;
      }
      for (final set in exercise.sets) {
        _validateSet(set);
      }
      normalizedExercises.add(
        WorkoutExerciseLogInput(
          exerciseId: normalizedExerciseId,
          sets: List.unmodifiable(exercise.sets),
        ),
      );
    }
    if (normalizedExercises.isEmpty) {
      throw ArgumentError('At least one set is required.');
    }

    final sessionId = _uuid.v4();
    final startedAtMs = startedAt.millisecondsSinceEpoch;
    final endedAtMs = endedAt.millisecondsSinceEpoch;
    final normalizedSessionName = _normalizeOptionalString(sessionName);
    final normalizedSplitId = _normalizeOptionalString(splitId);

    await _db.transaction(() async {
      await _db
          .into(_db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              id: sessionId,
              sessionType: normalizedMode,
              startedAt: startedAtMs,
              endedAt: endedAtMs,
              splitId: Value(normalizedSplitId),
              dayIndex: Value(dayIndex),
              sessionName: Value(normalizedSessionName),
            ),
          );

      for (final exercise in normalizedExercises) {
        for (var index = 0; index < exercise.sets.length; index++) {
          final set = exercise.sets[index];
          await _db
              .into(_db.performedSets)
              .insert(
                PerformedSetsCompanion.insert(
                  id: _uuid.v4(),
                  sessionId: sessionId,
                  exerciseId: exercise.exerciseId,
                  setIndex: index + 1,
                  reps: set.reps,
                  weightKg: set.weightKg,
                  performedAt: endedAtMs,
                  restSeconds: Value(set.restSeconds),
                  rpe: Value(set.rpe),
                ),
              );
        }
      }
    });

    return sessionId;
  }

  @override
  Future<PerformedSet?> getBestSetForExercise(String exerciseId) {
    return getBestSetForExercises([exerciseId]);
  }

  @override
  Future<PerformedSet?> getBestSetForExercises(List<String> exerciseIds) {
    final normalizedIds = _normalizeExerciseIds(exerciseIds);
    if (normalizedIds.isEmpty) {
      return Future.value(null);
    }

    final query = _db.select(_db.performedSets)
      ..where((tbl) => _exerciseIdFilter(tbl, normalizedIds))
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.weightKg),
        (tbl) => OrderingTerm.desc(tbl.reps),
        (tbl) => OrderingTerm.desc(tbl.performedAt),
      ])
      ..limit(1);

    return query.getSingleOrNull();
  }

  @override
  Future<PerformedSet?> getLastSetForExercises(List<String> exerciseIds) {
    final normalizedIds = _normalizeExerciseIds(exerciseIds);
    if (normalizedIds.isEmpty) {
      return Future.value(null);
    }

    final query = _db.select(_db.performedSets)
      ..where((tbl) => _exerciseIdFilter(tbl, normalizedIds))
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.performedAt),
        (tbl) => OrderingTerm.desc(tbl.setIndex),
        (tbl) => OrderingTerm.desc(tbl.id),
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
  }) {
    return getRecentSessionsForExercises([
      exerciseId,
    ], sessionLimit: sessionLimit);
  }

  @override
  Future<List<ExerciseSessionHistoryEntry>> getRecentSessionsForExercises(
    List<String> exerciseIds, {
    int sessionLimit = 12,
  }) async {
    final normalizedIds = _normalizeExerciseIds(exerciseIds);
    if (normalizedIds.isEmpty) {
      return const [];
    }

    final query =
        _db.select(_db.performedSets).join([
            innerJoin(
              _db.workoutSessions,
              _db.workoutSessions.id.equalsExp(_db.performedSets.sessionId),
            ),
          ])
          ..where(_db.performedSets.exerciseId.isIn(normalizedIds))
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
    String? sessionType,
    String? splitId,
  }) async {
    final normalizedSessionType = _normalizeOptionalString(sessionType);
    final normalizedSplitId = _normalizeOptionalString(splitId);

    final query = _db.select(_db.performedSets).join([
      innerJoin(
        _db.workoutSessions,
        _db.workoutSessions.id.equalsExp(_db.performedSets.sessionId),
      ),
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.performedSets.exerciseId),
      ),
    ]);

    final where = _buildOverviewFilter(
      sessionType: normalizedSessionType,
      splitId: normalizedSplitId,
    );
    if (where != null) {
      query.where(where);
    }

    query.orderBy([
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
            sessionName: entry.session.sessionName,
            splitId: entry.session.splitId,
            dayIndex: entry.session.dayIndex,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<HomeSessionOverviewEntry?> getLastSession({
    String? sessionType,
    String? splitId,
  }) async {
    final sessions = await getRecentSessionsOverview(
      sessionLimit: 1,
      sessionType: sessionType,
      splitId: splitId,
    );
    if (sessions.isEmpty) {
      return null;
    }
    return sessions.first;
  }

  @override
  Future<WorkoutSessionDetails?> getSessionDetails(String sessionId) async {
    final session = await (_db.select(
      _db.workoutSessions,
    )..where((tbl) => tbl.id.equals(sessionId))).getSingleOrNull();
    if (session == null) {
      return null;
    }

    final rows =
        await (_db.select(_db.performedSets).join([
                innerJoin(
                  _db.exercises,
                  _db.exercises.id.equalsExp(_db.performedSets.exerciseId),
                ),
              ])
              ..where(_db.performedSets.sessionId.equals(sessionId))
              ..orderBy([
                OrderingTerm.asc(_db.exercises.name),
                OrderingTerm.asc(_db.performedSets.exerciseId),
                OrderingTerm.asc(_db.performedSets.setIndex),
              ]))
            .get();

    final grouped = <String, _SessionExerciseAccumulator>{};
    final orderedExerciseIds = <String>[];

    for (final row in rows) {
      final set = row.readTable(_db.performedSets);
      final exercise = row.readTable(_db.exercises);
      final entry = grouped.putIfAbsent(exercise.id, () {
        orderedExerciseIds.add(exercise.id);
        return _SessionExerciseAccumulator(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
        );
      });
      entry.sets.add(
        WorkoutSessionSetDetails(
          setIndex: set.setIndex,
          reps: set.reps,
          weightKg: set.weightKg,
          restSeconds: set.restSeconds,
          rpe: set.rpe,
        ),
      );
    }

    final exercises = orderedExerciseIds
        .map((exerciseId) {
          final entry = grouped[exerciseId]!;
          return WorkoutSessionExerciseDetails(
            exerciseId: entry.exerciseId,
            exerciseName: entry.exerciseName,
            sets: List.unmodifiable(entry.sets),
          );
        })
        .toList(growable: false);

    return WorkoutSessionDetails(
      session: session,
      exercises: List.unmodifiable(exercises),
    );
  }

  @override
  Future<void> updateWorkoutSession({
    required String sessionId,
    required DateTime endedAt,
    required List<WorkoutExerciseLogInput> exercises,
    String? sessionName,
  }) async {
    final existing = await (_db.select(
      _db.workoutSessions,
    )..where((tbl) => tbl.id.equals(sessionId))).getSingleOrNull();
    if (existing == null) {
      throw ArgumentError('Session not found: $sessionId');
    }
    final endedAtMs = endedAt.millisecondsSinceEpoch;
    if (endedAtMs < existing.startedAt) {
      throw ArgumentError('End time cannot be before start time.');
    }

    final normalizedExercises = <WorkoutExerciseLogInput>[];
    for (final exercise in exercises) {
      final normalizedExerciseId = exercise.exerciseId.trim();
      if (normalizedExerciseId.isEmpty) {
        throw ArgumentError('exerciseId cannot be empty.');
      }
      final validSets = <LoggedSetInput>[];
      for (final set in exercise.sets) {
        _validateSet(set);
        validSets.add(set);
      }
      if (validSets.isEmpty) {
        continue;
      }
      normalizedExercises.add(
        WorkoutExerciseLogInput(
          exerciseId: normalizedExerciseId,
          sets: List.unmodifiable(validSets),
        ),
      );
    }
    if (normalizedExercises.isEmpty) {
      throw ArgumentError('At least one set is required.');
    }

    await _db.transaction(() async {
      await (_db.update(
        _db.workoutSessions,
      )..where((tbl) => tbl.id.equals(sessionId))).write(
        WorkoutSessionsCompanion(
          endedAt: Value(endedAtMs),
          sessionName: Value(_normalizeOptionalString(sessionName)),
        ),
      );

      await (_db.delete(
        _db.performedSets,
      )..where((tbl) => tbl.sessionId.equals(sessionId))).go();

      for (final exercise in normalizedExercises) {
        for (var index = 0; index < exercise.sets.length; index++) {
          final set = exercise.sets[index];
          await _db
              .into(_db.performedSets)
              .insert(
                PerformedSetsCompanion.insert(
                  id: _uuid.v4(),
                  sessionId: sessionId,
                  exerciseId: exercise.exerciseId,
                  setIndex: index + 1,
                  reps: set.reps,
                  weightKg: set.weightKg,
                  performedAt: endedAtMs,
                  restSeconds: Value(set.restSeconds),
                  rpe: Value(set.rpe),
                ),
              );
        }
      }
    });
  }

  @override
  Future<void> deleteWorkoutSession(String sessionId) async {
    final deleted = await _db.transaction(() async {
      await (_db.delete(
        _db.performedSets,
      )..where((tbl) => tbl.sessionId.equals(sessionId))).go();
      return (_db.delete(
        _db.workoutSessions,
      )..where((tbl) => tbl.id.equals(sessionId))).go();
    });
    if (deleted == 0) {
      throw ArgumentError('Session not found: $sessionId');
    }
  }

  void _validateSet(LoggedSetInput set) {
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

  String? _normalizeOptionalString(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Expression<bool>? _buildOverviewFilter({
    required String? sessionType,
    required String? splitId,
  }) {
    Expression<bool>? where;

    if (sessionType != null) {
      where = _db.workoutSessions.sessionType.equals(sessionType);
    }
    if (splitId != null) {
      final splitIdFilter = _db.workoutSessions.splitId.equals(splitId);
      where = where == null ? splitIdFilter : where & splitIdFilter;
    }

    return where;
  }

  Expression<bool> _exerciseIdFilter(
    $PerformedSetsTable tbl,
    List<String> exerciseIds,
  ) {
    if (exerciseIds.length == 1) {
      return tbl.exerciseId.equals(exerciseIds.first);
    }
    return tbl.exerciseId.isIn(exerciseIds);
  }

  List<String> _normalizeExerciseIds(List<String> exerciseIds) {
    final unique = <String>{};
    for (final id in exerciseIds) {
      final trimmed = id.trim();
      if (trimmed.isNotEmpty) {
        unique.add(trimmed);
      }
    }
    return unique.toList(growable: false);
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

class _SessionExerciseAccumulator {
  _SessionExerciseAccumulator({
    required this.exerciseId,
    required this.exerciseName,
  });

  final String exerciseId;
  final String exerciseName;
  final List<WorkoutSessionSetDetails> sets = [];
}
