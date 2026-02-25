import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/state/providers.dart';
import 'split_repository.dart';

class SplitsScreen extends ConsumerWidget {
  const SplitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  title: const Text('Saved split draft found'),
                  content: const Text(
                    'There is already a saved split draft. If you continue, you will overwrite it and the draft will be lost. Do you want to continue?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('Continue'),
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
          message: 'Failed to load splits: $error',
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
              label: Text('ADD SPLIT', style: TextStyle(color: actionColor)),
            ),
            if (hasSavedSplitDraft)
              OutlinedButton.icon(
                key: const Key('splits_continue_building_split_button'),
                onPressed: onContinueSplitDraft,
                icon: const Icon(Icons.play_arrow_outlined),
                label: const Text('Continue building split'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Current split',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _CurrentSplitCard(split: activeSplit),
        const SizedBox(height: 20),
        const Text(
          'All splits',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (splits.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'No splits created yet. Tap ADD SPLIT to create your first split.',
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
            ? const Text('No active split selected.')
            : ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  split!.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(_dayCountLabel(split!.dayCount)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/splits/${split!.id}'),
              ),
      ),
    );
  }
}

class _SplitListCard extends StatelessWidget {
  const _SplitListCard({required this.split});

  final SplitSummary split;

  @override
  Widget build(BuildContext context) {
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(split.updatedAt);
    return Card(
      child: ListTile(
        title: Text(split.name),
        subtitle: Text(
          '${_dayCountLabel(split.dayCount)} | Updated ${DateFormat('yyyy-MM-dd HH:mm').format(updatedAt)}',
        ),
        trailing: split.isActive
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(
                    label: Text('Active'),
                    visualDensity: VisualDensity.compact,
                  ),
                  Icon(Icons.chevron_right),
                ],
              )
            : const Icon(Icons.chevron_right),
        onTap: () => context.push('/splits/${split.id}'),
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
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _dayCountLabel(int dayCount) {
  if (dayCount == 1) {
    return '1 day';
  }
  return '$dayCount days';
}
