import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/user_exercise_database.dart';
import '../models/exercise_with_labels.dart';
import '../time/app_clock.dart';
import '../../devtools/demo_fixture_service.dart';
import '../../features/exercises/exercise_repository.dart';
import '../../features/home/home_workout_logic.dart';
import '../../features/splits/split_builder_draft.dart';
import '../../features/splits/split_builder_draft_storage.dart';
import '../../features/splits/split_repository.dart';
import '../../features/workouts/workout_draft.dart';
import '../../features/workouts/workout_draft_storage.dart';
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

final appClockProvider = Provider<AppClock>((ref) => DateTime.now);

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

final exerciseCreatedAtMapProvider = StreamProvider<Map<String, int>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db
      .customSelect(
        'SELECT id, created_at FROM exercises',
        readsFrom: {db.exercises},
      )
      .watch()
      .map((rows) {
        final map = <String, int>{};
        for (final row in rows) {
          final id = row.read<String>('id');
          final createdAt = row.read<int>('created_at');
          map[id] = createdAt;
        }
        return map;
      });
});

final exerciseLogCountMapProvider = StreamProvider<Map<String, int>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db
      .customSelect(
        'SELECT exercise_id, COUNT(*) AS log_count '
        'FROM performed_sets GROUP BY exercise_id',
        readsFrom: {db.performedSets},
      )
      .watch()
      .map((rows) {
        final map = <String, int>{};
        for (final row in rows) {
          final exerciseId = row.read<String>('exercise_id');
          final count = row.read<int>('log_count');
          map[exerciseId] = count;
        }
        return map;
      });
});

final allLabelsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(exerciseRepositoryProvider).watchAllLabels();
});

final labelCatalogProvider = StreamProvider<List<LabelCatalogEntry>>((ref) {
  return ref.watch(exerciseRepositoryProvider).watchLabelCatalog();
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

@immutable
class WorkoutLoggerReferenceLookup {
  const WorkoutLoggerReferenceLookup({
    required this.mode,
    required this.orderedExerciseIds,
    this.splitId,
    this.dayIndex,
  });

  final String mode;
  final String? splitId;
  final int? dayIndex;
  final List<String> orderedExerciseIds;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is WorkoutLoggerReferenceLookup &&
        other.mode == mode &&
        other.splitId == splitId &&
        other.dayIndex == dayIndex &&
        listEquals(other.orderedExerciseIds, orderedExerciseIds);
  }

  @override
  int get hashCode =>
      Object.hash(mode, splitId, dayIndex, Object.hashAll(orderedExerciseIds));
}

@immutable
class WorkoutLoggerOccurrenceReference {
  const WorkoutLoggerOccurrenceReference({
    required this.exerciseId,
    required this.occurrenceIndex,
    required this.session,
    required this.sets,
  });

  final String exerciseId;
  final int occurrenceIndex;
  final WorkoutLoggerReferenceSession session;
  final List<WorkoutLoggerSetReference> sets;
}

@immutable
class WorkoutLoggerOccurrenceKey {
  const WorkoutLoggerOccurrenceKey({
    required this.exerciseId,
    required this.occurrenceIndex,
  });

  final String exerciseId;
  final int occurrenceIndex;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is WorkoutLoggerOccurrenceKey &&
        other.exerciseId == exerciseId &&
        other.occurrenceIndex == occurrenceIndex;
  }

  @override
  int get hashCode => Object.hash(exerciseId, occurrenceIndex);
}

@immutable
class WorkoutLoggerResolvedReferences {
  const WorkoutLoggerResolvedReferences({required this.occurrenceMap});

  const WorkoutLoggerResolvedReferences.empty()
    : occurrenceMap =
          const <
            WorkoutLoggerOccurrenceKey,
            WorkoutLoggerOccurrenceReference
          >{};

  final Map<WorkoutLoggerOccurrenceKey, WorkoutLoggerOccurrenceReference>
  occurrenceMap;

  bool get isEmpty => occurrenceMap.isEmpty;

