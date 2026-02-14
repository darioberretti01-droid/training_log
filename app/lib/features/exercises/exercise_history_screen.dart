import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/state/providers.dart';

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
        final recentState = ref.watch(recentSetsByExerciseProvider(exerciseId));

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
              Text(
                'Recent sets',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              recentState.when(
                data: (sets) {
                  if (sets.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No sets logged yet.'),
                      ),
                    );
                  }

                  return Column(
                    children: sets
                        .map(
                          (set) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SetTile(set: set),
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
  const _SetTile({required this.set});

  final PerformedSet set;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('Set ${set.setIndex}: ${set.reps} reps x ${set.weightKg} kg'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatTimestamp(set.performedAt)),
            if (set.restSeconds != null) Text('Rest: ${set.restSeconds}s'),
            if (set.rpe != null) Text('RPE: ${set.rpe}'),
          ],
        ),
      ),
    );
  }
}

String _formatTimestamp(int millisSinceEpoch) {
  return DateFormat('yyyy-MM-dd HH:mm').format(
    DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch),
  );
}
