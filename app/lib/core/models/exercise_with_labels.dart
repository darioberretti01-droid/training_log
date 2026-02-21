class ExerciseWithLabels {
  const ExerciseWithLabels({
    required this.id,
    required this.name,
    required this.labels,
    this.isHidden = false,
    this.isStandard = false,
    this.hasCustomLabelOverride = false,
    this.overrideExerciseId,
    this.historyExerciseIds = const [],
  });

  final String id;
  final String name;
  final List<String> labels;
  final bool isHidden;
  final bool isStandard;
  final bool hasCustomLabelOverride;
  final String? overrideExerciseId;
  final List<String> historyExerciseIds;

  bool get canRestoreStandardLabels => isStandard && hasCustomLabelOverride;

  List<String> get lookupExerciseIds => historyExerciseIds.isEmpty
      ? [id]
      : List.unmodifiable(historyExerciseIds);
}
