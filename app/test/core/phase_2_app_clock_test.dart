import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_log_app/core/state/providers.dart';
import 'package:training_log_app/features/workouts/quick_workout_repository.dart';
import 'package:training_log_app/features/workouts/workout_draft.dart';

void main() {
  test('todayWorkoutDraftProvider uses injected app clock', () {
    final fixedNow = DateTime(2026, 2, 23, 9, 30);
    final todayDraft = WorkoutDraft(
      mode: WorkoutSessionMode.free,
      startedAtMs: fixedNow
          .subtract(const Duration(minutes: 20))
          .millisecondsSinceEpoch,
      updatedAtMs: fixedNow
          .subtract(const Duration(minutes: 2))
          .millisecondsSinceEpoch,
      exercises: const [],
    );

    final container = ProviderContainer(
      overrides: [appClockProvider.overrideWithValue(() => fixedNow)],
    );
    addTearDown(container.dispose);

    container.read(workoutDraftProvider.notifier).setDraft(todayDraft);
    expect(container.read(todayWorkoutDraftProvider), isNotNull);

    final staleDraft = WorkoutDraft(
      mode: WorkoutSessionMode.free,
      startedAtMs: fixedNow
          .subtract(const Duration(days: 1))
          .millisecondsSinceEpoch,
      updatedAtMs: fixedNow
          .subtract(const Duration(days: 1))
          .millisecondsSinceEpoch,
      exercises: const [],
    );
    container.read(workoutDraftProvider.notifier).setDraft(staleDraft);
    expect(container.read(todayWorkoutDraftProvider), isNull);
  });
}
