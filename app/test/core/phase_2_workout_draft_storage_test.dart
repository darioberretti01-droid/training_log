import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/core/db/app_database.dart';
import 'package:training_log_app/features/workouts/workout_draft.dart';
import 'package:training_log_app/features/workouts/workout_draft_storage.dart';
import 'package:training_log_app/features/workouts/quick_workout_repository.dart';

void main() {
  late AppDatabase database;
  late WorkoutDraftStorage storage;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    storage = WorkoutDraftStorage(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'saveDraft + loadDraft roundtrip persists workout draft payload',
    () async {
      final draft = WorkoutDraft(
        mode: WorkoutSessionMode.splitDay,
        splitId: 'split_1',
        dayIndex: 2,
        startedAtMs: DateTime(2026, 2, 23, 10, 0).millisecondsSinceEpoch,
        updatedAtMs: DateTime(2026, 2, 23, 10, 30).millisecondsSinceEpoch,
        exercises: const [
          WorkoutDraftExercise(
            exerciseId: 'bench_press',
            exerciseName: 'Bench Press',
            labels: ['push', 'chest'],
            repMin: 6,
            repMax: 10,
            targetSets: 3,
            restSeconds: 120,
            targetRpe: 8.0,
            rows: [
              WorkoutDraftSetRow(
                weightText: '60',
                repsText: '8',
                rpeText: '8',
                restSeconds: 120,
              ),
            ],
          ),
        ],
      );

      await storage.saveDraft(draft);
      final loaded = await storage.loadDraft();

      expect(loaded, isNotNull);
      expect(loaded!.mode, WorkoutSessionMode.splitDay);
      expect(loaded.splitId, 'split_1');
      expect(loaded.dayIndex, 2);
      expect(loaded.exercises, hasLength(1));
      expect(loaded.exercises.first.rows.first.weightText, '60');
    },
  );

  test('clearDraft removes previously saved draft', () async {
    final draft = WorkoutDraft(
      mode: WorkoutSessionMode.free,
      startedAtMs: DateTime(2026, 2, 23, 12, 0).millisecondsSinceEpoch,
      updatedAtMs: DateTime(2026, 2, 23, 12, 15).millisecondsSinceEpoch,
      exercises: const [
        WorkoutDraftExercise(
          exerciseId: 'row',
          exerciseName: 'Row',
          labels: ['pull'],
          repMin: 8,
          repMax: 12,
          targetSets: 2,
          rows: [],
        ),
      ],
    );

    await storage.saveDraft(draft);
    await storage.clearDraft();
    final loaded = await storage.loadDraft();

    expect(loaded, isNull);
  });
}
