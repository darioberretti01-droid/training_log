import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/state/providers.dart';
import '../../devtools/demo_fixture_models.dart';
import '../splits/split_repository.dart';
import '../workouts/workout_draft.dart';
import '../workouts/quick_workout_repository.dart';
import 'home_workout_logic.dart';

class HomeTabContent extends ConsumerWidget {
  const HomeTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestedState = ref.watch(suggestedWorkoutCardStateProvider);
    final splitsState = ref.watch(splitsProvider);
    final activeSplitState = ref.watch(activeSplitProvider);
    final lastSplitDaySessionState = ref.watch(lastSplitDaySessionProvider);
    final lastSessionState = ref.watch(lastHomeSessionProvider);
    final recentSessionsState = ref.watch(recentHomeSessionsProvider);
    final debugDraft = ref.watch(effectiveWorkoutDraftProvider);

    return ListView(
      key: const Key('home_scroll_view'),
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
        if (kDebugMode) ...[
          const SizedBox(height: 10),
          _HomeDebugDraftBanner(draft: debugDraft),
        ],
        const SizedBox(height: 16),
        _SuggestedWorkoutCard(
          suggestedState: suggestedState,
          splitsState: splitsState,
          activeSplitState: activeSplitState,
          lastSplitDaySessionState: lastSplitDaySessionState,
        ),
        const SizedBox(height: 12),
        _SecondaryActionsRow(
          splitsState: splitsState,
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
            ref.invalidate(lastSplitDaySessionProvider);
            ref.invalidate(suggestedWorkoutCardStateProvider);
          },
        ),
      ],
    );
  }
}

class _HomeDebugDraftBanner extends StatelessWidget {
  const _HomeDebugDraftBanner({required this.draft});

