import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/state/providers.dart';
import '../splits/split_repository.dart';
import '../workouts/quick_workout_repository.dart';
import 'home_workout_logic.dart';

class HomeTabContent extends ConsumerWidget {
  const HomeTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestedState = ref.watch(suggestedWorkoutCardStateProvider);
    final activeSplitState = ref.watch(activeSplitProvider);
    final lastSessionState = ref.watch(lastHomeSessionProvider);
    final recentSessionsState = ref.watch(recentHomeSessionsProvider);
    final activeSplitDetailsState = ref.watch(activeSplitDetailsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Home', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          _activeSplitLine(activeSplitState),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 2),
        Text(
          _lastSessionLine(lastSessionState),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _SuggestedWorkoutCard(state: suggestedState),
        const SizedBox(height: 12),
        _SecondaryActionsRow(
          activeSplitState: activeSplitDetailsState,
          onOpenWorkout: (splitId, dayIndex) {
            context.push(
              '/workout-logger?mode=split_day'
              '&splitId=${Uri.encodeComponent(splitId)}'
              '&dayIndex=$dayIndex',
            );
          },
        ),
        const SizedBox(height: 20),
        Text('Recent sessions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _RecentSessionsSection(
          state: recentSessionsState,
          onRetry: () {
            ref.invalidate(recentHomeSessionsProvider);
            ref.invalidate(lastHomeSessionProvider);
            ref.invalidate(suggestedWorkoutCardStateProvider);
          },
        ),
      ],
    );
  }
}

String _activeSplitLine(AsyncValue<SplitSummary?> state) {
  return state.when(
    data: (split) {
      if (split == null) {
        return 'Active split: none';
      }
      return 'Active split: ${split.name}';
    },
    loading: () => 'Active split: loading...',
    error: (_, _) => 'Active split: unavailable',
  );
}

String _lastSessionLine(AsyncValue<HomeSessionOverviewEntry?> state) {
  return state.when(
    data: (session) {
      if (session == null) {
        return 'Last session: No sessions yet';
      }
      final startedAt = DateTime.fromMillisecondsSinceEpoch(
        session.session.startedAt,
      );
      final label = _sessionDisplayName(session);
      return 'Last session: $label | ${DateFormat('MMM d').format(startedAt)}';
    },
    loading: () => 'Last session: loading...',
    error: (_, _) => 'Last session: unavailable',
  );
}

class _SuggestedWorkoutCard extends StatelessWidget {
  const _SuggestedWorkoutCard({required this.state});

  final AsyncValue<SuggestedWorkoutCardState?> state;

  @override
  Widget build(BuildContext context) {
    return state.when(
      data: (suggested) {
        if (suggested == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set an active split to get a workout suggestion.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  const FilledButton(
                    key: Key('home_log_current_split'),
                    onPressed: null,
                    child: Text('Start workout'),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next workout',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Day ${suggested.nextDayIndex}: ${suggested.nextDayName}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  '${suggested.exerciseCount} exercises | ~${suggested.estimatedDurationMinutes} min',
                ),
                if (suggested.previewExerciseNames.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggested.previewExerciseNames
                        .map((name) => Chip(label: Text(name)))
                        .toList(growable: false),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('home_log_current_split'),
                  onPressed: () {
                    context.push(
                      '/workout-logger?mode=split_day'
                      '&splitId=${Uri.encodeComponent(suggested.splitId)}'
                      '&dayIndex=${suggested.nextDayIndex}',
                    );
                  },
                  child: const Text('Start workout'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Loading next workout...'),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Could not load next workout: $error'),
        ),
      ),
    );
  }
}

class _SecondaryActionsRow extends StatelessWidget {
  const _SecondaryActionsRow({
    required this.activeSplitState,
    required this.onOpenWorkout,
  });

  final AsyncValue<SplitDetails?> activeSplitState;
  final void Function(String splitId, int dayIndex) onOpenWorkout;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton(
          key: const Key('home_log_other_split'),
          onPressed: activeSplitState.when(
            data: (split) {
              if (split == null || split.days.isEmpty) {
                return null;
              }
              return () => _showDayPicker(
                context,
                split: split,
                onPickDay: onOpenWorkout,
              );
            },
            loading: () => null,
            error: (_, _) => null,
          ),
          child: const Text('Choose another workout'),
        ),
        OutlinedButton(
          key: const Key('home_free_workout'),
          onPressed: () => context.push('/workout-logger?mode=free'),
          child: const Text('Free workout'),
        ),
        OutlinedButton(
          key: const Key('home_log_single_exercises'),
          onPressed: () =>
              context.push('/workout-logger?mode=free&openPicker=1'),
          child: const Text('Log single exercise'),
        ),
      ],
    );
  }

  Future<void> _showDayPicker(
    BuildContext context, {
    required SplitDetails split,
    required void Function(String splitId, int dayIndex) onPickDay,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                split.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...split.days.map(
              (day) => ListTile(
                title: Text('Day ${day.dayIndex}: ${day.title}'),
                subtitle: Text('${day.plannedExercises.length} exercises'),
                onTap: () {
                  Navigator.of(context).pop();
                  onPickDay(split.id, day.dayIndex);
                },
              ),
            ),
          ],
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
          child: Text('Loading recent sessions...'),
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
    final title =
        '${_sessionDisplayName(entry)} - ${DateFormat('MMM d').format(startedAt)}';
    final primaryExerciseId = entry.exercises.isEmpty
        ? null
        : entry.exercises.first.exerciseId;

    return Card(
      child: ListTile(
        key: Key('home_recent_session_${entry.session.id}'),
        enabled: primaryExerciseId != null,
        onTap: primaryExerciseId == null
            ? null
            : () => context.push('/exercises/$primaryExerciseId/history'),
        title: Text(title),
        subtitle: Text('${entry.totalSets} sets'),
      ),
    );
  }
}

String _sessionDisplayName(HomeSessionOverviewEntry entry) {
  final explicit = entry.sessionName?.trim();
  if (explicit != null && explicit.isNotEmpty) {
    return explicit;
  }

  switch (entry.session.sessionType) {
    case WorkoutSessionMode.splitDay:
      if (entry.dayIndex != null) {
        return 'Day ${entry.dayIndex}';
      }
      return 'Split workout';
    case WorkoutSessionMode.free:
      return 'Free workout';
    default:
      return 'Quick workout';
  }
}

class OtherTabContent extends StatelessWidget {
  const OtherTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        context.go('/home');
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              key: const Key('other_labels_item'),
              title: const Text('Labels'),
              subtitle: const Text('Browse and create labels'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/other/labels'),
            ),
          ),
        ],
      ),
    );
  }
}
