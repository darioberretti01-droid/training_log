import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/core/db/app_database.dart';
import 'package:training_log_app/core/db/user_exercise_database.dart';
import 'package:training_log_app/core/models/exercise_with_labels.dart';
import 'package:training_log_app/core/models/logged_set_input.dart';
import 'package:training_log_app/core/state/providers.dart';
import 'package:training_log_app/features/exercises/exercise_repository.dart';
import 'package:training_log_app/features/splits/split_repository.dart';
import 'package:training_log_app/features/workouts/quick_workout_repository.dart';
import 'package:training_log_app/features/workouts/workout_logger_screen.dart';

void main() {
  testWidgets('free workout shows delete current log action', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(
          home: WorkoutLoggerScreen(mode: WorkoutSessionMode.free),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('workout_logger_delete_log')), findsOneWidget);
  });

  testWidgets(
    'free workout add exercise opens the same picker controls as split builder',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            exercisesProvider.overrideWith(
              (ref) => Stream.value(const [
                ExerciseWithLabels(
                  id: 'bench_press',
                  name: 'Barbell Bench Press',
                  labels: ['chest'],
                ),
              ]),
            ),
          ],
          child: const MaterialApp(
            home: WorkoutLoggerScreen(mode: WorkoutSessionMode.free),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('workout_logger_add_exercise')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('split_builder_exercise_picker_search_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('split_builder_exercise_picker_grouping_dropdown'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('split_builder_exercise_picker_view_toggle')),
        findsOneWidget,
      );
    },
  );

  testWidgets('free workout picker excludes hidden exercises', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          exercisesProvider.overrideWith(
            (ref) => Stream.value(const [
              ExerciseWithLabels(
                id: 'bench_press',
                name: 'Barbell Bench Press',
                labels: ['chest'],
              ),
              ExerciseWithLabels(
                id: 'pull_up',
                name: 'Pull-Up',
                labels: ['back'],
                isHidden: true,
              ),
            ]),
          ),
        ],
        child: const MaterialApp(
          home: WorkoutLoggerScreen(mode: WorkoutSessionMode.free),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('workout_logger_add_exercise')));
    await tester.pumpAndSettle();

    expect(find.text('Barbell Bench Press'), findsWidgets);
    expect(find.text('Pull-Up'), findsNothing);
  });

  testWidgets(
    'split-day logger shows last-workout set hints and hides legacy strip',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      final userDatabase = UserExerciseDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      addTearDown(userDatabase.close);

      final exerciseRepository = DriftExerciseRepository(
        database,
        userDatabase,
      );
      final splitRepository = DriftSplitRepository(database);
      final workoutRepository = DriftQuickWorkoutRepository(database);

      await exerciseRepository.seedIfEmpty();
      final exercises = await exerciseRepository.watchExercises().first;
      final exercise = exercises.first;

      final splitId = await splitRepository.createSplit(
        SplitDraftInput(
          name: 'Upper Lower',
          days: [
            DayPlanDraftInput(
              dayIndex: 1,
              title: 'Upper A',
              plannedExercises: [
                PlannedExerciseDraftInput(
                  orderIndex: 1,
                  exerciseId: exercise.id,
                  targetSets: 2,
                  repMin: 5,
                  repMax: 8,
                ),
              ],
            ),
          ],
        ),
      );

      await workoutRepository.saveWorkoutSession(
        mode: WorkoutSessionMode.splitDay,
        splitId: splitId,
        dayIndex: 1,
        sessionName: 'Upper A',
        startedAt: DateTime(2026, 2, 10, 10, 0),
        endedAt: DateTime(2026, 2, 10, 10, 25),
        exercises: [
          WorkoutExerciseLogInput(
            exerciseId: exercise.id,
            sets: const [LoggedSetInput(reps: 5, weightKg: 100, rpe: 8.0)],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            userExerciseDatabaseProvider.overrideWithValue(userDatabase),
          ],
          child: MaterialApp(
            home: WorkoutLoggerScreen(
              mode: WorkoutSessionMode.splitDay,
              splitId: splitId,
              dayIndex: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Suggested load:'), findsNothing);
      expect(find.textContaining('Best (all-time):'), findsNothing);
      expect(find.textContaining('Last: 100.0 x 5'), findsOneWidget);
      expect(find.textContaining('RPE 8.0'), findsOneWidget);
      expect(find.text('Last: -'), findsOneWidget);
      expect(find.textContaining('Reference:'), findsOneWidget);
    },
  );

  testWidgets(
    'free logger set hints use latest exercise session across all workout modes',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      final userDatabase = UserExerciseDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      addTearDown(userDatabase.close);

      final exerciseRepository = DriftExerciseRepository(
        database,
        userDatabase,
      );
      final workoutRepository = DriftQuickWorkoutRepository(database);
      await exerciseRepository.seedIfEmpty();
      final exercises = await exerciseRepository.watchExercises().first;
      final exercise = exercises.first;

      await workoutRepository.saveWorkoutSession(
        mode: WorkoutSessionMode.free,
        startedAt: DateTime(2026, 2, 11, 9, 0),
        endedAt: DateTime(2026, 2, 11, 9, 20),
        exercises: [
          WorkoutExerciseLogInput(
            exerciseId: exercise.id,
            sets: const [LoggedSetInput(reps: 10, weightKg: 60)],
          ),
        ],
      );
      await workoutRepository.saveWorkoutSession(
        mode: WorkoutSessionMode.splitDay,
        splitId: 'split_for_latest',
        dayIndex: 2,
        sessionName: 'Lower',
        startedAt: DateTime(2026, 2, 12, 9, 0),
        endedAt: DateTime(2026, 2, 12, 9, 20),
        exercises: [
          WorkoutExerciseLogInput(
            exerciseId: exercise.id,
            sets: const [LoggedSetInput(reps: 8, weightKg: 70)],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            userExerciseDatabaseProvider.overrideWithValue(userDatabase),
            exercisesProvider.overrideWith(
              (ref) => Stream.value([
                ExerciseWithLabels(
                  id: exercise.id,
                  name: exercise.name,
                  labels: exercise.labels,
                ),
              ]),
            ),
          ],
          child: const MaterialApp(
            home: WorkoutLoggerScreen(mode: WorkoutSessionMode.free),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('workout_logger_add_exercise')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(exercise.name).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Last: 70.0 x 8'), findsOneWidget);
      expect(find.textContaining('Suggested load:'), findsNothing);
      expect(find.textContaining('Best (all-time):'), findsNothing);
    },
  );
}
