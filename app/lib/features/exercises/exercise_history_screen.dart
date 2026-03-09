import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/app_database.dart';
import '../../core/models/exercise_with_labels.dart';
import '../../core/state/providers.dart';
import '../../l10n/app_localizations.dart';
import '../workouts/quick_workout_repository.dart';

class ExerciseHistoryScreen extends ConsumerWidget {
  const ExerciseHistoryScreen({required this.exerciseId, super.key});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final exerciseState = ref.watch(exerciseByIdProvider(exerciseId));

    return exerciseState.when(
      data: (exercise) {
        if (exercise == null) {
          return Scaffold(
            appBar: _buildExerciseHistoryAppBar(),
            body: Center(child: Text(l10n.tr('Exercise not found.'))),
          );
        }

        final lookup = ExerciseHistoryLookup(
          exerciseIds: exercise.lookupExerciseIds,
        );
        final bestSetState = ref.watch(bestSetByLookupProvider(lookup));
        final lastSetState = ref.watch(lastSetByLookupProvider(lookup));
        final sessionsState = ref.watch(recentSessionsByLookupProvider(lookup));

        return Scaffold(
          appBar: _buildExerciseHistoryAppBar(
            title: l10n.localizeExerciseName(exercise.name),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _LabelsSection(exercise: exercise),
              const SizedBox(height: 12),
              Text(
                l10n.tr('Performance'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _MetricCard(title: l10n.tr('Best set'), state: bestSetState),
              const SizedBox(height: 8),
              _CurrentSplitBestCard(exercise: exercise),
              const SizedBox(height: 8),
              _MetricCard(title: l10n.tr('Last set'), state: lastSetState),
              const SizedBox(height: 12),
              Text(
                l10n.tr('Recent sessions'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              sessionsState.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.tr('No sessions logged yet.')),
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
                    child: Text(
                      l10n.format('Failed to load {title}: {error}', {
                        'title': l10n.tr('History'),
                        'error': error,
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: _buildExerciseHistoryAppBar(),
        body: Center(
          child: Text(
            l10n.format('Failed to load exercise: {error}', {'error': error}),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildExerciseHistoryAppBar({String? title}) {
    return AppBar(
      toolbarHeight: title == null ? null : 72,
      title: title == null
          ? null
          : Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}

class _LabelsSection extends StatelessWidget {
  const _LabelsSection({required this.exercise});

  final ExerciseWithLabels exercise;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OverflowBar(
              spacing: 8,
              overflowSpacing: 8,
              alignment: MainAxisAlignment.spaceBetween,
              overflowAlignment: OverflowBarAlignment.end,
              children: [
                Text(
                  l10n.tr('Labels'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                OutlinedButton.icon(
                  key: const Key('exercise_history_edit_labels'),
                  onPressed: () =>
                      context.push('/exercises/${exercise.id}/labels'),
                  icon: const Icon(Icons.edit),
                  label: Text(l10n.tr('Edit Labels')),
                ),
              ],
            ),
            if (exercise.isStandard) ...[
              const SizedBox(height: 4),
              Text(
                exercise.canRestoreStandardLabels
                    ? l10n.tr(
                        'This is a standard app exercise with custom labels applied.',
                      )
                    : l10n.tr(
                        'This is one of the standard app exercises. Saving creates a temporary custom label override.',
                      ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            if (exercise.labels.isEmpty)
              Text(l10n.tr('No labels.'))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: exercise.labels
                    .map(
                      (label) =>
                          Chip(label: Text(l10n.localizeLabelName(label))),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.state});

  final String title;
  final AsyncValue<PerformedSet?> state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return state.when(
      data: (set) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: set == null
              ? Text(
                  l10n.format('{title}: no logged data yet.', {'title': title}),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      l10n.format('{reps} reps x {weight} kg', {
                        'reps': set.reps,
                        'weight': set.weightKg,
                      }),
                    ),
                    if (set.restSeconds != null)
                      Text(
                        l10n.format('Rest: {seconds}s', {
                          'seconds': set.restSeconds,
                        }),
                      ),
                    if (set.rpe != null) Text('RPE: ${set.rpe}'),
                    Text(
                      l10n.format('Logged: {value}', {
                        'value': _formatTimestamp(context, set.performedAt),
                      }),
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
          child: Text(
            l10n.format('Failed to load {title}: {error}', {
              'title': title,
              'error': error,
            }),
          ),
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
    final l10n = context.l10n;
    final activeSplitState = ref.watch(activeSplitProvider);

    return activeSplitState.when(
      data: (activeSplit) {
        if (activeSplit == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.tr('Best current split set: no active split selected.'),
              ),
            ),
          );
        }

        final detailsState = ref.watch(splitDetailsProvider(activeSplit.id));
        return detailsState.when(
          data: (details) {
            if (details == null) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.tr('Best current split set: active split not found.'),
                  ),
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
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.tr(
                      'Best current split set: exercise not in active split.',
                    ),
                  ),
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
                      ? Text(
                          l10n.tr(
                            'Best current split set: no logged data yet.',
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.tr('Best current split set'),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.format('{reps} reps x {weight} kg', {
                                'reps': set.reps,
                                'weight': set.weightKg,
                              }),
                            ),
                            if (set.restSeconds != null)
                              Text(
                                l10n.format('Rest: {seconds}s', {
                                  'seconds': set.restSeconds,
                                }),
                              ),
                            if (set.rpe != null) Text('RPE: ${set.rpe}'),
                            Text(
                              l10n.format('Logged: {value}', {
                                'value': _formatTimestamp(
                                  context,
                                  set.performedAt,
                                ),
                              }),
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
                  child: Text(
                    l10n.format(
                      'Failed to load current split best set: {error}',
                      {'error': error},
                    ),
                  ),
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
              child: Text(
                l10n.format('Failed to load active split details: {error}', {
                  'error': error,
                }),
              ),
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
          child: Text(
            l10n.format('Failed to load active split: {error}', {
              'error': error,
            }),
          ),
        ),
      ),
    );
  }
}

class _SetTile extends StatelessWidget {
  const _SetTile({required this.set, required this.isFirst});

  final PerformedSet set;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      title: Text(
        l10n.format('Set {index}: {reps} reps x {weight} kg', {
          'index': set.setIndex,
          'reps': set.reps,
          'weight': set.weightKg,
        }),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFirst)
            Text(
              l10n.format('Logged: {value}', {
                'value': _formatTimestamp(context, set.performedAt),
              }),
            ),
          if (set.restSeconds != null)
            Text(l10n.format('Rest: {seconds}s', {'seconds': set.restSeconds})),
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
    final l10n = context.l10n;
    final startedAt = DateTime.fromMillisecondsSinceEpoch(
      entry.session.startedAt,
    );
    final endedAt = DateTime.fromMillisecondsSinceEpoch(entry.session.endedAt);
    final duration = endedAt.difference(startedAt);
    final minutes = duration.inMinutes;

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(
              l10n.format('Session {date}', {
                'date': l10n.formatDateTimeCompact(startedAt),
              }),
            ),
            subtitle: Text(
              minutes > 0
                  ? l10n.format('{minutes} min | {sets} sets', {
                      'minutes': minutes,
                      'sets': entry.sets.length,
                    })
                  : l10n.setCountLabel(entry.sets.length),
            ),
          ),
          const Divider(height: 1),
          ...List.generate(
            entry.sets.length,
            (index) => _SetTile(set: entry.sets[index], isFirst: index == 0),
          ),
        ],
      ),
    );
  }
}

String _formatTimestamp(BuildContext context, int millisSinceEpoch) {
  return context.l10n.formatDateTimeCompact(
    DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch),
  );
}
