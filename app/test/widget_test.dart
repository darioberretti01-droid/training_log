import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/app.dart';
import 'package:training_log_app/core/models/exercise_with_labels.dart';
import 'package:training_log_app/core/state/providers.dart';

void main() {
  testWidgets('App boots on Home tab and can switch to Exercises', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (count, error) => null,
        overrides: [
          seedDataProvider.overrideWith((ref) async {}),
          exercisesProvider.overrideWith(
            (ref) => Stream.value(const [
              ExerciseWithLabels(
                id: 'bench_press',
                name: 'Barbell Bench Press',
                labels: ['push', 'chest', 'triceps'],
              ),
            ]),
          ),
          exerciseCreatedAtMapProvider.overrideWith(
            (ref) => Stream.value(const {'bench_press': 1}),
          ),
          exerciseLogCountMapProvider.overrideWith(
            (ref) => Stream.value(const {'bench_press': 0}),
          ),
          recentHomeSessionsProvider.overrideWith((ref) async => const []),
          lastHomeSessionProvider.overrideWith((ref) async => null),
          suggestedWorkoutCardStateProvider.overrideWith((ref) async => null),
          activeSplitDetailsProvider.overrideWith((ref) async => null),
          activeSplitProvider.overrideWith(
            (ref) => const AsyncValue.data(null),
          ),
        ],
        child: const TrainingLogApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Home')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home_log_current_split')), findsOneWidget);
    expect(find.text('Exercises'), findsOneWidget);

    await tester.tap(find.text('Exercises'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Exercises'),
      ),
      findsOneWidget,
    );
    expect(find.text('Barbell Bench Press'), findsWidgets);
  });
}
