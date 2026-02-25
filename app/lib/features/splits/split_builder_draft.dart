class SplitBuilderDraft {
  const SplitBuilderDraft({
    required this.splitName,
    required this.setAsActive,
    required this.selectedVolumeControlLabels,
    required this.manuallyCreatedControlLabels,
    required this.days,
    required this.updatedAtMs,
  });

  final String splitName;
  final bool setAsActive;
  final List<String> selectedVolumeControlLabels;
  final List<String> manuallyCreatedControlLabels;
  final List<SplitBuilderDayDraft> days;
  final int updatedAtMs;
}

class SplitBuilderDayDraft {
  const SplitBuilderDayDraft({
    required this.title,
    required this.plannedExercises,
  });

  final String title;
  final List<SplitBuilderPlannedExerciseDraft> plannedExercises;
}

class SplitBuilderPlannedExerciseDraft {
  const SplitBuilderPlannedExerciseDraft({
    required this.selectedExerciseId,
    required this.sets,
    required this.repMin,
    required this.repMax,
    required this.rest,
    required this.rpe,
  });

  final String? selectedExerciseId;
  final String sets;
  final String repMin;
  final String repMax;
  final String rest;
  final String rpe;
}