  final WorkoutDraft? draft;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = _debugText(draft);
    return Container(
      key: const Key('home_debug_draft_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.tertiary),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colorScheme.onTertiaryContainer),
      ),
    );
  }

  String _debugText(WorkoutDraft? draft) {
    if (draft == null) {
      return 'DEBUG draft: none';
    }
    final updated = DateTime.fromMillisecondsSinceEpoch(draft.updatedAtMs);
    final updatedLabel = DateFormat('MMM d HH:mm:ss').format(updated);
    final splitLabel = draft.splitId ?? '-';
    final dayLabel = draft.dayIndex?.toString() ?? '-';
    return 'DEBUG draft: mode=${draft.mode}, split=$splitLabel, day=$dayLabel, updated=$updatedLabel';
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

class _SuggestedWorkoutCard extends ConsumerWidget {
  const _SuggestedWorkoutCard({
    required this.suggestedState,
    required this.splitsState,
    required this.activeSplitState,
    required this.lastSplitDaySessionState,
  });

  final AsyncValue<SuggestedWorkoutCardState?> suggestedState;
  final AsyncValue<List<SplitSummary>> splitsState;
  final AsyncValue<SplitSummary?> activeSplitState;
  final AsyncValue<HomeSessionOverviewEntry?> lastSplitDaySessionState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayDraft = ref.watch(todayWorkoutDraftProvider);
    final recoveryState = _buildRecoveryState();
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: todayDraft != null
            ? _buildResumeContent(context, todayDraft)
            : recoveryState == null
            ? _buildSuggestedContent(context, ref)
            : _buildRecoveryContent(context, ref, recoveryState),
      ),
    );
  }

  HomeSplitRecoveryState? _buildRecoveryState() {
    final splits = splitsState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final activeSplit = activeSplitState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final lastSplitDaySession = lastSplitDaySessionState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    if (splits == null) {
      return null;
    }
    return getHomeSplitRecoveryState(
      splits: splits,
      activeSplit: activeSplit,
      lastSplitDaySession: lastSplitDaySession,
    );
  }

  Widget _buildSuggestedContent(BuildContext context, WidgetRef ref) {
    final activeSplit = activeSplitState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final splits =
        splitsState.maybeWhen(data: (value) => value, orElse: () => null) ??
        const <SplitSummary>[];
    final hasCurrentSplit = activeSplit != null;

    return suggestedState.when(
      data: (suggested) {
        if (suggested == null) {
          final primaryLabel = hasCurrentSplit
              ? 'Log current split'
              : 'Set current split';
          final primaryAction = hasCurrentSplit || splits.isEmpty
              ? null
              : () => _openSetCurrentSplitPicker(context, ref, splits);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Next workout',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                hasCurrentSplit
                    ? 'Current split has no available workout suggestion.'
                    : 'Set an active split to get a workout suggestion.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('home_log_current_split'),
                onPressed: primaryAction,
                child: Text(primaryLabel),
              ),
            ],
          );
        }

        return Column(
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
                _openSuggestedWorkout(context, suggested);
              },
              child: const Text('Log current split'),
            ),
          ],
        );
      },
      loading: () => const Text('Loading next workout...'),
      error: (error, _) => Text('Could not load next workout: $error'),
    );
  }

  Widget _buildRecoveryContent(
    BuildContext context,
    WidgetRef ref,
    HomeSplitRecoveryState recoveryState,
  ) {
    final suggested = suggestedState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final activeSplit = activeSplitState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final splits =
        splitsState.maybeWhen(data: (value) => value, orElse: () => null) ??
        const <SplitSummary>[];
    final hasCurrentSplit = activeSplit != null;
    final secondaryActionLabel = hasCurrentSplit
        ? 'Log new current split'
        : 'Set current split';
    final secondaryAction = hasCurrentSplit
        ? (suggested == null
              ? null
              : () => _openSuggestedWorkout(context, suggested))
        : (splits.isEmpty
              ? null
              : () => _openSetCurrentSplitPicker(context, ref, splits));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Next workout', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          recoveryState.wasLastUsedSplitDeleted
              ? 'Your last used split was deleted.'
              : 'Your last used split is not the current split.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (!recoveryState.wasLastUsedSplitDeleted &&
            recoveryState.lastUsedSplitName != null) ...[
          const SizedBox(height: 4),
          Text(
            'Last used: ${recoveryState.lastUsedSplitName}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        if (recoveryState.canRestoreLastUsedSplit)
          FilledButton(
            onPressed: () => _setActiveSplit(
              context,
              ref,
              recoveryState.lastUsedSplitId,
              'Set last used split as current.',
            ),
            child: const Text('Set last used split as current'),
          ),
        if (recoveryState.canRestoreLastUsedSplit) const SizedBox(height: 8),
        OutlinedButton(
          onPressed: secondaryAction,
          child: Text(secondaryActionLabel),
        ),
      ],
    );
  }

  Future<void> _setActiveSplit(
    BuildContext context,
    WidgetRef ref,
    String splitId,
    String successMessage,
  ) async {
    try {
      await ref.read(splitRepositoryProvider).setActiveSplit(splitId);
      ref.invalidate(splitsProvider);
      ref.invalidate(activeSplitDetailsProvider);
      ref.invalidate(suggestedWorkoutCardStateProvider);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not set active split: $error')),
      );
    }
  }

  Future<void> _openSetCurrentSplitPicker(
    BuildContext hostContext,
    WidgetRef ref,
    List<SplitSummary> splits,
  ) async {
    await showModalBottomSheet<void>(
      context: hostContext,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: splits
              .map(
                (split) => ListTile(
                  title: Text(split.name),
                  subtitle: Text(
                    split.dayCount == 1 ? '1 day' : '${split.dayCount} days',
                  ),
                  trailing: split.isActive
                      ? const Chip(
                          label: Text('Current'),
                          visualDensity: VisualDensity.compact,
                        )
                      : null,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _setActiveSplit(
                      hostContext,
                      ref,
                      split.id,
                      'Current split updated.',
                    );
                  },
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  void _openSuggestedWorkout(
    BuildContext context,
    SuggestedWorkoutCardState suggested,
  ) {
    context.push(
      '/workout-logger?mode=split_day'
      '&splitId=${Uri.encodeComponent(suggested.splitId)}'
      '&dayIndex=${suggested.nextDayIndex}',
    );
  }

  Widget _buildResumeContent(BuildContext context, WorkoutDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Next workout', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'You have an in-progress workout from today.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('home_keep_logging_today'),
          onPressed: () => _openDraftWorkout(context, draft),
          child: const Text("Keep logging today's workout"),
        ),
      ],
    );
  }

  void _openDraftWorkout(BuildContext context, WorkoutDraft draft) {
    if (draft.mode == WorkoutSessionMode.splitDay) {
      final splitId = draft.splitId;
      final dayIndex = draft.dayIndex;
      if (splitId == null || dayIndex == null || dayIndex <= 0) {
        return;
      }
      context.push(
        '/workout-logger?mode=split_day'
        '&splitId=${Uri.encodeComponent(splitId)}'
        '&dayIndex=$dayIndex',
      );
      return;
    }
    context.push('/workout-logger?mode=free');
  }
}

class _SecondaryActionsRow extends ConsumerWidget {
  const _SecondaryActionsRow({
    required this.splitsState,
    required this.onOpenWorkout,
  });

