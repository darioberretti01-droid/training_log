import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';

class SplitScheduleMode {
  static const String sequence = 'sequence';
  static const String weekday = 'weekday';

  static bool isSupported(String value) {
    return value == sequence || value == weekday;
  }
}

abstract class SplitRepository {
  Future<String> createSplit(SplitDraftInput input);

  Future<void> updateSplit(String splitId, SplitDraftInput input);

  Future<void> setActiveSplit(String splitId);

  Stream<List<SplitSummary>> watchSplits();

  Future<SplitDetails?> getSplitById(String splitId);

  Future<void> deleteSplit(String splitId);
}

class SplitDraftInput {
  const SplitDraftInput({
    required this.name,
    required this.days,
    this.scheduleMode = SplitScheduleMode.sequence,
  });

  final String name;
  final List<DayPlanDraftInput> days;
  final String scheduleMode;
}

class DayPlanDraftInput {
  const DayPlanDraftInput({
    required this.dayIndex,
    required this.title,
    required this.plannedExercises,
  });

  final int dayIndex;
  final String title;
  final List<PlannedExerciseDraftInput> plannedExercises;
}

class PlannedExerciseDraftInput {
  const PlannedExerciseDraftInput({
    required this.orderIndex,
    required this.exerciseId,
    required this.targetSets,
    required this.repMin,
    required this.repMax,
    this.restSeconds,
    this.targetRpe,
  });

  final int orderIndex;
  final String exerciseId;
  final int targetSets;
  final int repMin;
  final int repMax;
  final int? restSeconds;
  final double? targetRpe;
}

