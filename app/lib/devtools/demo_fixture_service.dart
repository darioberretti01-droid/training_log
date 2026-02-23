import 'package:drift/drift.dart';

import '../core/db/app_database.dart';
import '../core/db/user_exercise_database.dart';
import '../features/exercises/exercise_repository.dart';
import '../features/workouts/workout_draft.dart';
import '../features/workouts/workout_draft_storage.dart';
import '../features/workouts/quick_workout_repository.dart';
import 'demo_fixture_models.dart';

class DemoFixtureService {
  DemoFixtureService({
    required AppDatabase appDb,
    required UserExerciseDatabase userDb,
    required ExerciseRepository exerciseRepository,
    required WorkoutDraftStorage workoutDraftStorage,
  }) : _appDb = appDb,
       _userDb = userDb,
       _exerciseRepository = exerciseRepository,
       _workoutDraftStorage = workoutDraftStorage;

  final AppDatabase _appDb;
  final UserExerciseDatabase _userDb;
  final ExerciseRepository _exerciseRepository;
  final WorkoutDraftStorage _workoutDraftStorage;

  static const List<String> _appTablesInDeleteOrder = <String>[
    'performed_sets',
    'workout_sessions',
    'planned_exercises',
    'day_plans',
    'splits',
    'exercise_label_links',
    'exercise_labels',
    'exercises',
    'workout_drafts',
  ];

  static const List<String> _userTablesInDeleteOrder = <String>[
    'user_exercise_label_links',
    'user_exercise_labels',
    'user_exercises',
    'hidden_standard_labels',
    'hidden_standard_exercises',
  ];

  Future<void> resetAllData() async {
    await _appDb.transaction(() async {
      await _appDb.customStatement('PRAGMA foreign_keys = OFF;');
      for (final table in _appTablesInDeleteOrder) {
        await _appDb.customStatement('DELETE FROM $table;');
      }
      await _appDb.customStatement('PRAGMA foreign_keys = ON;');
    });

    await _userDb.transaction(() async {
      await _userDb.customStatement('PRAGMA foreign_keys = OFF;');
      for (final table in _userTablesInDeleteOrder) {
        await _userDb.customStatement('DELETE FROM $table;');
      }
      await _userDb.customStatement('PRAGMA foreign_keys = ON;');
    });

    await _workoutDraftStorage.clearDraft();
  }

  Future<void> seedBaseFixture({required DateTime now}) async {
    await _exerciseRepository.seedIfEmpty();
    final nowMs = now.millisecondsSinceEpoch;

    await _appDb.transaction(() async {
      await _seedSplits(nowMs);
      await _seedSessions(now);
    });
  }

  Future<void> applyScenarioOverlay(
    DemoFixtureScenario scenario, {
    required DateTime now,
  }) async {
    await _workoutDraftStorage.clearDraft();

    switch (scenario) {
      case DemoFixtureScenario.baseRealistic:
        return;
      case DemoFixtureScenario.homeKeepLoggingToday:
        await _seedKeepLoggingDraft(now);
        return;
      case DemoFixtureScenario.homeNoCurrentSplit:
        await _setNoActiveSplit();
        return;
      case DemoFixtureScenario.homeLastUsedExistsNotCurrent:
        await _setActiveSplit(
          DemoFixtureIds.splitFullBody,
          nowMs: now.millisecondsSinceEpoch,
        );
        await _insertSession(
          id: 'session_overlay_last_used_exists',
          mode: WorkoutSessionMode.splitDay,
          splitId: DemoFixtureIds.splitPushPullLegs,
          dayIndex: 2,
          sessionName: 'Pull',
          startedAt: now.subtract(const Duration(hours: 2)),
          endedAt: now.subtract(const Duration(hours: 1, minutes: 20)),
          setsByExercise: const {
            'lat_pulldown': [_LoggedSetSeed(reps: 10, weightKg: 65)],
            'barbell_row': [_LoggedSetSeed(reps: 8, weightKg: 75)],
          },
        );
        return;
      case DemoFixtureScenario.homeLastUsedDeleted:
        await _setActiveSplit(
          DemoFixtureIds.splitFullBody,
          nowMs: now.millisecondsSinceEpoch,
        );
        await _insertSession(
          id: 'session_overlay_last_used_deleted',
          mode: WorkoutSessionMode.splitDay,
          splitId: 'split_deleted_archived',
          dayIndex: 1,
          sessionName: 'Deleted Split Day',
          startedAt: now.subtract(const Duration(hours: 2)),
          endedAt: now.subtract(const Duration(hours: 1, minutes: 15)),
          setsByExercise: const {
            'bench_press': [_LoggedSetSeed(reps: 8, weightKg: 82.5)],
          },
        );
        return;
      case DemoFixtureScenario.homeNoSessions:
        await _clearSessions();
        return;
      case DemoFixtureScenario.loggerSplitWithUnfilledRows:
        return;
    }
  }

