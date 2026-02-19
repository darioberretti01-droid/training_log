import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/exercise_with_labels.dart';
import '../../core/state/providers.dart';
import '../workouts/quick_workout_repository.dart';

class ExerciseListScreen extends ConsumerWidget {
  const ExerciseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seedState = ref.watch(seedDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Log'),
        actions: [
          IconButton(
            key: const Key('open_split_builder'),
            tooltip: 'Split Builder',
            onPressed: () => context.push('/splits/builder'),
            icon: const Icon(Icons.view_week_outlined),
          ),
        ],
      ),
      body: seedState.when(
        data: (_) {
          final exercisesState = ref.watch(exercisesProvider);
          return exercisesState.when(
            data: (exercises) {
              final recentSessionsState = ref.watch(recentHomeSessionsProvider);
              return ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Recent sessions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _RecentSessionsSection(
                      state: recentSessionsState,
                      onRetry: () => ref.invalidate(recentHomeSessionsProvider),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  if (exercises.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No exercises available.')),
                    ),
                  ...List.generate(exercises.length, (index) {
                    final exercise = exercises[index];
                    final isLast = index == exercises.length - 1;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ExerciseTile(exercise: exercise),
                        if (!isLast) const Divider(height: 1),
                      ],
                    );
                  }),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorState(
              message: 'Failed to load exercises: $error',
              onRetry: () => ref.invalidate(exercisesProvider),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: 'Failed to initialize exercise data: $error',
          onRetry: () => ref.invalidate(seedDataProvider),
        ),
      ),
    );
  }
}

class _RecentSessionsSection extends StatelessWidget {
  const _RecentSessionsSection({required this.state, required this.onRetry});

  final AsyncValue<List<HomeSessionOverviewEntry>> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return state.when(
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
                  child: _HomeSessionCard(entry: session),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Failed to load recent sessions: $error'),
              const SizedBox(height: 10),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeSessionCard extends StatelessWidget {
  const _HomeSessionCard({required this.entry});

  final HomeSessionOverviewEntry entry;

  @override
  Widget build(BuildContext context) {
    final startedAt = DateTime.fromMillisecondsSinceEpoch(
      entry.session.startedAt,
    );
    final endedAt = DateTime.fromMillisecondsSinceEpoch(entry.session.endedAt);
    final durationMinutes = endedAt.difference(startedAt).inMinutes;

    final summary = _exerciseSummary(entry.exercises);
    final metadata = durationMinutes > 0
        ? '$durationMinutes min | ${entry.totalSets} sets'
        : '${entry.totalSets} sets';
    final primaryExerciseId = entry.exercises.isEmpty
        ? null
        : entry.exercises.first.exerciseId;

    return Card(
      child: ListTile(
        key: Key('home_recent_session_${entry.session.id}'),
        enabled: primaryExerciseId != null,
        onTap: primaryExerciseId == null
            ? null
            : () => context.push('/history/$primaryExerciseId'),
        title: Text(
          'Session ${DateFormat('yyyy-MM-dd HH:mm').format(startedAt)}',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(metadata), Text('Exercises: $summary')],
        ),
      ),
    );
  }
}

String _exerciseSummary(List<HomeSessionExerciseSummary> exercises) {
  if (exercises.isEmpty) {
    return 'none';
  }
  final names = exercises.map((exercise) => exercise.exerciseName).toList();
  final firstTwo = names.take(2).join(', ');
  final hiddenCount = names.length - 2;
  if (hiddenCount > 0) {
    return '$firstTwo (+$hiddenCount more)';
  }
  return firstTwo;
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise});

  final ExerciseWithLabels exercise;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(exercise.name),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 6,
          runSpacing: -8,
          children: exercise.labels
              .map(
                (label) => Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  label: Text(label),
                ),
              )
              .toList(growable: false),
        ),
      ),
      trailing: IconButton(
        tooltip: 'History',
        onPressed: () => context.push('/history/${exercise.id}'),
        icon: const Icon(Icons.history),
      ),
      onTap: () => context.push('/quick/${exercise.id}'),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