class SplitSummary {
  const SplitSummary({
    required this.id,
    required this.name,
    this.scheduleMode = SplitScheduleMode.sequence,
    required this.isActive,
    required this.dayCount,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String scheduleMode;
  final bool isActive;
  final int dayCount;
  final int updatedAt;
}

class SplitDetails {
  const SplitDetails({
    required this.id,
    required this.name,
    this.scheduleMode = SplitScheduleMode.sequence,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.days,
  });

  final String id;
  final String name;
  final String scheduleMode;
  final bool isActive;
  final int createdAt;
  final int updatedAt;
  final List<DayPlanDetails> days;
}

class DayPlanDetails {
  const DayPlanDetails({
    required this.id,
    required this.dayIndex,
    required this.title,
    required this.plannedExercises,
  });

  final String id;
  final int dayIndex;
  final String title;
  final List<PlannedExerciseDetails> plannedExercises;
}

class PlannedExerciseDetails {
  const PlannedExerciseDetails({
    required this.id,
    required this.orderIndex,
    required this.exerciseId,
    required this.exerciseName,
    required this.targetSets,
    required this.repMin,
    required this.repMax,
    required this.restSeconds,
    required this.targetRpe,
  });

  final String id;
  final int orderIndex;
  final String exerciseId;
  final String exerciseName;
  final int targetSets;
  final int repMin;
  final int repMax;
  final int? restSeconds;
  final double? targetRpe;
}

class DriftSplitRepository implements SplitRepository {
  DriftSplitRepository(this._db, {Uuid? uuid, DateTime Function()? now})
    : _uuid = uuid ?? const Uuid(),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final Uuid _uuid;
  final DateTime Function() _now;

  @override
  Future<String> createSplit(SplitDraftInput input) async {
    _validateSplitDraft(input);

    final splitId = _uuid.v4();
    final nowMs = _now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      await _db
          .into(_db.splits)
          .insert(
            SplitsCompanion.insert(
              id: splitId,
              name: input.name.trim(),
              scheduleMode: Value(input.scheduleMode),
              isActive: const Value(false),
              createdAt: nowMs,
              updatedAt: nowMs,
            ),
          );

      final orderedDays = [...input.days]
        ..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));
      for (final day in orderedDays) {
        final dayPlanId = _uuid.v4();
        await _db
            .into(_db.dayPlans)
            .insert(
              DayPlansCompanion.insert(
                id: dayPlanId,
                splitId: splitId,
                dayIndex: day.dayIndex,
                title: day.title.trim(),
                createdAt: nowMs,
                updatedAt: nowMs,
              ),
            );

        final orderedExercises = [...day.plannedExercises]
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        for (final exercise in orderedExercises) {
          await _db
              .into(_db.plannedExercises)
              .insert(
                PlannedExercisesCompanion.insert(
                  id: _uuid.v4(),
                  dayPlanId: dayPlanId,
                  exerciseId: exercise.exerciseId,
                  orderIndex: exercise.orderIndex,
                  targetSets: exercise.targetSets,
                  repMin: exercise.repMin,
                  repMax: exercise.repMax,
                  restSeconds: Value(exercise.restSeconds),
                  targetRpe: Value(exercise.targetRpe),
                  createdAt: nowMs,
                  updatedAt: nowMs,
                ),
              );
        }
      }
    });

    return splitId;
  }

  @override
  Future<void> updateSplit(String splitId, SplitDraftInput input) async {
    _validateSplitDraft(input);
    final nowMs = _now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.splits,
      )..where((tbl) => tbl.id.equals(splitId))).getSingleOrNull();
      if (existing == null) {
        throw ArgumentError('Split not found: $splitId');
      }

      await (_db.update(
        _db.splits,
      )..where((tbl) => tbl.id.equals(splitId))).write(
        SplitsCompanion(
          name: Value(input.name.trim()),
          scheduleMode: Value(input.scheduleMode),
          updatedAt: Value(nowMs),
        ),
      );

      await (_db.delete(
        _db.dayPlans,
      )..where((tbl) => tbl.splitId.equals(splitId))).go();

      final orderedDays = [...input.days]
        ..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));
      for (final day in orderedDays) {
        final dayPlanId = _uuid.v4();
        await _db
            .into(_db.dayPlans)
            .insert(
              DayPlansCompanion.insert(
                id: dayPlanId,
                splitId: splitId,
                dayIndex: day.dayIndex,
                title: day.title.trim(),
                createdAt: nowMs,
                updatedAt: nowMs,
              ),
            );

        final orderedExercises = [...day.plannedExercises]
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        for (final exercise in orderedExercises) {
          await _db
              .into(_db.plannedExercises)
              .insert(
                PlannedExercisesCompanion.insert(
                  id: _uuid.v4(),
                  dayPlanId: dayPlanId,
                  exerciseId: exercise.exerciseId,
                  orderIndex: exercise.orderIndex,
                  targetSets: exercise.targetSets,
                  repMin: exercise.repMin,
                  repMax: exercise.repMax,
                  restSeconds: Value(exercise.restSeconds),
                  targetRpe: Value(exercise.targetRpe),
                  createdAt: nowMs,
                  updatedAt: nowMs,
                ),
              );
        }
      }
    });
  }

  @override
  Future<void> setActiveSplit(String splitId) async {
    final nowMs = _now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.splits,
      )..where((tbl) => tbl.id.equals(splitId))).getSingleOrNull();
      if (existing == null) {
        throw ArgumentError('Split not found: $splitId');
      }

      await (_db.update(_db.splits)..where((tbl) => const Constant(true)))
          .write(const SplitsCompanion(isActive: Value(false)));

      await (_db.update(
        _db.splits,
      )..where((tbl) => tbl.id.equals(splitId))).write(
        SplitsCompanion(isActive: const Value(true), updatedAt: Value(nowMs)),
      );
    });
  }

  @override
  Stream<List<SplitSummary>> watchSplits() {
    final query =
        _db.select(_db.splits).join([
          leftOuterJoin(
            _db.dayPlans,
            _db.dayPlans.splitId.equalsExp(_db.splits.id),
          ),
        ])..orderBy([
          OrderingTerm.desc(_db.splits.updatedAt),
          OrderingTerm.asc(_db.splits.name),
          OrderingTerm.asc(_db.dayPlans.dayIndex),
        ]);

    return query.watch().map((rows) {
      final grouped = <String, _SplitSummaryAccumulator>{};
      for (final row in rows) {
        final split = row.readTable(_db.splits);
        final dayPlan = row.readTableOrNull(_db.dayPlans);

        final entry = grouped.putIfAbsent(
          split.id,
          () => _SplitSummaryAccumulator(
            id: split.id,
            name: split.name,
            scheduleMode: split.scheduleMode,
            isActive: split.isActive,
            updatedAt: split.updatedAt,
          ),
        );

        if (dayPlan != null) {
          entry.dayCount += 1;
        }
      }

      return grouped.values
          .map(
            (entry) => SplitSummary(
              id: entry.id,
              name: entry.name,
              scheduleMode: entry.scheduleMode,
              isActive: entry.isActive,
              dayCount: entry.dayCount,
              updatedAt: entry.updatedAt,
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<SplitDetails?> getSplitById(String splitId) async {
    final split = await (_db.select(
      _db.splits,
    )..where((tbl) => tbl.id.equals(splitId))).getSingleOrNull();
    if (split == null) {
      return null;
    }

    final days =
        await (_db.select(_db.dayPlans)
              ..where((tbl) => tbl.splitId.equals(splitId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.dayIndex)]))
            .get();

    if (days.isEmpty) {
      return SplitDetails(
        id: split.id,
        name: split.name,
        scheduleMode: split.scheduleMode,
        isActive: split.isActive,
        createdAt: split.createdAt,
        updatedAt: split.updatedAt,
        days: const [],
      );
    }

    final dayPlanIds = days.map((day) => day.id).toList(growable: false);
    final plannedRows =
        await (_db.select(_db.plannedExercises).join([
                innerJoin(
                  _db.exercises,
                  _db.exercises.id.equalsExp(_db.plannedExercises.exerciseId),
                ),
              ])
              ..where(_db.plannedExercises.dayPlanId.isIn(dayPlanIds))
              ..orderBy([
                OrderingTerm.asc(_db.plannedExercises.dayPlanId),
                OrderingTerm.asc(_db.plannedExercises.orderIndex),
              ]))
            .get();

    final plannedByDay = <String, List<PlannedExerciseDetails>>{};
    for (final row in plannedRows) {
      final planned = row.readTable(_db.plannedExercises);
      final exercise = row.readTable(_db.exercises);

      plannedByDay
          .putIfAbsent(planned.dayPlanId, () => [])
          .add(
            PlannedExerciseDetails(
              id: planned.id,
              orderIndex: planned.orderIndex,
              exerciseId: planned.exerciseId,
              exerciseName: exercise.name,
              targetSets: planned.targetSets,
              repMin: planned.repMin,
              repMax: planned.repMax,
              restSeconds: planned.restSeconds,
              targetRpe: planned.targetRpe,
            ),
          );
    }

    final dayDetails = days
        .map(
          (day) => DayPlanDetails(
            id: day.id,
            dayIndex: day.dayIndex,
            title: day.title,
            plannedExercises: List.unmodifiable(
              plannedByDay[day.id] ?? const <PlannedExerciseDetails>[],
            ),
          ),
        )
        .toList(growable: false);

    return SplitDetails(
      id: split.id,
      name: split.name,
      scheduleMode: split.scheduleMode,
      isActive: split.isActive,
      createdAt: split.createdAt,
      updatedAt: split.updatedAt,
      days: List.unmodifiable(dayDetails),
    );
  }

  @override
  Future<void> deleteSplit(String splitId) async {
    final deleted = await (_db.delete(
      _db.splits,
    )..where((tbl) => tbl.id.equals(splitId))).go();
    if (deleted == 0) {
      throw ArgumentError('Split not found: $splitId');
    }
  }

  void _validateSplitDraft(SplitDraftInput input) {
    if (input.name.trim().isEmpty) {
      throw ArgumentError('Split name is required.');
    }
    if (input.days.isEmpty) {
      throw ArgumentError('At least one day plan is required.');
    }
    if (!SplitScheduleMode.isSupported(input.scheduleMode)) {
      throw ArgumentError('Unsupported schedule mode: ${input.scheduleMode}.');
    }

    final orderedDays = [...input.days]
      ..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));
    for (var i = 0; i < orderedDays.length; i++) {
      final day = orderedDays[i];
      final expectedDayIndex = i + 1;
      if (day.dayIndex != expectedDayIndex) {
        throw ArgumentError(
          'Day indices must be contiguous and start at 1. Missing day $expectedDayIndex.',
        );
      }
      if (day.title.trim().isEmpty) {
        throw ArgumentError('Day ${day.dayIndex} title is required.');
      }
      if (day.plannedExercises.isEmpty) {
        throw ArgumentError(
          'Day ${day.dayIndex} must include at least one planned exercise.',
        );
      }

      final orderIndexes = <int>{};
      for (final planned in day.plannedExercises) {
        if (planned.orderIndex <= 0) {
          throw ArgumentError(
            'Day ${day.dayIndex}: order index must be greater than zero.',
          );
        }
        if (!orderIndexes.add(planned.orderIndex)) {
          throw ArgumentError(
            'Day ${day.dayIndex}: duplicate order index ${planned.orderIndex}.',
          );
        }
        if (planned.targetSets <= 0) {
          throw ArgumentError(
            'Day ${day.dayIndex}: target sets must be greater than zero.',
          );
        }
        if (planned.repMin <= 0) {
          throw ArgumentError(
            'Day ${day.dayIndex}: minimum reps must be greater than zero.',
          );
        }
        if (planned.repMax < planned.repMin) {
          throw ArgumentError(
            'Day ${day.dayIndex}: maximum reps cannot be lower than minimum reps.',
          );
        }
        if (planned.restSeconds != null && planned.restSeconds! < 0) {
          throw ArgumentError(
            'Day ${day.dayIndex}: rest seconds cannot be negative.',
          );
        }
        if (planned.targetRpe != null &&
            (planned.targetRpe! < 0 || planned.targetRpe! > 10)) {
          throw ArgumentError(
            'Day ${day.dayIndex}: target RPE must be between 0 and 10.',
          );
        }
      }
    }
  }
}

class _SplitSummaryAccumulator {
  _SplitSummaryAccumulator({
    required this.id,
    required this.name,
    required this.scheduleMode,
    required this.isActive,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String scheduleMode;
  final bool isActive;
  final int updatedAt;
  int dayCount = 0;
}
