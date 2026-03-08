import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/providers.dart';
import '../../devtools/demo_fixture_models.dart';
import '../../l10n/app_localizations.dart';
import '../splits/split_repository.dart';
import '../workouts/workout_draft.dart';
import '../workouts/quick_workout_repository.dart';
import 'home_workout_logic.dart';

class HomeTabContent extends ConsumerWidget {
  const HomeTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
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
        Text(
          l10n.tr('Home'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          _activeSplitLine(context, activeSplitState),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 2),
        Text(
          _lastSessionLine(context, lastSessionState),
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
        Text(
          l10n.tr('Recent sessions'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
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
    final text = _debugText(context, draft);
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

  String _debugText(BuildContext context, WorkoutDraft? draft) {
    final l10n = context.l10n;
    if (draft == null) {
      return l10n.tr('DEBUG draft: none');
    }
    final updated = DateTime.fromMillisecondsSinceEpoch(draft.updatedAtMs);
    final updatedLabel = l10n.formatMonthDayTimeSeconds(updated);
    final splitLabel = draft.splitId ?? '-';
    final dayLabel = draft.dayIndex?.toString() ?? '-';
    return l10n.format(
      'DEBUG draft: mode={mode}, split={split}, day={day}, updated={updated}',
      {
        'mode': draft.mode,
        'split': splitLabel,
        'day': dayLabel,
        'updated': updatedLabel,
      },
    );
  }
}

String _activeSplitLine(BuildContext context, AsyncValue<SplitSummary?> state) {
  final l10n = context.l10n;
  return state.when(
    data: (split) {
      if (split == null) {
        return l10n.tr('Active split: none');
      }
      return l10n.format('Active split: {name}', {'name': split.name});
    },
    loading: () => l10n.tr('Active split: loading...'),
    error: (_, _) => l10n.tr('Active split: unavailable'),
  );
}

String _lastSessionLine(
  BuildContext context,
  AsyncValue<HomeSessionOverviewEntry?> state,
) {
  final l10n = context.l10n;
  return state.when(
    data: (session) {
      if (session == null) {
        return l10n.tr('Last session: No sessions yet');
      }
      final startedAt = DateTime.fromMillisecondsSinceEpoch(
        session.session.startedAt,
      );
      final label = _sessionDisplayName(context, session);
      return l10n.format('Last session: {label} | {date}', {
        'label': label,
        'date': l10n.formatMonthDay(startedAt),
      });
    },
    loading: () => l10n.tr('Last session: loading...'),
    error: (_, _) => l10n.tr('Last session: unavailable'),
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
    final l10n = context.l10n;
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
              ? l10n.tr('Log current split')
              : l10n.tr('Set current split');
          final primaryAction = hasCurrentSplit || splits.isEmpty
              ? null
              : () => _openSetCurrentSplitPicker(context, ref, splits);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tr('Next workout'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                hasCurrentSplit
                    ? l10n.tr(
                        'Current split has no available workout suggestion.',
                      )
                    : l10n.tr(
                        'Set an active split to get a workout suggestion.',
                      ),
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
              l10n.tr('Next workout'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.format('Day {day}: {title}', {
                'day': suggested.nextDayIndex,
                'title': suggested.nextDayName,
              }),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.format('{count} exercises | ~{minutes} min', {
                'count': suggested.exerciseCount,
                'minutes': suggested.estimatedDurationMinutes,
              }),
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
              child: Text(l10n.tr('Log current split')),
            ),
          ],
        );
      },
      loading: () => Text(l10n.tr('Loading next workout...')),
      error: (error, _) => Text(
        l10n.format('Could not load next workout: {error}', {'error': error}),
      ),
    );
  }

  Widget _buildRecoveryContent(
    BuildContext context,
    WidgetRef ref,
    HomeSplitRecoveryState recoveryState,
  ) {
    final l10n = context.l10n;
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
        ? l10n.tr('Log new current split')
        : l10n.tr('Set current split');
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
        Text(
          l10n.tr('Next workout'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          recoveryState.wasLastUsedSplitDeleted
              ? l10n.tr('Your last used split was deleted.')
              : l10n.tr('Your last used split is not the current split.'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (!recoveryState.wasLastUsedSplitDeleted &&
            recoveryState.lastUsedSplitName != null) ...[
          const SizedBox(height: 4),
          Text(
            l10n.format('Last used: {name}', {
              'name': recoveryState.lastUsedSplitName,
            }),
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
              l10n.tr('Set last used split as current.'),
            ),
            child: Text(l10n.tr('Set last used split as current')),
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
        SnackBar(
          content: Text(
            context.l10n.format('Could not set active split: {error}', {
              'error': error,
            }),
          ),
        ),
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
                    hostContext.l10n.dayCountLabel(split.dayCount),
                  ),
                  trailing: split.isActive
                      ? Chip(
                          label: Text(hostContext.l10n.tr('Current')),
                          visualDensity: VisualDensity.compact,
                        )
                      : null,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _setActiveSplit(
                      hostContext,
                      ref,
                      split.id,
                      hostContext.l10n.tr('Current split updated.'),
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
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tr('Next workout'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tr('You have an in-progress workout from today.'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('home_keep_logging_today'),
          onPressed: () => _openDraftWorkout(context, draft),
          child: Text(l10n.tr("Keep logging today's workout")),
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
          child: Text(context.l10n.tr('Log different split')),
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
          child: Text(context.l10n.tr('Log different day')),
        ),
        OutlinedButton(
          key: const Key('home_free_workout'),
          onPressed: () => context.push('/workout-logger?mode=free'),
          child: Text(context.l10n.tr('Free workout')),
        ),
        OutlinedButton(
          key: const Key('home_create_split'),
          onPressed: () => context.push('/splits/builder'),
          child: Text(context.l10n.tr('Create new split')),
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
                    hostContext.l10n.dayCountLabel(split.dayCount),
                  ),
                  trailing: split.isActive
                      ? Chip(
                          label: Text(hostContext.l10n.tr('Current')),
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
                        SnackBar(
                          content: Text(
                            hostContext.l10n.tr(
                              'Selected split has no workout days.',
                            ),
                          ),
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
                title: Text(
                  context.l10n.format('Day {day}: {title}', {
                    'day': day.dayIndex,
                    'title': day.title,
                  }),
                ),
                subtitle: Text(
                  context.l10n.exerciseCountLabel(day.plannedExercises.length),
                ),
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
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(context.l10n.tr('No sessions logged yet.')),
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
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(context.l10n.tr('Loading recent sessions...')),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.format('Failed to load recent sessions: {error}', {
                  'error': error,
                }),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: onRetry,
                child: Text(context.l10n.tr('Retry')),
              ),
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
    final title = context.l10n.format('Last session: {label} | {date}', {
      'label': _sessionDisplayName(context, entry),
      'date': context.l10n.formatMonthDay(startedAt),
    });

    return Card(
      child: ListTile(
        key: Key('home_recent_session_${entry.session.id}'),
        onTap: () => context.push('/sessions/${entry.session.id}'),
        title: Text(title),
        subtitle: Text(context.l10n.setCountLabel(entry.totalSets)),
      ),
    );
  }
}

String _sessionDisplayName(
  BuildContext context,
  HomeSessionOverviewEntry entry,
) {
  final explicit = entry.sessionName?.trim();
  if (explicit != null && explicit.isNotEmpty) {
    return explicit;
  }

  final l10n = context.l10n;
  switch (entry.session.sessionType) {
    case WorkoutSessionMode.splitDay:
      if (entry.dayIndex != null) {
        return l10n.format('Day {day}', {'day': entry.dayIndex});
      }
      return l10n.tr('Split workout');
    case WorkoutSessionMode.free:
      return l10n.tr('Free workout');
    default:
      return l10n.tr('Quick workout');
  }
}

const _debugToolsPassword = 'DevAccess';

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
          const _LanguageSettingsCard(),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              key: const Key('other_labels_item'),
              title: Text(context.l10n.tr('Labels')),
              subtitle: Text(context.l10n.tr('Browse and create labels')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/other/labels'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              key: const Key('other_debug_tools_item'),
              title: Text(context.l10n.tr('Debug tools')),
              subtitle: Text(context.l10n.tr('Protected developer utilities')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openDebugTools(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDebugTools(BuildContext context) async {
    final unlocked = await _showDebugToolsPasswordPrompt(context);
    if (!context.mounted || !unlocked) {
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const DebugToolsScreen()));
  }

  Future<bool> _showDebugToolsPasswordPrompt(BuildContext context) async {
    final unlocked = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const _DebugToolsPasswordDialog(),
    );
    return unlocked ?? false;
  }
}

class _LanguageSettingsCard extends ConsumerWidget {
  const _LanguageSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final appLocaleState = ref.watch(appLocaleProvider);
    final selectedLocale = appLocaleState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final subtitle = l10n.languageDisplayName(selectedLocale?.languageCode);

    return Card(
      child: ListTile(
        key: const Key('other_language_item'),
        title: Text(l10n.tr('Language')),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showLanguagePicker(context, ref, selectedLocale),
      ),
    );
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    Locale? selectedLocale,
  ) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final selectedLanguageCode = selectedLocale?.languageCode;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(
                  l10n.tr('Language'),
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                subtitle: Text(l10n.tr('Choose app language')),
              ),
              _LanguageOptionTile(
                key: const Key('language_option_system'),
                label: l10n.tr('Follow system language'),
                selected: selectedLanguageCode == null,
                onTap: () async {
                  await ref.read(appLocaleProvider.notifier).useSystemLocale();
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
              _LanguageOptionTile(
                key: const Key('language_option_en'),
                label: l10n.tr('English'),
                selected: selectedLanguageCode == 'en',
                onTap: () async {
                  await ref
                      .read(appLocaleProvider.notifier)
                      .setLanguageCode('en');
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
              _LanguageOptionTile(
                key: const Key('language_option_it'),
                label: l10n.tr('Italian'),
                selected: selectedLanguageCode == 'it',
                onTap: () async {
                  await ref
                      .read(appLocaleProvider.notifier)
                      .setLanguageCode('it');
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: onTap,
    );
  }
}

class DebugToolsScreen extends StatelessWidget {
  const DebugToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tr('Debug tools'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [_DebugToolsCard()],
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
            Text(
              context.l10n.tr('Debug tools'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
                  : Text(context.l10n.tr('Reset + seed demo data')),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('debug_reset_all_data'),
              onPressed: _isWorking ? null : _resetAllData,
              child: Text(context.l10n.tr('Reset all data')),
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
      successMessage: context.l10n.tr('Demo fixture restored.'),
    );
  }

  Future<void> _resetAllData() async {
    await _runAction(
      action: () async {
        await ref.read(demoFixtureServiceProvider).resetAllData();
      },
      successMessage: context.l10n.tr('All local data has been reset.'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.format('Debug action failed: {error}', {
              'error': error,
            }),
          ),
        ),
      );
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

class _DebugToolsPasswordDialog extends StatefulWidget {
  const _DebugToolsPasswordDialog();

  @override
  State<_DebugToolsPasswordDialog> createState() =>
      _DebugToolsPasswordDialogState();
}

class _DebugToolsPasswordDialogState extends State<_DebugToolsPasswordDialog> {
  final TextEditingController _controller = TextEditingController();
  String _errorText = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.tr('Unlock debug tools')),
      content: TextField(
        key: const Key('debug_tools_password_field'),
        controller: _controller,
        autofocus: true,
        obscureText: true,
        decoration: InputDecoration(
          labelText: context.l10n.tr('Password'),
          errorText: _errorText.isEmpty ? null : _errorText,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.tr('Cancel')),
        ),
        FilledButton(
          key: const Key('debug_tools_password_submit'),
          onPressed: _submit,
          child: Text(context.l10n.tr('Unlock')),
        ),
      ],
    );
  }

  void _submit() {
    if (_controller.text == _debugToolsPassword) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _errorText = context.l10n.tr('Incorrect password');
    });
  }
}
