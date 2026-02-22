class SplitVolumeExerciseInput {
  const SplitVolumeExerciseInput({
    required this.exerciseId,
    required this.targetSets,
  });

  final String exerciseId;
  final int targetSets;
}

class SplitVolumeDayInput {
  const SplitVolumeDayInput({
    required this.dayIndex,
    required this.dayTitle,
    required this.exercises,
  });

  final int dayIndex;
  final String dayTitle;
  final List<SplitVolumeExerciseInput> exercises;
}

class MuscleSetVolume {
  const MuscleSetVolume({required this.muscleLabel, required this.setCount});

  final String muscleLabel;
  final int setCount;
}

class DayMuscleVolumeSummary {
  const DayMuscleVolumeSummary({
    required this.dayIndex,
    required this.dayTitle,
    required this.plannedSetCount,
    required this.muscleVolumes,
  });

  final int dayIndex;
  final String dayTitle;
  final int plannedSetCount;
  final List<MuscleSetVolume> muscleVolumes;

  String get displayLabel {
    final trimmed = dayTitle.trim();
    if (trimmed.isEmpty) {
      return 'Day $dayIndex';
    }
    return 'Day $dayIndex ($trimmed)';
  }
}

class SplitMuscleVolumeSummary {
  const SplitMuscleVolumeSummary({
    required this.daySummaries,
    required this.totalMuscleVolumes,
    required this.totalPlannedSets,
  });

  final List<DayMuscleVolumeSummary> daySummaries;
  final List<MuscleSetVolume> totalMuscleVolumes;
  final int totalPlannedSets;

  bool get hasTrackedMuscles => totalMuscleVolumes.isNotEmpty;

  bool get hasAnyVolume {
    for (final muscle in totalMuscleVolumes) {
      if (muscle.setCount > 0) {
        return true;
      }
    }
    return false;
  }
}

const defaultSplitVolumeControlLabels = <String>[
  'chest',
  'back',
  'shoulders',
  'biceps',
  'triceps',
  'quads',
  'glutes',
  'hamstrings',
];

SplitMuscleVolumeSummary summarizeSplitMuscleVolume({
  required List<SplitVolumeDayInput> days,
  required Map<String, List<String>> exerciseLabelsById,
  required List<String> trackedMuscleLabels,
}) {
  final trackedLabels = normalizeSplitVolumeControlLabels(trackedMuscleLabels);
  final daySummaries = <DayMuscleVolumeSummary>[];
  final totalByMuscle = <String, int>{
    for (final label in trackedLabels) label: 0,
  };
  var totalPlannedSets = 0;

  for (final day in days) {
    final dayByMuscle = <String, int>{
      for (final label in trackedLabels) label: 0,
    };
    var dayPlannedSets = 0;

    for (final planned in day.exercises) {
      final exerciseId = planned.exerciseId.trim();
      if (exerciseId.isEmpty || planned.targetSets <= 0) {
        continue;
      }

      dayPlannedSets += planned.targetSets;
      final labels = exerciseLabelsById[exerciseId] ?? const <String>[];
      final exerciseLabelSet = _normalizeLabelSet(labels);

      for (final muscle in trackedLabels) {
        if (!exerciseLabelSet.contains(muscle)) {
          continue;
        }
        dayByMuscle.update(
          muscle,
          (existing) => existing + planned.targetSets,
          ifAbsent: () => planned.targetSets,
        );
        totalByMuscle.update(
          muscle,
          (existing) => existing + planned.targetSets,
          ifAbsent: () => planned.targetSets,
        );
      }
    }

    totalPlannedSets += dayPlannedSets;
    daySummaries.add(
      DayMuscleVolumeSummary(
        dayIndex: day.dayIndex,
        dayTitle: day.dayTitle,
        plannedSetCount: dayPlannedSets,
        muscleVolumes: _volumeEntriesInOrder(dayByMuscle, trackedLabels),
      ),
    );
  }

  return SplitMuscleVolumeSummary(
    daySummaries: List.unmodifiable(daySummaries),
    totalMuscleVolumes: List.unmodifiable(
      _volumeEntriesInOrder(totalByMuscle, trackedLabels),
    ),
    totalPlannedSets: totalPlannedSets,
  );
}

List<String> normalizeSplitVolumeControlLabels(List<String> labels) {
  final unique = <String>{};
  for (final label in labels) {
    final normalized = _normalizeLabel(label);
    if (normalized.isEmpty) {
      continue;
    }
    unique.add(normalized);
  }
  return unique.toList(growable: false);
}

List<MuscleSetVolume> _volumeEntriesInOrder(
  Map<String, int> volumeByMuscle,
  List<String> order,
) {
  return order
      .map(
        (label) => MuscleSetVolume(
          muscleLabel: _displayMuscleLabel(label),
          setCount: volumeByMuscle[label] ?? 0,
        ),
      )
      .toList(growable: false);
}

String _normalizeLabel(String value) {
  return value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
}

Set<String> _normalizeLabelSet(List<String> labels) {
  final normalized = <String>{};
  for (final label in labels) {
    final value = _normalizeLabel(label);
    if (value.isNotEmpty) {
      normalized.add(value);
    }
  }
  return normalized;
}

String _displayMuscleLabel(String normalized) {
  return normalized
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
