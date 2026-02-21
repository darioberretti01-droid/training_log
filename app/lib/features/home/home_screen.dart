import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/state/providers.dart';
import '../exercises/exercise_list_screen.dart';
import '../splits/splits_screen.dart';
import '../workouts/quick_workout_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final title = _titleForIndex(_selectedIndex);
    final body = _bodyForIndex(_selectedIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: _actionsForIndex(_selectedIndex, context),
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.view_week_outlined),
            label: 'Splits',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            label: 'Exercises',
          ),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Other'),
        ],
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Splits';
      case 2:
        return 'Exercises';
      case 3:
        return 'Other';
      default:
        return 'Home';
    }
  }

  Widget _bodyForIndex(int index) {
    switch (index) {
      case 0:
        return const _HomeTabContent();
      case 1:
        return const SplitsScreen();
      case 2:
        return const ExerciseListContent();
      case 3:
        return const _OtherTabContent();
      default:
        return const _HomeTabContent();
    }
  }

  List<Widget>? _actionsForIndex(int index, BuildContext context) {
    if (index == 1) {
      return [
        IconButton(
          key: const Key('splits_add_button'),
          tooltip: 'Create split',
          onPressed: () => context.push('/splits/builder'),
          icon: const Icon(Icons.add_circle, size: 36),
        ),
      ];
    }

    if (index == 2) {
      return [
        IconButton(
          key: const Key('exercises_add_button'),
          tooltip: 'Create exercise',
          onPressed: () => context.push('/exercises/new'),
          icon: const Icon(Icons.add_circle, size: 36),
        ),
      ];
    }

    return null;
  }
}

class _HomeTabContent extends ConsumerWidget {
  const _HomeTabContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentSessionsState = ref.watch(recentHomeSessionsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 20),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SizedBox(
              height: 112,
              width: double.infinity,
              child: FilledButton(
                key: const Key('home_log_current_split'),
                onPressed: () {},
                child: const Text('Log current split'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('home_log_other_split'),
                  onPressed: () {},
                  child: const Text(
                    'Log from other split',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  key: const Key('home_log_single_exercises'),
                  onPressed: () {},
                  child: const Text(
                    'Log single exercises',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Recent sessions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _RecentSessionsSection(
          state: recentSessionsState,
          onRetry: () => ref.invalidate(recentHomeSessionsProvider),
        ),
      ],
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

class _OtherTabContent extends StatelessWidget {
  const _OtherTabContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            key: const Key('other_labels_item'),
            title: const Text('Labels'),
            subtitle: const Text('Browse and create labels'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/labels'),
          ),
        ),
      ],
    );
  }
}