  Future<void> resetAndSeed(
    DemoFixtureScenario scenario, {
    required DateTime now,
  }) async {
    await resetAllData();
    await seedBaseFixture(now: now);
    await applyScenarioOverlay(scenario, now: now);
  }

  Future<void> _seedSplits(int nowMs) async {
    await _insertSplit(
      splitId: DemoFixtureIds.splitUpperLower,
      splitName: 'Upper / Lower',
      scheduleMode: 'sequence',
      isActive: true,
      nowMs: nowMs,
      days: const [
        _DaySeed(
          id: DemoFixtureIds.dayUpperA,
          dayIndex: 1,
          title: 'Upper A',
          exercises: [
            _PlannedExerciseSeed(
              exerciseId: 'bench_press',
              orderIndex: 1,
              targetSets: 3,
              repMin: 6,
              repMax: 8,
              restSeconds: 150,
              targetRpe: 8,
            ),
            _PlannedExerciseSeed(
              exerciseId: 'barbell_row',
              orderIndex: 2,
              targetSets: 3,
              repMin: 8,
              repMax: 10,
              restSeconds: 120,
              targetRpe: 8,
            ),
            _PlannedExerciseSeed(
              exerciseId: 'overhead_press',
              orderIndex: 3,
              targetSets: 3,
              repMin: 8,
              repMax: 10,
              restSeconds: 120,
              targetRpe: 8,
            ),
          ],
        ),
        _DaySeed(
          id: DemoFixtureIds.dayLowerA,
          dayIndex: 2,
          title: 'Lower A',
          exercises: [
            _PlannedExerciseSeed(
              exerciseId: 'back_squat',
              orderIndex: 1,
              targetSets: 4,
              repMin: 5,
              repMax: 8,
              restSeconds: 180,
              targetRpe: 8,
            ),
            _PlannedExerciseSeed(
              exerciseId: 'romanian_deadlift',
              orderIndex: 2,
              targetSets: 3,
              repMin: 8,
              repMax: 10,
              restSeconds: 150,
              targetRpe: 8,
            ),
            _PlannedExerciseSeed(
              exerciseId: 'standing_calf_raise',
              orderIndex: 3,
              targetSets: 3,
              repMin: 10,
              repMax: 15,
              restSeconds: 90,
              targetRpe: 8,
            ),
          ],
        ),
      ],
    );

    await _insertSplit(
      splitId: DemoFixtureIds.splitPushPullLegs,
      splitName: 'Push / Pull / Legs',
      scheduleMode: 'sequence',
      isActive: false,
      nowMs: nowMs,
      days: const [
        _DaySeed(
          id: DemoFixtureIds.dayPush,
          dayIndex: 1,
          title: 'Push',
          exercises: [
            _PlannedExerciseSeed(
              exerciseId: 'incline_dumbbell_press',
              orderIndex: 1,
              targetSets: 3,
              repMin: 8,
              repMax: 12,
              restSeconds: 120,
              targetRpe: 8,
            ),
            _PlannedExerciseSeed(
              exerciseId: 'dips',
              orderIndex: 2,
              targetSets: 3,
              repMin: 8,
              repMax: 12,
              restSeconds: 120,
              targetRpe: 8,
            ),
          ],
        ),
        _DaySeed(
          id: DemoFixtureIds.dayPull,
          dayIndex: 2,
          title: 'Pull',
          exercises: [
            _PlannedExerciseSeed(
              exerciseId: 'lat_pulldown',
              orderIndex: 1,
              targetSets: 3,
              repMin: 8,
              repMax: 12,
              restSeconds: 120,
              targetRpe: 8,
            ),
            _PlannedExerciseSeed(
              exerciseId: 'seated_cable_row',
              orderIndex: 2,
              targetSets: 3,
              repMin: 8,
              repMax: 12,
              restSeconds: 120,
              targetRpe: 8,
            ),
          ],
        ),
        _DaySeed(
          id: DemoFixtureIds.dayLegs,
          dayIndex: 3,
          title: 'Legs',
          exercises: [
            _PlannedExerciseSeed(
              exerciseId: 'front_squat',
              orderIndex: 1,
              targetSets: 4,
              repMin: 5,
              repMax: 8,
              restSeconds: 180,
              targetRpe: 8,
            ),
          ],
        ),
      ],
    );

    await _insertSplit(
      splitId: DemoFixtureIds.splitFullBody,
      splitName: 'Full Body',
      scheduleMode: 'sequence',
      isActive: false,
      nowMs: nowMs,
      days: const [
        _DaySeed(
          id: DemoFixtureIds.dayFullBodyA,
          dayIndex: 1,
          title: 'Full Body A',
          exercises: [
            _PlannedExerciseSeed(
              exerciseId: 'back_squat',
              orderIndex: 1,
              targetSets: 3,
              repMin: 6,
              repMax: 8,
              restSeconds: 150,
              targetRpe: 8,
            ),
            _PlannedExerciseSeed(
              exerciseId: 'bench_press',
              orderIndex: 2,
              targetSets: 3,
              repMin: 6,
              repMax: 8,
              restSeconds: 150,
              targetRpe: 8,
            ),
          ],
        ),
        _DaySeed(
          id: DemoFixtureIds.dayFullBodyB,
          dayIndex: 2,
          title: 'Full Body B',
          exercises: [
            _PlannedExerciseSeed(
              exerciseId: 'romanian_deadlift',
              orderIndex: 1,
              targetSets: 3,
              repMin: 6,
              repMax: 8,
              restSeconds: 150,
              targetRpe: 8,
            ),
            _PlannedExerciseSeed(
              exerciseId: 'overhead_press',
              orderIndex: 2,
              targetSets: 3,
              repMin: 8,
              repMax: 10,
              restSeconds: 120,
              targetRpe: 8,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _insertSplit({
    required String splitId,
    required String splitName,
    required String scheduleMode,
    required bool isActive,
    required int nowMs,
    required List<_DaySeed> days,
  }) async {
    await _appDb
        .into(_appDb.splits)
        .insert(
          SplitsCompanion.insert(
            id: splitId,
            name: splitName,
            scheduleMode: Value(scheduleMode),
            isActive: Value(isActive),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    for (final day in days) {
      await _appDb
          .into(_appDb.dayPlans)
          .insert(
            DayPlansCompanion.insert(
              id: day.id,
              splitId: splitId,
              dayIndex: day.dayIndex,
              title: day.title,
              createdAt: nowMs,
              updatedAt: nowMs,
            ),
          );

      for (final planned in day.exercises) {
        await _appDb
            .into(_appDb.plannedExercises)
            .insert(
              PlannedExercisesCompanion.insert(
                id: '${day.id}_plan_${planned.orderIndex}',
                dayPlanId: day.id,
                exerciseId: planned.exerciseId,
                orderIndex: planned.orderIndex,
                targetSets: planned.targetSets,
                repMin: planned.repMin,
                repMax: planned.repMax,
                restSeconds: Value(planned.restSeconds),
                targetRpe: Value(planned.targetRpe),
                createdAt: nowMs,
                updatedAt: nowMs,
              ),
            );
      }
    }
  }

  Future<void> _seedSessions(DateTime now) async {
    await _insertSession(
      id: 'session_split_upper_a_old',
      mode: WorkoutSessionMode.splitDay,
      splitId: DemoFixtureIds.splitUpperLower,
      dayIndex: 1,
      sessionName: 'Upper A',
      startedAt: now.subtract(const Duration(days: 6, hours: 1)),
      endedAt: now.subtract(const Duration(days: 6)),
      setsByExercise: const {
        'bench_press': [
          _LoggedSetSeed(reps: 8, weightKg: 80, restSeconds: 150, rpe: 8),
          _LoggedSetSeed(reps: 8, weightKg: 80),
          _LoggedSetSeed(reps: 7, weightKg: 80),
        ],
        'barbell_row': [
          _LoggedSetSeed(reps: 10, weightKg: 70),
          _LoggedSetSeed(reps: 9, weightKg: 70),
        ],
      },
    );

    await _insertSession(
      id: 'session_split_lower_a_old',
      mode: WorkoutSessionMode.splitDay,
      splitId: DemoFixtureIds.splitUpperLower,
      dayIndex: 2,
      sessionName: 'Lower A',
      startedAt: now.subtract(const Duration(days: 4, hours: 1)),
      endedAt: now.subtract(const Duration(days: 4)),
      setsByExercise: const {
        'back_squat': [
          _LoggedSetSeed(reps: 6, weightKg: 110),
          _LoggedSetSeed(reps: 6, weightKg: 110),
          _LoggedSetSeed(reps: 5, weightKg: 110),
        ],
      },
    );

    await _insertSession(
      id: 'session_split_upper_recent',
      mode: WorkoutSessionMode.splitDay,
      splitId: DemoFixtureIds.splitUpperLower,
      dayIndex: 1,
      sessionName: 'Upper A',
      startedAt: now.subtract(const Duration(days: 1, hours: 1)),
      endedAt: now.subtract(const Duration(days: 1)),
      setsByExercise: const {
        'bench_press': [
          _LoggedSetSeed(reps: 8, weightKg: 82.5),
          _LoggedSetSeed(reps: 8, weightKg: 82.5),
          _LoggedSetSeed(reps: 8, weightKg: 82.5),
        ],
        'barbell_row': [
          _LoggedSetSeed(reps: 10, weightKg: 72.5),
          _LoggedSetSeed(reps: 10, weightKg: 72.5),
        ],
      },
    );

    await _insertSession(
      id: 'session_free_recent',
      mode: WorkoutSessionMode.free,
      splitId: null,
      dayIndex: null,
      sessionName: 'Free workout',
      startedAt: now.subtract(const Duration(hours: 15)),
      endedAt: now.subtract(const Duration(hours: 14, minutes: 30)),
      setsByExercise: const {
        'lateral_raise': [
          _LoggedSetSeed(reps: 12, weightKg: 12),
          _LoggedSetSeed(reps: 12, weightKg: 12),
        ],
        'barbell_curl': [_LoggedSetSeed(reps: 10, weightKg: 35)],
      },
    );
  }

  Future<void> _insertSession({
    required String id,
    required String mode,
    required String? splitId,
    required int? dayIndex,
    required String? sessionName,
    required DateTime startedAt,
    required DateTime endedAt,
    required Map<String, List<_LoggedSetSeed>> setsByExercise,
  }) async {
    final startedAtMs = startedAt.millisecondsSinceEpoch;
    final endedAtMs = endedAt.millisecondsSinceEpoch;
    await _appDb
        .into(_appDb.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            id: id,
            sessionType: mode,
            splitId: Value(splitId),
            dayIndex: Value(dayIndex),
            sessionName: Value(sessionName),
            startedAt: startedAtMs,
            endedAt: endedAtMs,
          ),
        );

    var rowCounter = 0;
    for (final entry in setsByExercise.entries) {
      final exerciseId = entry.key;
      final sets = entry.value;
      for (var index = 0; index < sets.length; index++) {
        rowCounter += 1;
        final set = sets[index];
        await _appDb
            .into(_appDb.performedSets)
            .insert(
              PerformedSetsCompanion.insert(
                id: '${id}_set_$rowCounter',
                sessionId: id,
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
    }
  }

  Future<void> _setActiveSplit(String splitId, {required int nowMs}) async {
    await (_appDb.update(_appDb.splits)..where((tbl) => const Constant(true)))
        .write(const SplitsCompanion(isActive: Value(false)));
    await (_appDb.update(
      _appDb.splits,
    )..where((tbl) => tbl.id.equals(splitId))).write(
      SplitsCompanion(isActive: const Value(true), updatedAt: Value(nowMs)),
    );
  }

  Future<void> _setNoActiveSplit() async {
    await (_appDb.update(_appDb.splits)..where((tbl) => const Constant(true)))
        .write(const SplitsCompanion(isActive: Value(false)));
  }

  Future<void> _clearSessions() async {
    await (_appDb.delete(
      _appDb.performedSets,
    )..where((tbl) => const Constant(true))).go();
    await (_appDb.delete(
      _appDb.workoutSessions,
    )..where((tbl) => const Constant(true))).go();
  }

  Future<void> _seedKeepLoggingDraft(DateTime now) {
    return _workoutDraftStorage.saveDraft(
      WorkoutDraft(
        mode: WorkoutSessionMode.splitDay,
        splitId: DemoFixtureIds.splitUpperLower,
        dayIndex: 2,
        startedAtMs: now
            .subtract(const Duration(minutes: 25))
            .millisecondsSinceEpoch,
        updatedAtMs: now
            .subtract(const Duration(minutes: 2))
            .millisecondsSinceEpoch,
        exercises: const [
          WorkoutDraftExercise(
            exerciseId: 'back_squat',
            exerciseName: 'Back Squat',
            labels: ['legs', 'quads', 'compound'],
            repMin: 5,
            repMax: 8,
            targetSets: 4,
            restSeconds: 180,
            targetRpe: 8,
            rows: [
              WorkoutDraftSetRow(
                weightText: '110',
                repsText: '6',
                rpeText: '8',
                restSeconds: 180,
              ),
              WorkoutDraftSetRow(
                weightText: '',
                repsText: '',
                rpeText: '',
                restSeconds: null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DaySeed {
  const _DaySeed({
    required this.id,
    required this.dayIndex,
    required this.title,
    required this.exercises,
  });

  final String id;
  final int dayIndex;
  final String title;
  final List<_PlannedExerciseSeed> exercises;
}

class _PlannedExerciseSeed {
  const _PlannedExerciseSeed({
    required this.exerciseId,
    required this.orderIndex,
    required this.targetSets,
    required this.repMin,
    required this.repMax,
    required this.restSeconds,
    required this.targetRpe,
  });

  final String exerciseId;
  final int orderIndex;
  final int targetSets;
  final int repMin;
  final int repMax;
  final int? restSeconds;
  final double? targetRpe;
}

class _LoggedSetSeed {
  const _LoggedSetSeed({
    required this.reps,
    required this.weightKg,
    this.restSeconds,
    this.rpe,
  });

  final int reps;
  final double weightKg;
  final int? restSeconds;
  final double? rpe;
}
