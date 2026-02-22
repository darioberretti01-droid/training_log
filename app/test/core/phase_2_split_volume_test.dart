import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/features/splits/split_volume.dart';

void main() {
  test('summarizeSplitMuscleVolume aggregates day and split muscle sets', () {
    final summary = summarizeSplitMuscleVolume(
      days: const [
        SplitVolumeDayInput(
          dayIndex: 1,
          dayTitle: 'Upper A',
          exercises: [
            SplitVolumeExerciseInput(exerciseId: 'bench_press', targetSets: 3),
            SplitVolumeExerciseInput(exerciseId: 'pull_up', targetSets: 4),
          ],
        ),
        SplitVolumeDayInput(
          dayIndex: 2,
          dayTitle: 'Back Focus',
          exercises: [
            SplitVolumeExerciseInput(exerciseId: 'barbell_row', targetSets: 2),
          ],
        ),
      ],
      exerciseLabelsById: const {
        'bench_press': ['push', 'chest', 'triceps'],
        'pull_up': ['pull', 'back', 'biceps'],
        'barbell_row': ['pull', 'back', 'forearms'],
      },
      trackedMuscleLabels: const ['chest', 'back', 'biceps', 'triceps'],
    );

    expect(summary.totalPlannedSets, 9);
    expect(summary.daySummaries, hasLength(2));
    expect(summary.daySummaries[0].displayLabel, 'Day 1 (Upper A)');
    expect(summary.daySummaries[0].plannedSetCount, 7);
    expect(summary.daySummaries[1].plannedSetCount, 2);

    expect(summary.totalMuscleVolumes.map((entry) => entry.muscleLabel), [
      'Chest',
      'Back',
      'Biceps',
      'Triceps',
    ]);
    expect(summary.totalMuscleVolumes.map((entry) => entry.setCount), [
      3,
      6,
      4,
      3,
    ]);
  });

  test(
    'summarizeSplitMuscleVolume ignores invalid sets and keeps control label order',
    () {
      final summary = summarizeSplitMuscleVolume(
        days: const [
          SplitVolumeDayInput(
            dayIndex: 1,
            dayTitle: '',
            exercises: [
              SplitVolumeExerciseInput(exerciseId: 'a', targetSets: 0),
              SplitVolumeExerciseInput(exerciseId: 'a', targetSets: -2),
              SplitVolumeExerciseInput(exerciseId: 'b', targetSets: 3),
            ],
          ),
        ],
        exerciseLabelsById: const {
          'a': ['chest'],
          'b': ['compound', 'shoulders', 'shoulders', 'back'],
        },
        trackedMuscleLabels: const ['chest', 'back', 'shoulders', 'chest'],
      );

      expect(summary.totalPlannedSets, 3);
      expect(summary.daySummaries.single.displayLabel, 'Day 1');
      expect(summary.totalMuscleVolumes.map((entry) => entry.muscleLabel), [
        'Chest',
        'Back',
        'Shoulders',
      ]);
      expect(summary.totalMuscleVolumes.map((entry) => entry.setCount), [
        0,
        3,
        3,
      ]);
    },
  );
}
