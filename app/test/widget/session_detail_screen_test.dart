import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/core/db/app_database.dart';
import 'package:training_log_app/core/models/logged_set_input.dart';
import 'package:training_log_app/core/state/providers.dart';
import 'package:training_log_app/features/workouts/quick_workout_repository.dart';
import 'package:training_log_app/features/workouts/session_detail_screen.dart';

import '../test_helpers/localized_test_app.dart';

void main() {
  testWidgets('session overview starts in view mode', (tester) async {
    final repository = _FakeQuickWorkoutRepository();
    await _pumpSessionDetail(tester, repository);

    expect(find.byKey(const Key('session_detail_edit')), findsOneWidget);
    expect(find.byKey(const Key('session_detail_delete')), findsOneWidget);
    expect(find.byKey(const Key('session_detail_save')), findsNothing);
    expect(find.byKey(const Key('session_detail_discard')), findsNothing);
    expect(
      find.byKey(const Key('session_detail_add_set_exercise_1')),
      findsNothing,
    );
  });

  testWidgets('deleting a set asks for confirmation in edit mode', (
    tester,
  ) async {
    final repository = _FakeQuickWorkoutRepository();
    await _pumpSessionDetail(tester, repository);

    await tester.tap(find.byKey(const Key('session_detail_edit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('session_detail_save')), findsOneWidget);
    expect(find.byKey(const Key('session_detail_discard')), findsOneWidget);
    expect(
      find.byKey(const Key('session_detail_delete_set_exercise_1')),
      findsOneWidget,
    );

    expect(find.byType(TextField), findsNWidgets(9));
    await tester.tap(
      find.byKey(const Key('session_detail_delete_set_exercise_1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete set?'), findsOneWidget);
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(9));

    await tester.tap(
      find.byKey(const Key('session_detail_delete_set_exercise_1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Confirm'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(5));
  });
}

Future<void> _pumpSessionDetail(
  WidgetTester tester,
  QuickWorkoutRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [quickWorkoutRepositoryProvider.overrideWithValue(repository)],
      child: localizedTestApp(
        home: const SessionDetailScreen(sessionId: 'session_1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
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
  Future<WorkoutSessionDetails?> getSessionDetails(String sessionId) async {
    return WorkoutSessionDetails(
      session: WorkoutSession(
        id: sessionId,
        sessionType: WorkoutSessionMode.free,
        startedAt: DateTime(2026, 2, 28, 8, 0).millisecondsSinceEpoch,
        endedAt: DateTime(2026, 2, 28, 8, 30).millisecondsSinceEpoch,
      ),
      exercises: const [
        WorkoutSessionExerciseDetails(
          exerciseId: 'exercise_1',
          exerciseName: 'Exercise 1',
          sets: [
            WorkoutSessionSetDetails(setIndex: 1, reps: 10, weightKg: 50),
            WorkoutSessionSetDetails(setIndex: 2, reps: 8, weightKg: 55),
          ],
        ),
      ],
    );
  }

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
