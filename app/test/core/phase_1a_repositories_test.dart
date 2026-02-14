import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/core/db/app_database.dart';
import 'package:training_log_app/core/models/logged_set_input.dart';
import 'package:training_log_app/features/exercises/exercise_repository.dart';
import 'package:training_log_app/features/workouts/quick_workout_repository.dart';

void main() {
  late AppDatabase database;
  late DriftExerciseRepository exerciseRepository;
  late DriftQuickWorkoutRepository quickWorkoutRepository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    exerciseRepository = DriftExerciseRepository(database);
    quickWorkoutRepository = DriftQuickWorkoutRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('seedIfEmpty is idempotent', () async {
    await exerciseRepository.seedIfEmpty();
    final firstCount = await _exerciseCount(database);

    await exerciseRepository.seedIfEmpty();
    final secondCount = await _exerciseCount(database);

    expect(firstCount, inInclusiveRange(18, 24));
    expect(secondCount, firstCount);
  });

  test('quick workout save persists sets and supports roundtrip', () async {
    await exerciseRepository.seedIfEmpty();
    final exercise = (await exerciseRepository.watchExercises().first).first;

    final sessionId = await quickWorkoutRepository.saveQuickWorkout(
      exerciseId: exercise.id,
      startedAt: DateTime(2026, 1, 1, 10, 0),
      endedAt: DateTime(2026, 1, 1, 10, 20),
      sets: const [
        LoggedSetInput(reps: 8, weightKg: 60),
        LoggedSetInput(reps: 8, weightKg: 62.5, restSeconds: 120, rpe: 8.0),
        LoggedSetInput(reps: 7, weightKg: 65, restSeconds: 120, rpe: 8.5),
      ],
    );

    final sets = await quickWorkoutRepository.getRecentSetsForExercise(
      exercise.id,
      limit: 30,
    );

    expect(sessionId, isNotEmpty);
    expect(sets, hasLength(3));
    expect(sets.first.sessionId, sessionId);
    expect(sets.first.reps, 8);
    expect(sets.first.weightKg, 60);
    expect(sets[1].restSeconds, 120);
    expect(sets[1].rpe, 8.0);
  });

  test('best set is ordered by heaviest weight, then reps, then most recent', () async {
    await exerciseRepository.seedIfEmpty();
    final exercise = (await exerciseRepository.watchExercises().first).first;

    await quickWorkoutRepository.saveQuickWorkout(
      exerciseId: exercise.id,
      startedAt: DateTime(2026, 1, 2, 10, 0),
      endedAt: DateTime(2026, 1, 2, 10, 10),
      sets: const [
        LoggedSetInput(reps: 10, weightKg: 80),
      ],
    );

    await quickWorkoutRepository.saveQuickWorkout(
      exerciseId: exercise.id,
      startedAt: DateTime(2026, 1, 3, 10, 0),
      endedAt: DateTime(2026, 1, 3, 10, 10),
      sets: const [
        LoggedSetInput(reps: 9, weightKg: 80),
        LoggedSetInput(reps: 8, weightKg: 82.5),
      ],
    );

    await quickWorkoutRepository.saveQuickWorkout(
      exerciseId: exercise.id,
      startedAt: DateTime(2026, 1, 4, 10, 0),
      endedAt: DateTime(2026, 1, 4, 10, 10),
      sets: const [
        LoggedSetInput(reps: 8, weightKg: 82.5),
      ],
    );

    final best = await quickWorkoutRepository.getBestSetForExercise(exercise.id);

    expect(best, isNotNull);
    expect(best!.weightKg, 82.5);
    expect(best.reps, 8);
    expect(best.performedAt, DateTime(2026, 1, 4, 10, 10).millisecondsSinceEpoch);
  });

  test('saveQuickWorkout validates required values', () async {
    await exerciseRepository.seedIfEmpty();
    final exercise = (await exerciseRepository.watchExercises().first).first;

    expect(
      () => quickWorkoutRepository.saveQuickWorkout(
        exerciseId: exercise.id,
        startedAt: DateTime.now(),
        endedAt: DateTime.now(),
        sets: const [],
      ),
      throwsArgumentError,
    );

    expect(
      () => quickWorkoutRepository.saveQuickWorkout(
        exerciseId: exercise.id,
        startedAt: DateTime.now(),
        endedAt: DateTime.now(),
        sets: const [LoggedSetInput(reps: 0, weightKg: 40)],
      ),
      throwsArgumentError,
    );
  });

  test('getRecentSessionsForExercise groups sets by session', () async {
    await exerciseRepository.seedIfEmpty();
    final exercise = (await exerciseRepository.watchExercises().first).first;

    await quickWorkoutRepository.saveQuickWorkout(
      exerciseId: exercise.id,
      startedAt: DateTime(2026, 1, 5, 10, 0),
      endedAt: DateTime(2026, 1, 5, 10, 20),
      sets: const [
        LoggedSetInput(reps: 10, weightKg: 50),
        LoggedSetInput(reps: 9, weightKg: 52.5),
      ],
    );

    await quickWorkoutRepository.saveQuickWorkout(
      exerciseId: exercise.id,
      startedAt: DateTime(2026, 1, 6, 10, 0),
      endedAt: DateTime(2026, 1, 6, 10, 15),
      sets: const [
        LoggedSetInput(reps: 8, weightKg: 55),
      ],
    );

    final sessions = await quickWorkoutRepository.getRecentSessionsForExercise(
      exercise.id,
      sessionLimit: 10,
    );

    expect(sessions, hasLength(2));
    expect(
      sessions.first.session.startedAt,
      DateTime(2026, 1, 6, 10, 0).millisecondsSinceEpoch,
    );
    expect(sessions.first.sets, hasLength(1));
    expect(sessions.last.sets, hasLength(2));
    expect(sessions.last.sets.first.setIndex, 1);
    expect(sessions.last.sets.last.setIndex, 2);
  });
}

Future<int> _exerciseCount(AppDatabase database) async {
  final row = await database.customSelect(
    'SELECT COUNT(*) AS c FROM exercises',
  ).getSingle();
  return row.read<int>('c');
}
