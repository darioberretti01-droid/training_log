import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../models/exercise_with_labels.dart';
import '../../features/exercises/exercise_repository.dart';
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

final seedDataProvider = FutureProvider<void>((ref) async {
  await ref.watch(exerciseRepositoryProvider).seedIfEmpty();
});

final exercisesProvider = StreamProvider<List<ExerciseWithLabels>>((ref) {
  return ref.watch(exerciseRepositoryProvider).watchExercises();
});

final exerciseByIdProvider = FutureProvider.family<ExerciseWithLabels?, String>((
  ref,
  exerciseId,
) {
  return ref.watch(exerciseRepositoryProvider).getById(exerciseId);
});

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
