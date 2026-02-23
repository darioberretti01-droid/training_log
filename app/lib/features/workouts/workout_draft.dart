import 'quick_workout_repository.dart';

class WorkoutDraft {
  const WorkoutDraft({
    required this.mode,
    required this.startedAtMs,
    required this.updatedAtMs,
    required this.exercises,
    this.splitId,
    this.dayIndex,
  });

  final String mode;
  final String? splitId;
  final int? dayIndex;
  final int startedAtMs;
  final int updatedAtMs;
  final List<WorkoutDraftExercise> exercises;

  bool isForToday(DateTime now) {
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(updatedAtMs);
    return updatedAt.year == now.year &&
        updatedAt.month == now.month &&
        updatedAt.day == now.day;
  }

  bool matchesLoggerContext({
    required String mode,
    String? splitId,
    int? dayIndex,
  }) {
    if (this.mode != mode) {
      return false;
    }
    if (mode == WorkoutSessionMode.splitDay) {
      return this.splitId == splitId && this.dayIndex == dayIndex;
    }
    return true;
  }
}

class WorkoutDraftExercise {
  const WorkoutDraftExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.labels,
    required this.repMin,
    required this.repMax,
    required this.targetSets,
    required this.rows,
    this.restSeconds,
    this.targetRpe,
  });

  final String exerciseId;
  final String exerciseName;
  final List<String> labels;
  final int repMin;
  final int repMax;
  final int targetSets;
  final int? restSeconds;
  final double? targetRpe;
  final List<WorkoutDraftSetRow> rows;
}

class WorkoutDraftSetRow {
  const WorkoutDraftSetRow({
    required this.weightText,
    required this.repsText,
    required this.rpeText,
    this.restSeconds,
  });

  final String weightText;
  final String repsText;
  final String rpeText;
  final int? restSeconds;
}
