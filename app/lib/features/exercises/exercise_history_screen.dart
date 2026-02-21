import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/models/exercise_with_labels.dart';
import '../../core/state/providers.dart';
import '../workouts/quick_workout_repository.dart';

class ExerciseHistoryScreen extends ConsumerWidget {
  const ExerciseHistoryScreen({
    required this.exerciseId,
    super.key,
  });

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseState = ref.watch(exerciseByIdProvider(exerciseId));

    return exerciseState.when(
      data: (exercise) {
        if (exercise == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('History')),
            body: const Center(child: Text('Exercise not found.')),
          );
        }

        final lookup = ExerciseHistoryLookup(
          exerciseIds: exercise.lookupExerciseIds,
        );
        final bestSetState = ref.watch(bestSetByLookupProvider(lookup));
        final lastSetState = ref.watch(lastSetByLookupProvider(lookup));
        final sessionsState = ref.watch(recentSessionsByLookupProvider(lookup));

        return Scaffold(
          appBar: AppBar(title: Text('${exercise.name} History')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _LabelsSection(exercise: exercise),
              const SizedBox(height: 12),
              Text('Performance', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _MetricCard(
                title: 'Best set',
                state: bestSetState,
              ),
              const SizedBox(height: 8),
              _CurrentSplitBestCard(exercise: exercise),
              const SizedBox(height: 8),
              _MetricCard(
                title: 'Last set',
                state: lastSetState,
              ),
              const SizedBox(height: 12),
              Text('Recent sessions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              sessionsState.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No sessions logged yet.'),
                      ),
                    );
                  }

                  return Column(
                    children: sessions
                        .map(
                          (session) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SessionCard(entry: session),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      height: 24,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
                error: (error, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Failed to load set history: $error'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('History')),
        body: Center(child: Text('Failed to load exercise: $error')),
      ),
    );
  }
}

class _LabelsSection extends StatelessWidget {
  const _LabelsSection({required this.exercise});

  final ExerciseWithLabels exercise;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Labels',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                OutlinedButton.icon(
                  key: const Key('exercise_history_edit_labels'),
                  onPressed: () => context.push('/exercises/${exercise.id}/labels'),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ],
            ),
            if (exercise.isStandard) ...[
              const SizedBox(height: 4),
              Text(
                exercise.canRestoreStandardLabels
                    ? 'Standard exercise with custom labels.'
                    : 'Standard app exercise.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            if (exercise.labels.isEmpty)
              const Text('No labels.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: exercise.labels
                    .map((label) => Chip(label: Text(label)))
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.state,
  });

  final String title;
  final AsyncValue<PerformedSet?> state;

  @override
  Widget build(BuildContext context) {
    return state.when(
      data: (set) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: set == null
              ? Text('$title: no logged data yet.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text('${set.reps} reps x ${set.weightKg} kg'),
                    if (set.restSeconds != null) Text('Rest: ${set.restSeconds}s'),
                    if (set.rpe != null) Text('RPE: ${set.rpe}'),
                    Text(
                      'Logged: ${_formatTimestamp(set.performedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
        ),
      ),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            height: 24,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Failed to load $title: $error'),
        ),
      ),
    );
  }
}

class _CurrentSplitBestCard extends ConsumerWidget {
  const _CurrentSplitBestCard({required this.exercise});

  final ExerciseWithLabels exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSplitState = ref.watch(activeSplitProvider);

    return activeSplitState.when(
      data: (activeSplit) {
        if (activeSplit == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Best current split set: no active split selected.'),
            ),
          );
        }

        final detailsState = ref.watch(splitDetailsProvider(activeSplit.id));
        return detailsState.when(
          data: (details) {
            if (details == null) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Best current split set: active split not found.'),
                ),
              );
            }

            final activeSplitExerciseIds = <String>{};
            for (final day in details.days) {
              for (final planned in day.plannedExercises) {
                activeSplitExerciseIds.add(planned.exerciseId);
              }
            }

            final lookupIds = exercise.lookupExerciseIds
                .where(activeSplitExerciseIds.contains)
                .toList(growable: false);
            if (lookupIds.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Best current split set: exercise not in active split.'),
                ),
              );
            }

            final lookup = ExerciseHistoryLookup(exerciseIds: lookupIds);
            final bestState = ref.watch(bestSetByLookupProvider(lookup));
            return bestState.when(
              data: (set) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: set == null
                      ? const Text('Best current split set: no logged data yet.')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Best current split set',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text('${set.reps} reps x ${set.weightKg} kg'),
                            if (set.restSeconds != null)
                              Text('Rest: ${set.restSeconds}s'),
                            if (set.rpe != null) Text('RPE: ${set.rpe}'),
                            Text(
                              'Logged: ${_formatTimestamp(set.performedAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                ),
              ),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    height: 24,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
              error: (error, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load current split best set: $error'),
                ),
              ),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                height: 24,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load active split details: $error'),
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            height: 24,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Failed to load active split: $error'),
        ),
      ),
    );
  }
}

class _SetTile extends StatelessWidget {
  const _SetTile({
    required this.set,
    required this.isFirst,
  });

  final PerformedSet set;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      title: Text('Set ${set.setIndex}: ${set.reps} reps x ${set.weightKg} kg'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFirst) Text('Logged: ${_formatTimestamp(set.performedAt)}'),
          if (set.restSeconds != null) Text('Rest: ${set.restSeconds}s'),
          if (set.rpe != null) Text('RPE: ${set.rpe}'),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.entry});

  final ExerciseSessionHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final startedAt = DateTime.fromMillisecondsSinceEpoch(entry.session.startedAt);
    final endedAt = DateTime.fromMillisecondsSinceEpoch(entry.session.endedAt);
    final duration = endedAt.difference(startedAt);
    final minutes = duration.inMinutes;

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(
              'Session ${DateFormat('yyyy-MM-dd HH:mm').format(startedAt)}',
            ),
            subtitle: Text(
              minutes > 0 ? '$minutes min | ${entry.sets.length} sets' : '${entry.sets.length} sets',
            ),
          ),
          const Divider(height: 1),
          ...List.generate(
            entry.sets.length,
            (index) => _SetTile(
              set: entry.sets[index],
              isFirst: index == 0,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTimestamp(int millisSinceEpoch) {
  return DateFormat('yyyy-MM-dd HH:mm').format(
    DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch),
  );
}
