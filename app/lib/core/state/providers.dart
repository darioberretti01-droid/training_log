import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../models/exercise_with_labels.dart';
import '../../features/exercises/exercise_repository.dart';
import '../../features/splits/split_repository.dart';
import '../../features/workouts/quick_workout_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return DriftExerciseRepository(ref.watch(appDatabaseProvider));
});

final quickWorkoutRepositoryProvider = Provider<QuickWorkoutRepository>((ref) {
  return DriftQuickWorkoutRepository(ref.watch(appDatabaseProvider));
});

final splitRepositoryProvider = Provider<SplitRepository>((ref) {
  return DriftSplitRepository(ref.watch(appDatabaseProvider));
});

final seedDataProvider = FutureProvider<void>((ref) async {
  await ref.watch(exerciseRepositoryProvider).seedIfEmpty();
});

final exercisesProvider = StreamProvider<List<ExerciseWithLabels>>((ref) {
  return ref.watch(exerciseRepositoryProvider).watchExercises();
});

final exerciseByIdProvider = FutureProvider.family<ExerciseWithLabels?, String>(
  (ref, exerciseId) {
    return ref.watch(exerciseRepositoryProvider).getById(exerciseId);
  },
);

final bestSetByExerciseProvider = FutureProvider.family<PerformedSet?, String>((
  ref,
  exerciseId,
) {
  return ref
      .watch(quickWorkoutRepositoryProvider)
      .getBestSetForExercise(exerciseId);
});

final recentSetsByExerciseProvider =
    FutureProvider.family<List<PerformedSet>, String>((ref, exerciseId) {
      return ref
          .watch(quickWorkoutRepositoryProvider)
          .getRecentSetsForExercise(exerciseId);
    });

final recentSessionsByExerciseProvider =
    FutureProvider.family<List<ExerciseSessionHistoryEntry>, String>((
      ref,
      exerciseId,
    ) {
      return ref
          .watch(quickWorkoutRepositoryProvider)
          .getRecentSessionsForExercise(exerciseId);
    });

final recentHomeSessionsProvider =
    FutureProvider<List<HomeSessionOverviewEntry>>((ref) {
      return ref
          .watch(quickWorkoutRepositoryProvider)
          .getRecentSessionsOverview();
    });

final splitsProvider = StreamProvider<List<SplitSummary>>((ref) {
  return ref.watch(splitRepositoryProvider).watchSplits();
});

final activeSplitProvider = Provider<AsyncValue<SplitSummary?>>((ref) {
  final splitsState = ref.watch(splitsProvider);
  return splitsState.whenData((splits) {
    for (final split in splits) {
      if (split.isActive) {
        return split;
      }
    }
    return null;
  });
});

final splitDetailsProvider = FutureProvider.family<SplitDetails?, String>((
  ref,
  splitId,
) {
  return ref.watch(splitRepositoryProvider).getSplitById(splitId);
});
