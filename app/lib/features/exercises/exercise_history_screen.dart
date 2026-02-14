import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
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

        final bestState = ref.watch(bestSetByExerciseProvider(exerciseId));
        final sessionState = ref.watch(
          recentSessionsByExerciseProvider(exerciseId),
        );

        return Scaffold(
          appBar: AppBar(title: Text('${exercise.name} History')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              bestState.when(
                data: (bestSet) => _BestSetCard(bestSet: bestSet),
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
                    child: Text('Failed to load best set: $error'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Recent sessions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              sessionState.when(
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
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
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

class _BestSetCard extends StatelessWidget {
  const _BestSetCard({required this.bestSet});

  final PerformedSet? bestSet;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: bestSet == null
            ? const Text('Best set: no logged data yet.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Best set',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text('${bestSet!.reps} reps x ${bestSet!.weightKg} kg'),
                  if (bestSet!.restSeconds != null)
                    Text('Rest: ${bestSet!.restSeconds}s'),
                  if (bestSet!.rpe != null) Text('RPE: ${bestSet!.rpe}'),
                  const SizedBox(height: 4),
                  Text(
                    'Logged: ${_formatTimestamp(bestSet!.performedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
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
              minutes > 0 ? '$minutes min • ${entry.sets.length} sets' : '${entry.sets.length} sets',
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
