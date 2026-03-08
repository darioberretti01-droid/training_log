import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/providers.dart';
import '../../l10n/app_localizations.dart';
import 'split_repository.dart';

class SplitsScreen extends ConsumerWidget {
  const SplitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final splitsState = ref.watch(splitsProvider);
    final splitBuilderDraftState = ref.watch(
      persistedSplitBuilderDraftProvider,
    );
    final hasSavedSplitDraft = splitBuilderDraftState.maybeWhen(
      data: (draft) => draft != null,
      orElse: () => false,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        context.go('/home');
      },
      child: splitsState.when(
        data: (splits) => _SplitsContent(
          splits: splits,
          hasSavedSplitDraft: hasSavedSplitDraft,
          onAddSplit: () async {
            if (hasSavedSplitDraft) {
              final shouldContinue = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(l10n.tr('Saved split draft found')),
                  content: Text(
                    l10n.tr(
                      'There is already a saved split draft. If you continue, you will overwrite it and the draft will be lost. Do you want to continue?',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(l10n.tr('Cancel')),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text(l10n.tr('Continue')),
                    ),
                  ],
                ),
              );
              if (shouldContinue != true) {
                return;
              }
              await ref.read(splitBuilderDraftStorageProvider).clearDraft();
              ref.invalidate(persistedSplitBuilderDraftProvider);
            }
            if (!context.mounted) {
              return;
            }
            await context.push('/splits/builder');
            ref.invalidate(persistedSplitBuilderDraftProvider);
          },
          onContinueSplitDraft: () async {
            await context.push('/splits/builder?resumeDraft=1');
            ref.invalidate(persistedSplitBuilderDraftProvider);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _SplitsErrorState(
          message: l10n.format('Failed to load splits: {error}', {
            'error': error,
          }),
          onRetry: () => ref.invalidate(splitsProvider),
        ),
      ),
    );
  }
}

class _SplitsContent extends StatelessWidget {
  const _SplitsContent({
    required this.splits,
    required this.hasSavedSplitDraft,
    required this.onAddSplit,
    required this.onContinueSplitDraft,
  });

  final List<SplitSummary> splits;
  final bool hasSavedSplitDraft;
  final Future<void> Function() onAddSplit;
  final Future<void> Function() onContinueSplitDraft;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actionColor = Theme.of(context).colorScheme.primary;
    SplitSummary? activeSplit;
    for (final split in splits) {
      if (split.isActive) {
        activeSplit = split;
        break;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              key: const Key('splits_add_button'),
              onPressed: onAddSplit,
              avatar: Icon(Icons.add, size: 18, color: actionColor),
              label: Text(
                l10n.tr('ADD SPLIT'),
                style: TextStyle(color: actionColor),
              ),
            ),
            if (hasSavedSplitDraft)
              OutlinedButton.icon(
                key: const Key('splits_continue_building_split_button'),
                onPressed: onContinueSplitDraft,
                icon: const Icon(Icons.play_arrow_outlined),
                label: Text(l10n.tr('Continue building split')),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          l10n.tr('Current split'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _CurrentSplitCard(split: activeSplit),
        const SizedBox(height: 20),
        Text(
          l10n.tr('All splits'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (splits.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                l10n.tr(
                  'No splits created yet. Tap ADD SPLIT to create your first split.',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ...splits.map((split) => _SplitListCard(split: split)),
      ],
    );
  }
}

class _CurrentSplitCard extends StatelessWidget {
  const _CurrentSplitCard({required this.split});

  final SplitSummary? split;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: split == null
            ? Text(context.l10n.tr('No active split selected.'))
            : ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  split!.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  _splitStatsLabel(context, split!.dayCount, split!.totalSets),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/splits/${split!.id}'),
              ),
      ),
    );
  }
}

class _SplitListCard extends ConsumerStatefulWidget {
  const _SplitListCard({required this.split});

  final SplitSummary split;

  @override
  ConsumerState<_SplitListCard> createState() => _SplitListCardState();
}

class _SplitListCardState extends ConsumerState<_SplitListCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final split = widget.split;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(split.name),
            subtitle: Text(
              _splitStatsLabel(context, split.dayCount, split.totalSets),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (split.isActive)
                  Chip(
                    label: Text(l10n.tr('Active')),
                    visualDensity: VisualDensity.compact,
                  ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  tooltip: _isExpanded
                      ? l10n.tr('Hide split summary')
                      : l10n.tr('Show split summary'),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => context.push('/splits/${split.id}'),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _SplitDisclosureContent(split: split),
            ),
        ],
      ),
    );
  }
}

class _SplitDisclosureContent extends ConsumerWidget {
  const _SplitDisclosureContent({required this.split});

  final SplitSummary split;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detailsState = ref.watch(splitDetailsProvider(split.id));
    return detailsState.when(
      data: (details) {
        if (details == null) {
          return Text(
            l10n.format('Split details unavailable.\nLast logged: {value}', {
              'value': _lastLoggedLabel(context, split.lastLoggedAt),
            }),
          );
        }

        final rows = <Widget>[];
        if (details.days.isEmpty) {
          rows.add(Text(l10n.tr('No day plans configured.')));
        } else {
          for (var dayIndex = 0; dayIndex < details.days.length; dayIndex++) {
            final day = details.days[dayIndex];
            final daySetTotal = day.plannedExercises.fold<int>(
              0,
              (sum, exercise) => sum + exercise.targetSets,
            );
            rows.add(
              Text(
                '${day.title}: ${l10n.setCountLabel(daySetTotal)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            );
            for (final exercise in day.plannedExercises) {
              rows.add(
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 2),
                  child: Text(
                    '${l10n.localizeExerciseName(exercise.exerciseName)}: ${l10n.setCountLabel(exercise.targetSets)}',
                  ),
                ),
              );
            }
            if (dayIndex != details.days.length - 1) {
              rows.add(const SizedBox(height: 8));
            }
          }
        }

        rows.add(const SizedBox(height: 10));
        rows.add(
          Text(
            l10n.format('Last logged: {value}', {
              'value': _lastLoggedLabel(context, split.lastLoggedAt),
            }),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (error, stackTrace) => Text(
        l10n.format('Could not load split summary.\nLast logged: {value}', {
          'value': _lastLoggedLabel(context, split.lastLoggedAt),
        }),
      ),
    );
  }
}

class _SplitsErrorState extends StatelessWidget {
  const _SplitsErrorState({required this.message, required this.onRetry});

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
            FilledButton(
              onPressed: onRetry,
              child: Text(context.l10n.tr('Retry')),
            ),
          ],
        ),
      ),
    );
  }
}

String _splitStatsLabel(BuildContext context, int dayCount, int totalSets) {
  final l10n = context.l10n;
  return '${l10n.dayCountLabel(dayCount)} | ${l10n.setCountLabel(totalSets)}';
}

String _lastLoggedLabel(BuildContext context, int? lastLoggedAtMs) {
  if (lastLoggedAtMs == null) {
    return context.l10n.tr('Never');
  }
  return context.l10n.formatDateTimeCompact(
    DateTime.fromMillisecondsSinceEpoch(lastLoggedAtMs),
  );
}
