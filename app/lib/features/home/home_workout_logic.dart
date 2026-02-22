import 'package:collection/collection.dart';

import '../splits/split_repository.dart';
import '../workouts/quick_workout_repository.dart';

class SuggestedWorkoutCardState {
  const SuggestedWorkoutCardState({
    required this.splitId,
    required this.splitName,
    required this.nextDayName,
    required this.nextDayIndex,
    required this.exerciseCount,
    required this.estimatedDurationMinutes,
    required this.previewExerciseNames,
    required this.lastSessionSummary,
  });

  final String splitId;
  final String splitName;
  final String nextDayName;
  final int nextDayIndex;
  final int exerciseCount;
  final int estimatedDurationMinutes;
  final List<String> previewExerciseNames;
  final HomeSessionOverviewEntry? lastSessionSummary;
}

Future<SplitDetails?> getActiveSplit(SplitRepository splitRepository) async {
  final splits = await splitRepository.watchSplits().first;
  final activeSummary = splits.firstWhereOrNull((split) => split.isActive);
  if (activeSummary == null) {
    return null;
  }
  return splitRepository.getSplitById(activeSummary.id);
}

Future<HomeSessionOverviewEntry?> getLastSession(
  QuickWorkoutRepository workoutRepository, {
  String? activeSplitId,
}) {
  if (activeSplitId != null && activeSplitId.trim().isNotEmpty) {
    return workoutRepository.getLastSession(
      sessionType: WorkoutSessionMode.splitDay,
      splitId: activeSplitId,
    );
  }
  return workoutRepository.getLastSession();
}

int getNextDayIndexSequence(
  SplitDetails split,
  HomeSessionOverviewEntry? lastSession,
) {
  if (split.days.isEmpty) {
    return 0;
  }

  final lastDayIndex = lastSession?.dayIndex;
  if (lastSession != null &&
      lastSession.splitId == split.id &&
      lastDayIndex != null) {
    final currentIndex = split.days.indexWhere(
      (day) => day.dayIndex == lastDayIndex,
    );
    if (currentIndex >= 0) {
      return split.days[(currentIndex + 1) % split.days.length].dayIndex;
    }
  }

  return split.days.first.dayIndex;
}

Future<SuggestedWorkoutCardState?> getSuggestedWorkoutCardState({
  required SplitRepository splitRepository,
  required QuickWorkoutRepository workoutRepository,
}) async {
  final activeSplit = await getActiveSplit(splitRepository);
  if (activeSplit == null || activeSplit.days.isEmpty) {
    return null;
  }

  final lastSession = await getLastSession(
    workoutRepository,
    activeSplitId: activeSplit.id,
  );
  final nextDayIndex = getNextDayIndexSequence(activeSplit, lastSession);
  final nextDay =
      activeSplit.days.firstWhereOrNull(
        (day) => day.dayIndex == nextDayIndex,
      ) ??
      activeSplit.days.first;
  final exerciseCount = nextDay.plannedExercises.length;
  final estimatedMinutes = _estimateDurationMinutes(nextDay);

  return SuggestedWorkoutCardState(
    splitId: activeSplit.id,
    splitName: activeSplit.name,
    nextDayName: nextDay.title,
    nextDayIndex: nextDay.dayIndex,
    exerciseCount: exerciseCount,
    estimatedDurationMinutes: estimatedMinutes,
    previewExerciseNames: nextDay.plannedExercises
        .map((exercise) => exercise.exerciseName)
        .take(3)
        .toList(growable: false),
    lastSessionSummary: lastSession,
  );
}

int _estimateDurationMinutes(DayPlanDetails day) {
  var estimate = 0;
  for (final planned in day.plannedExercises) {
    estimate += planned.targetSets * 3;
  }
  if (estimate < 20 && day.plannedExercises.isNotEmpty) {
    return 20;
  }
  return estimate;
}