  WorkoutLoggerOccurrenceReference? occurrenceFor({
    required String exerciseId,
    required int occurrenceIndex,
  }) {
    return occurrenceMap[WorkoutLoggerOccurrenceKey(
      exerciseId: exerciseId,
      occurrenceIndex: occurrenceIndex,
    )];
  }

  WorkoutLoggerSetReference? setFor({
    required String exerciseId,
    required int occurrenceIndex,
    required int setIndex,
  }) {
    final occurrence = occurrenceFor(
      exerciseId: exerciseId,
      occurrenceIndex: occurrenceIndex,
    );
    if (occurrence == null) {
      return null;
    }
    for (final set in occurrence.sets) {
      if (set.setIndex == setIndex) {
        return set;
      }
    }
    return null;
  }
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
    FutureProvider.family<PerformedSet?, ExerciseHistoryLookup>((ref, lookup) {
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
    FutureProvider.family<
      List<ExerciseSessionHistoryEntry>,
      ExerciseHistoryLookup
    >((ref, lookup) {
      return ref
          .watch(quickWorkoutRepositoryProvider)
          .getRecentSessionsForExercises(
            lookup.exerciseIds,
            sessionLimit: lookup.sessionLimit,
          );
    });

final workoutLoggerReferencesProvider =
    FutureProvider.family<
      WorkoutLoggerResolvedReferences,
      WorkoutLoggerReferenceLookup
    >((ref, lookup) async {
      if (lookup.orderedExerciseIds.isEmpty) {
        return const WorkoutLoggerResolvedReferences.empty();
      }

      final repo = ref.watch(quickWorkoutRepositoryProvider);
      final occurrences = <WorkoutLoggerOccurrenceReference>[];

      if (lookup.mode == WorkoutSessionMode.splitDay) {
        final splitId = lookup.splitId?.trim();
        final dayIndex = lookup.dayIndex;
        if (splitId == null ||
            splitId.isEmpty ||
            dayIndex == null ||
            dayIndex <= 0) {
          return const WorkoutLoggerResolvedReferences.empty();
        }
        final sessionReference = await repo.getLastSplitDayWorkoutReference(
          splitId: splitId,
          dayIndex: dayIndex,
        );
        if (sessionReference != null) {
          final currentExerciseSet = lookup.orderedExerciseIds.toSet();
          for (final occurrence in sessionReference.exerciseOccurrences) {
            if (!currentExerciseSet.contains(occurrence.exerciseId)) {
              continue;
            }
            occurrences.add(
              WorkoutLoggerOccurrenceReference(
                exerciseId: occurrence.exerciseId,
                occurrenceIndex: occurrence.occurrenceIndex,
                session: sessionReference.session,
                sets: occurrence.sets,
              ),
            );
          }
        }
      } else if (lookup.mode == WorkoutSessionMode.free) {
        final references = await repo.getLatestSessionReferencesForExercises(
          lookup.orderedExerciseIds,
        );
        for (final reference in references) {
          for (final occurrence in reference.occurrences) {
            occurrences.add(
              WorkoutLoggerOccurrenceReference(
                exerciseId: reference.exerciseId,
                occurrenceIndex: occurrence.occurrenceIndex,
                session: reference.session,
                sets: occurrence.sets,
              ),
            );
          }
        }
      } else {
        return const WorkoutLoggerResolvedReferences.empty();
      }

      final map =
          <WorkoutLoggerOccurrenceKey, WorkoutLoggerOccurrenceReference>{};
      for (final occurrence in occurrences) {
        map[WorkoutLoggerOccurrenceKey(
              exerciseId: occurrence.exerciseId,
              occurrenceIndex: occurrence.occurrenceIndex,
            )] =
            occurrence;
      }

      return WorkoutLoggerResolvedReferences(
        occurrenceMap: Map.unmodifiable(map),
      );
    });

final recentHomeSessionsProvider =
    FutureProvider<List<HomeSessionOverviewEntry>>((ref) {
      return ref
          .watch(quickWorkoutRepositoryProvider)
          .getRecentSessionsOverview(sessionLimit: 5);
    });

final lastHomeSessionProvider = FutureProvider<HomeSessionOverviewEntry?>((
  ref,
) {
  return ref.watch(quickWorkoutRepositoryProvider).getLastSession();
});

final lastSplitDaySessionProvider = FutureProvider<HomeSessionOverviewEntry?>((
  ref,
) {
  return ref
      .watch(quickWorkoutRepositoryProvider)
      .getLastSession(sessionType: WorkoutSessionMode.splitDay);
});

final suggestedWorkoutCardStateProvider =
    FutureProvider<SuggestedWorkoutCardState?>((ref) async {
      final activeSplitSummary = ref
          .watch(activeSplitProvider)
          .maybeWhen(data: (value) => value, orElse: () => null);
      if (activeSplitSummary == null) {
        return null;
      }

      final activeSplitDetails = await ref.watch(
        splitDetailsProvider(activeSplitSummary.id).future,
      );
      if (activeSplitDetails == null) {
        return null;
      }

      final lastSession = await ref
          .watch(quickWorkoutRepositoryProvider)
          .getLastSession(
            sessionType: WorkoutSessionMode.splitDay,
            splitId: activeSplitSummary.id,
          );
      return buildSuggestedWorkoutCardState(
        activeSplit: activeSplitDetails,
        lastSession: lastSession,
      );
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

final activeSplitDetailsProvider = FutureProvider<SplitDetails?>((ref) async {
  final activeSummary = ref
      .watch(activeSplitProvider)
      .maybeWhen(data: (value) => value, orElse: () => null);
  if (activeSummary == null) {
    return null;
  }
  return ref.watch(splitRepositoryProvider).getSplitById(activeSummary.id);
});

final sessionDetailsProvider =
    FutureProvider.family<WorkoutSessionDetails?, String>((ref, sessionId) {
      return ref
          .watch(quickWorkoutRepositoryProvider)
          .getSessionDetails(sessionId);
    });

class WorkoutDraftNotifier extends Notifier<WorkoutDraft?> {
  @override
  WorkoutDraft? build() => null;

  void setDraft(WorkoutDraft? draft) {
    state = draft;
  }

  void clearDraft() {
    state = null;
  }
}

final workoutDraftProvider =
    NotifierProvider<WorkoutDraftNotifier, WorkoutDraft?>(
      WorkoutDraftNotifier.new,
    );

final workoutDraftStorageProvider = Provider<WorkoutDraftStorage>((ref) {
  return WorkoutDraftStorage(ref.watch(appDatabaseProvider));
});

final splitBuilderDraftStorageProvider = Provider<SplitBuilderDraftStorage>((
  ref,
) {
  return SplitBuilderDraftStorage(ref.watch(appDatabaseProvider));
});

final demoFixtureServiceProvider = Provider<DemoFixtureService>((ref) {
  return DemoFixtureService(
    appDb: ref.watch(appDatabaseProvider),
    userDb: ref.watch(userExerciseDatabaseProvider),
    exerciseRepository: ref.watch(exerciseRepositoryProvider),
    workoutDraftStorage: ref.watch(workoutDraftStorageProvider),
  );
});

final persistedWorkoutDraftProvider = FutureProvider<WorkoutDraft?>((ref) {
  return ref.watch(workoutDraftStorageProvider).loadDraft();
});

final persistedSplitBuilderDraftProvider = FutureProvider<SplitBuilderDraft?>((
  ref,
) {
  return ref.watch(splitBuilderDraftStorageProvider).loadDraft();
});

final effectiveWorkoutDraftProvider = Provider<WorkoutDraft?>((ref) {
  final inMemory = ref.watch(workoutDraftProvider);
  if (inMemory != null) {
    return inMemory;
  }
  return ref
      .watch(persistedWorkoutDraftProvider)
      .maybeWhen(data: (value) => value, orElse: () => null);
});

final todayWorkoutDraftProvider = Provider<WorkoutDraft?>((ref) {
  final draft = ref.watch(effectiveWorkoutDraftProvider);
  if (draft == null) {
    return null;
  }
  if (!draft.isForToday(ref.watch(appClockProvider)())) {
    return null;
  }
  return draft;
});
