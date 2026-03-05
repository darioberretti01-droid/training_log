import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/core/db/app_database.dart';
import 'package:training_log_app/core/models/exercise_with_labels.dart';
import 'package:training_log_app/core/state/providers.dart';
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
}
