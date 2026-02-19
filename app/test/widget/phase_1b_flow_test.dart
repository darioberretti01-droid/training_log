import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/core/db/app_database.dart';
import 'package:training_log_app/core/models/exercise_with_labels.dart';
import 'package:training_log_app/core/models/logged_set_input.dart';
import 'package:training_log_app/core/state/providers.dart';
import 'package:training_log_app/features/workouts/quick_workout_repository.dart';
import 'package:training_log_app/features/workouts/quick_workout_screen.dart';

void main() {
  testWidgets('quick workout shows inline validation and blocks save', (
    tester,
  ) async {
    final repository = _FakeQuickWorkoutRepository();
    await _pumpQuickWorkout(tester, repository);

    await tester.tap(find.byKey(const Key('quick_workout_save')));
    await tester.pumpAndSettle();

    expect(
      find.text('Set 1: reps must be a positive integer.'),
      findsOneWidget,
    );
    expect(repository.saveCalls, 0);
  });

  testWidgets('quick workout saves when required fields are valid', (
    tester,
  ) async {
    final repository = _FakeQuickWorkoutRepository();
    await _pumpQuickWorkout(tester, repository);

    await tester.enterText(find.byKey(const Key('set_1_reps')), '8');
    await tester.enterText(find.byKey(const Key('set_1_weight')), '60');
    await tester.enterText(find.byKey(const Key('set_2_reps')), '8');
    await tester.enterText(find.byKey(const Key('set_2_weight')), '62.5');
    await tester.enterText(find.byKey(const Key('set_3_reps')), '7');
    await tester.enterText(find.byKey(const Key('set_3_weight')), '65');

    await tester.tap(find.byKey(const Key('quick_workout_save')));
    await tester.pumpAndSettle();

    expect(repository.saveCalls, 1);
    expect(repository.lastSavedSets, isNotNull);
    expect(repository.lastSavedSets!, hasLength(3));
    expect(repository.lastSavedSets!.first.reps, 8);
    expect(repository.lastSavedSets!.first.weightKg, 60);
  });
}

Future<void> _pumpQuickWorkout(
  WidgetTester tester,
  _FakeQuickWorkoutRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        exerciseByIdProvider.overrideWith((ref, exerciseId) async {
          return const ExerciseWithLabels(
            id: 'bench_press',
            name: 'Barbell Bench Press',
            labels: ['push', 'chest', 'triceps'],
          );
        }),
        quickWorkoutRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        home: QuickWorkoutScreen(exerciseId: 'bench_press'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeQuickWorkoutRepository implements QuickWorkoutRepository {
  int saveCalls = 0;
  List<LoggedSetInput>? lastSavedSets;

  @override
  Future<PerformedSet?> getBestSetForExercise(String exerciseId) async => null;

  @override
  Future<List<PerformedSet>> getRecentSetsForExercise(
    String exerciseId, {
    int limit = 30,
  }) async => const [];

  @override
  Future<List<ExerciseSessionHistoryEntry>> getRecentSessionsForExercise(
    String exerciseId, {
    int sessionLimit = 12,
  }) async => const [];

  @override
  Future<List<HomeSessionOverviewEntry>> getRecentSessionsOverview({
    int sessionLimit = 8,
  }) async => const [];

  @override
  Future<String> saveQuickWorkout({
    required String exerciseId,
    required DateTime startedAt,
    required DateTime endedAt,
    required List<LoggedSetInput> sets,
  }) async {
    saveCalls += 1;
    lastSavedSets = sets;
    return 'session_1';
  }
}
