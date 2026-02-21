import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/user_exercise_database.dart';
import '../models/exercise_with_labels.dart';
import '../../features/exercises/exercise_repository.dart';
import '../../features/splits/split_repository.dart';
import '../../features/workouts/quick_workout_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final userExerciseDatabaseProvider = Provider<UserExerciseDatabase>((ref) {
  final database = UserExerciseDatabase();
  ref.onDispose(database.close);
  return database;
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return DriftExerciseRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(userExerciseDatabaseProvider),
  );
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

final allLabelsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(exerciseRepositoryProvider).watchAllLabels();
});

final exerciseByIdProvider = FutureProvider.family<ExerciseWithLabels?, String>(
  (ref, exerciseId) {
    return ref.watch(exerciseRepositoryProvider).getById(exerciseId);
  },
);

@immutable
class ExerciseHistoryLookup {
  const ExerciseHistoryLookup({
    required this.exerciseIds,
    this.sessionLimit = 12,
  });

  final List<String> exerciseIds;
  final int sessionLimit;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ExerciseHistoryLookup &&
        other.sessionLimit == sessionLimit &&
        listEquals(other.exerciseIds, exerciseIds);
  }

  @override
  int get hashCode => Object.hash(sessionLimit, Object.hashAll(exerciseIds));
}

final bestSetByExerciseProvider = FutureProvider.family<PerformedSet?, String>((
  ref,
  exerciseId,
) {
  return ref
      .watch(quickWorkoutRepositoryProvider)
      .getBestSetForExercise(exerciseId);
});

final bestSetByLookupProvider =
    FutureProvider.family<PerformedSet?, ExerciseHistoryLookup>((
      ref,
      lookup,
    ) {
      return ref
          .watch(quickWorkoutRepositoryProvider)
          .getBestSetForExercises(lookup.exerciseIds);
    });

final lastSetByLookupProvider =
    FutureProvider.family<PerformedSet?, ExerciseHistoryLookup>((ref, lookup) {
      return ref
          .watch(quickWorkoutRepositoryProvider)
          .getLastSetForExercises(lookup.exerciseIds);
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

final recentSessionsByLookupProvider =
    FutureProvider.family<List<ExerciseSessionHistoryEntry>, ExerciseHistoryLookup>((
      ref,
      lookup,
    ) {
      return ref
          .watch(quickWorkoutRepositoryProvider)
          .getRecentSessionsForExercises(
            lookup.exerciseIds,
            sessionLimit: lookup.sessionLimit,
          );
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
