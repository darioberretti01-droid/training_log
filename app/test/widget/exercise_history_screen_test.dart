import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/core/db/app_database.dart';
import 'package:training_log_app/core/models/exercise_with_labels.dart';
import 'package:training_log_app/core/models/logged_set_input.dart';
import 'package:training_log_app/core/state/providers.dart';
import 'package:training_log_app/features/exercises/exercise_history_screen.dart';
import 'package:training_log_app/features/workouts/quick_workout_repository.dart';

import '../test_helpers/localized_test_app.dart';

void main() {
  testWidgets('history app bar shows only the exercise name on two lines', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exerciseByIdProvider.overrideWith((ref, exerciseId) async {
            return const ExerciseWithLabels(
              id: 'custom_row',
              name: 'An Extremely Long Exercise Name That Should Wrap Cleanly',
              labels: ['back'],
            );
          }),
          activeSplitProvider.overrideWith((ref) => const AsyncData(null)),
          quickWorkoutRepositoryProvider.overrideWithValue(
            _FakeQuickWorkoutRepository(),
          ),
        ],
        child: localizedTestApp(
          locale: const Locale('it'),
          home: const ExerciseHistoryScreen(exerciseId: 'custom_row'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final titleFinder = find.text(
      'An Extremely Long Exercise Name That Should Wrap Cleanly',
    );
    expect(titleFinder, findsOneWidget);
    expect(find.text('Storico'), findsNothing);
    expect(find.text('History'), findsNothing);

    final titleText = tester.widget<Text>(titleFinder);
    expect(titleText.maxLines, 2);
    expect(tester.takeException(), isNull);
  });
}

class _FakeQuickWorkoutRepository implements QuickWorkoutRepository {
  @override
  Future<PerformedSet?> getBestSetForExercise(String exerciseId) async => null;

  @override
  Future<PerformedSet?> getBestSetForExercises(
    List<String> exerciseIds,
  ) async => null;

  @override
  Future<PerformedSet?> getLastSetForExercises(
    List<String> exerciseIds,
  ) async => null;

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
  Future<List<ExerciseSessionHistoryEntry>> getRecentSessionsForExercises(
    List<String> exerciseIds, {
    int sessionLimit = 12,
  }) async => const [];

  @override
  Future<List<HomeSessionOverviewEntry>> getRecentSessionsOverview({
    int sessionLimit = 8,
    String? sessionType,
    String? splitId,
  }) async => const [];

  @override
  Future<HomeSessionOverviewEntry?> getLastSession({
    String? sessionType,
    String? splitId,
  }) async => null;

  @override
  Future<WorkoutSessionDetails?> getSessionDetails(String sessionId) async =>
      null;

  @override
  Future<void> updateWorkoutSession({
    required String sessionId,
    required DateTime endedAt,
    required List<WorkoutExerciseLogInput> exercises,
    String? sessionName,
  }) async {}

  @override
  Future<void> deleteWorkoutSession(String sessionId) async {}

  @override
  Future<String> saveQuickWorkout({
    required String exerciseId,
    required DateTime startedAt,
    required DateTime endedAt,
    required List<LoggedSetInput> sets,
  }) async => 'session_1';

  @override
  Future<String> saveWorkoutSession({
    required String mode,
    required DateTime startedAt,
    required DateTime endedAt,
    required List<WorkoutExerciseLogInput> exercises,
    String? splitId,
    int? dayIndex,
    String? sessionName,
  }) async => 'session_1';

  @override
  Future<WorkoutLoggerSessionReference?> getLastSplitDayWorkoutReference({
    required String splitId,
    required int dayIndex,
  }) async => null;

  @override
  Future<List<WorkoutLoggerExerciseSessionReference>>
  getLatestSessionReferencesForExercises(List<String> exerciseIds) async =>
      const [];
}
