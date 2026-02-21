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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        context.go('/home');
      },
      child: splitsState.when(
        data: (splits) => _SplitsContent(splits: splits),
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
  const _SplitsContent({required this.splits});

  final List<SplitSummary> splits;

  @override
  Widget build(BuildContext context) {
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
