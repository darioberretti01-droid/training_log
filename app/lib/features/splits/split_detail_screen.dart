import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/state/providers.dart';
import 'split_repository.dart';

class SplitDetailScreen extends ConsumerStatefulWidget {
  const SplitDetailScreen({required this.splitId, super.key});

  final String splitId;

  @override
  ConsumerState<SplitDetailScreen> createState() => _SplitDetailScreenState();
}

class _SplitDetailScreenState extends ConsumerState<SplitDetailScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final detailsState = ref.watch(splitDetailsProvider(widget.splitId));
    return Scaffold(
      appBar: AppBar(
        title: detailsState.when(
          data: (details) => Text(details?.name ?? 'Split'),
          loading: () => const Text('Split'),
          error: (_, _) => const Text('Split'),
        ),
        actions: [
          IconButton(
            key: const Key('split_detail_edit'),
            tooltip: 'Edit split',
            onPressed: _isDeleting
                ? null
                : () => context.push('/splits/${widget.splitId}/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            key: const Key('split_detail_delete'),
            tooltip: 'Delete split',
            onPressed: _isDeleting ? null : _confirmDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: detailsState.when(
        data: (details) {
          if (details == null) {
            return const Center(child: Text('Split not found.'));
          }
          return _SplitDetailBody(details: details);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load split details: $error'),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('Do you want to delete this split?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await ref.read(splitRepositoryProvider).deleteSplit(widget.splitId);
      ref.invalidate(splitsProvider);
      ref.invalidate(splitDetailsProvider(widget.splitId));

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Split deleted.')),
      );
      context.go('/splits');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete split: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}

class _SplitDetailBody extends StatelessWidget {
  const _SplitDetailBody({required this.details});

  final SplitDetails details;

  @override
  Widget build(BuildContext context) {
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(details.updatedAt);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Updated ${DateFormat('yyyy-MM-dd HH:mm').format(updatedAt)}',
                ),
                const SizedBox(height: 6),
                Text('Days: ${details.days.length}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Days',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (details.days.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('This split has no days configured.'),
            ),
          ),
        ...details.days.map((day) => _DayDetailsCard(day: day)),
      ],
    );
  }
}

class _DayDetailsCard extends StatelessWidget {
  const _DayDetailsCard({required this.day});

  final DayPlanDetails day;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Day ${day.dayIndex}: ${day.title}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (day.plannedExercises.isEmpty)
              const Text('No planned exercises.')
            else
              ...day.plannedExercises.map(
                (planned) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${planned.orderIndex}. ${planned.exerciseName} - '
                    '${planned.targetSets} sets x ${planned.repMin}-${planned.repMax} reps',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
