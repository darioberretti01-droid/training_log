import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/exercise_with_labels.dart';
import '../../core/state/providers.dart';

class ExerciseListScreen extends ConsumerWidget {
  const ExerciseListScreen({super.key, this.title = 'Exercises'});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const ExerciseListContent(),
    );
  }
}

class ExerciseListContent extends ConsumerWidget {
  const ExerciseListContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seedState = ref.watch(seedDataProvider);

    return seedState.when(
      data: (_) {
        final exercisesState = ref.watch(exercisesProvider);
        return exercisesState.when(
          data: (exercises) => ListView(
            children: [
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
          ),
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
    );
  }
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
        onPressed: () => context.push('/exercises/${exercise.id}/history'),
        icon: const Icon(Icons.history),
      ),
      onTap: () => context.push('/exercises/${exercise.id}/history'),
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
