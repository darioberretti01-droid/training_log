import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/core/db/app_database.dart';
import 'package:training_log_app/core/models/exercise_with_labels.dart';
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

  test('getRecentSessionsOverview returns newest sessions first', () async {
    final exercises = await _seedExercises(exerciseRepository);
    final exerciseId = exercises.first.id;

    await _insertSession(
      database,
      sessionId: 'session_older',
      startedAt: DateTime(2026, 1, 2, 9, 0),
      endedAt: DateTime(2026, 1, 2, 9, 30),
      exerciseIds: [exerciseId],
    );
    await _insertSession(
      database,
      sessionId: 'session_newer',
      startedAt: DateTime(2026, 1, 3, 9, 0),
      endedAt: DateTime(2026, 1, 3, 9, 30),
      exerciseIds: [exerciseId],
    );

    final sessions = await quickWorkoutRepository.getRecentSessionsOverview();

    expect(sessions, hasLength(2));
    expect(sessions.first.session.id, 'session_newer');
    expect(sessions.last.session.id, 'session_older');
  });

  test(
    'getRecentSessionsOverview enforces sessionLimit by unique sessions',
    () async {
      final exercises = await _seedExercises(exerciseRepository);
      final exerciseId = exercises.first.id;

      await _insertSession(
        database,
        sessionId: 'session_1',
        startedAt: DateTime(2026, 1, 1, 9, 0),
        endedAt: DateTime(2026, 1, 1, 9, 30),
        exerciseIds: [exerciseId, exerciseId],
      );
      await _insertSession(
        database,
        sessionId: 'session_2',
        startedAt: DateTime(2026, 1, 2, 9, 0),
        endedAt: DateTime(2026, 1, 2, 9, 30),
        exerciseIds: [exerciseId, exerciseId],
      );
      await _insertSession(
        database,
        sessionId: 'session_3',
        startedAt: DateTime(2026, 1, 3, 9, 0),
        endedAt: DateTime(2026, 1, 3, 9, 30),
        exerciseIds: [exerciseId, exerciseId],
      );

      final sessions = await quickWorkoutRepository.getRecentSessionsOverview(
        sessionLimit: 2,
      );

      expect(sessions, hasLength(2));
      expect(sessions.first.session.id, 'session_3');
      expect(sessions.last.session.id, 'session_2');
    },
  );

  test(
    'getRecentSessionsOverview aggregates totalSets and per-exercise counts',
    () async {
      final exercises = await _seedExercises(exerciseRepository);
      final firstExercise = exercises[0];
      final secondExercise = exercises[1];

      await _insertSession(
        database,
        sessionId: 'session_mix',
        startedAt: DateTime(2026, 1, 5, 9, 0),
        endedAt: DateTime(2026, 1, 5, 9, 30),
        exerciseIds: [firstExercise.id, firstExercise.id, secondExercise.id],
      );

      final sessions = await quickWorkoutRepository.getRecentSessionsOverview();
      final entry = sessions.single;

      expect(entry.totalSets, 3);
      expect(entry.exercises, hasLength(2));

      final firstSummary = entry.exercises.firstWhere(
        (exercise) => exercise.exerciseId == firstExercise.id,
      );
      final secondSummary = entry.exercises.firstWhere(
        (exercise) => exercise.exerciseId == secondExercise.id,
      );
      expect(firstSummary.setCount, 2);
      expect(secondSummary.setCount, 1);
    },
  );

  test(
    'exercise summaries are sorted by setCount desc then name asc',
    () async {
      final seeded = await _seedExercises(exerciseRepository);
      final byName = [...seeded]..sort((a, b) => a.name.compareTo(b.name));

      final alphaA = byName[0];
      final alphaB = byName[1];
      final highVolume = byName[2];

      await _insertSession(
        database,
        sessionId: 'session_sorting',
        startedAt: DateTime(2026, 1, 6, 9, 0),
        endedAt: DateTime(2026, 1, 6, 9, 30),
        exerciseIds: [highVolume.id, highVolume.id, alphaB.id, alphaA.id],
      );

      final sessions = await quickWorkoutRepository.getRecentSessionsOverview();
      final names = sessions.single.exercises
          .map((exercise) => exercise.exerciseName)
          .toList();
      final counts = sessions.single.exercises
          .map((exercise) => exercise.setCount)
          .toList();

      expect(counts, [2, 1, 1]);
      expect(names, [highVolume.name, alphaA.name, alphaB.name]);
    },
  );
}

Future<List<ExerciseWithLabels>> _seedExercises(
  DriftExerciseRepository repository,
) async {
  await repository.seedIfEmpty();
  return repository.watchExercises().first;
}

Future<void> _insertSession(
  AppDatabase database, {
  required String sessionId,
  required DateTime startedAt,
  required DateTime endedAt,
  required List<String> exerciseIds,
}) async {
  final startedAtMs = startedAt.millisecondsSinceEpoch;
  final endedAtMs = endedAt.millisecondsSinceEpoch;

  await database.transaction(() async {
    await database
        .into(database.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            id: sessionId,
            sessionType: 'quick',
            startedAt: startedAtMs,
            endedAt: endedAtMs,
          ),
        );

    for (var index = 0; index < exerciseIds.length; index++) {
      await database
          .into(database.performedSets)
          .insert(
            PerformedSetsCompanion.insert(
              id: '${sessionId}_set_${index + 1}',
              sessionId: sessionId,
              exerciseId: exerciseIds[index],
              setIndex: index + 1,
              reps: 8,
              weightKg: (50 + index).toDouble(),
              performedAt: endedAtMs,
            ),
          );
    }
  });
}