  final AsyncValue<List<SplitSummary>> splitsState;
  final void Function(String splitId, int dayIndex) onOpenWorkout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSplitDetailsState = ref.watch(activeSplitDetailsProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton(
          key: const Key('home_log_different_split'),
          onPressed: splitsState.when(
            data: (splits) {
              if (splits.isEmpty) {
                return null;
              }
              return () =>
                  _showSplitPicker(context, ref, splits, onOpenWorkout);
            },
            loading: () => null,
            error: (_, _) => null,
          ),
          child: const Text('Log different split'),
        ),
        OutlinedButton(
          key: const Key('home_log_different_day'),
          onPressed: activeSplitDetailsState.when(
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
          child: const Text('Log different day'),
        ),
        OutlinedButton(
          key: const Key('home_free_workout'),
          onPressed: () => context.push('/workout-logger?mode=free'),
          child: const Text('Free workout'),
        ),
        OutlinedButton(
          key: const Key('home_create_split'),
          onPressed: () => context.push('/splits/builder'),
          child: const Text('Create new split'),
        ),
      ],
    );
  }

  Future<void> _showSplitPicker(
    BuildContext hostContext,
    WidgetRef ref,
    List<SplitSummary> splits,
    void Function(String splitId, int dayIndex) onPickDay,
  ) async {
    await showModalBottomSheet<void>(
      context: hostContext,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: splits
              .map(
                (split) => ListTile(
                  title: Text(split.name),
                  subtitle: Text(
                    split.dayCount == 1 ? '1 day' : '${split.dayCount} days',
                  ),
                  trailing: split.isActive
                      ? const Chip(
                          label: Text('Current'),
                          visualDensity: VisualDensity.compact,
                        )
                      : null,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final splitDetails = await ref
                        .read(splitRepositoryProvider)
                        .getSplitById(split.id);
                    if (!hostContext.mounted) {
                      return;
                    }
                    if (splitDetails == null || splitDetails.days.isEmpty) {
                      ScaffoldMessenger.of(hostContext).showSnackBar(
                        const SnackBar(
                          content: Text('Selected split has no workout days.'),
                        ),
                      );
                      return;
                    }
                    await _showDayPicker(
                      hostContext,
                      split: splitDetails,
                      onPickDay: onPickDay,
                    );
                  },
                ),
              )
              .toList(growable: false),
        ),
      ),
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

    return Card(
      child: ListTile(
        key: Key('home_recent_session_${entry.session.id}'),
        onTap: () => context.push('/sessions/${entry.session.id}'),
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

class OtherTabContent extends ConsumerWidget {
  const OtherTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          const SizedBox(height: 12),
          const _DebugToolsCard(),
        ],
      ),
    );
  }
}

class _DebugToolsCard extends ConsumerStatefulWidget {
  const _DebugToolsCard();

  @override
  ConsumerState<_DebugToolsCard> createState() => _DebugToolsCardState();
}

class _DebugToolsCardState extends ConsumerState<_DebugToolsCard> {
  bool _isWorking = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('other_debug_tools'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Debug tools', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            FilledButton(
              key: const Key('debug_seed_demo_data'),
              onPressed: _isWorking ? null : _seedDemoData,
              child: _isWorking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Reset + seed demo data'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('debug_reset_all_data'),
              onPressed: _isWorking ? null : _resetAllData,
              child: const Text('Reset all data'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedDemoData() async {
    await _runAction(
      action: () async {
        await ref
            .read(demoFixtureServiceProvider)
            .resetAndSeed(
              DemoFixtureScenario.baseRealistic,
              now: ref.read(appClockProvider)(),
            );
      },
      successMessage: 'Demo fixture restored.',
    );
  }

  Future<void> _resetAllData() async {
    await _runAction(
      action: () async {
        await ref.read(demoFixtureServiceProvider).resetAllData();
      },
      successMessage: 'All local data has been reset.',
    );
  }

  Future<void> _runAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    setState(() => _isWorking = true);
    try {
      await action();
      ref.read(workoutDraftProvider.notifier).clearDraft();
      _invalidateAppState();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Debug action failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  void _invalidateAppState() {
    ref.invalidate(seedDataProvider);
    ref.invalidate(exercisesProvider);
    ref.invalidate(allLabelsProvider);
    ref.invalidate(labelCatalogProvider);
    ref.invalidate(splitsProvider);
    ref.invalidate(activeSplitProvider);
    ref.invalidate(activeSplitDetailsProvider);
    ref.invalidate(recentHomeSessionsProvider);
    ref.invalidate(lastHomeSessionProvider);
    ref.invalidate(lastSplitDaySessionProvider);
    ref.invalidate(suggestedWorkoutCardStateProvider);
    ref.invalidate(persistedWorkoutDraftProvider);
    ref.invalidate(effectiveWorkoutDraftProvider);
    ref.invalidate(todayWorkoutDraftProvider);
  }
}
