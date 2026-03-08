import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/exercise_with_labels.dart';
import '../../core/state/providers.dart';
import '../../core/widgets/label_pill_selector.dart';
import '../../l10n/app_localizations.dart';

class ExerciseLabelsScreen extends ConsumerStatefulWidget {
  const ExerciseLabelsScreen({required this.exerciseId, super.key});

  final String exerciseId;

  @override
  ConsumerState<ExerciseLabelsScreen> createState() =>
      _ExerciseLabelsScreenState();
}

class _ExerciseLabelsScreenState extends ConsumerState<ExerciseLabelsScreen> {
  final List<String> _labels = [];
  bool _didInitializeLabels = false;
  bool _isSaving = false;
  String? _validationMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final exerciseState = ref.watch(exerciseByIdProvider(widget.exerciseId));
    final labelsState = ref.watch(allLabelsProvider);
    return exerciseState.when(
      data: (exercise) {
        if (exercise == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.tr('Edit Labels'))),
            body: Center(child: Text(l10n.tr('Exercise not found.'))),
          );
        }

        if (!_didInitializeLabels) {
          _labels
            ..clear()
            ..addAll(exercise.labels);
          _labels.sort();
          _didInitializeLabels = true;
        }

        return _buildScaffold(context, exercise, labelsState);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.tr('Edit Labels'))),
        body: Center(
          child: Text(
            l10n.format('Failed to load exercise: {error}', {'error': error}),
          ),
        ),
      ),
    );
  }

  Scaffold _buildScaffold(
    BuildContext context,
    ExerciseWithLabels exercise,
    AsyncValue<List<String>> labelsState,
  ) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.format('Labels: {name}', {
            'name': l10n.localizeExerciseName(exercise.name),
          }),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              key: const Key('exercise_labels_save'),
              onPressed: _isSaving ? null : () => _save(exercise),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.tr('Save')),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (exercise.isStandard)
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  exercise.canRestoreStandardLabels
                      ? l10n.tr(
                          'This is a standard app exercise with custom labels applied.',
                        )
                      : l10n.tr(
                          'This is one of the standard app exercises. Saving creates a temporary custom label override.',
                        ),
                ),
              ),
            ),
          if (exercise.canRestoreStandardLabels) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                key: const Key('exercise_labels_restore_standard'),
                onPressed: _isSaving ? null : () => _restoreStandard(exercise),
                child: Text(l10n.tr('Back to standard labels')),
              ),
            ),
          ],
          const SizedBox(height: 8),
          labelsState.when(
            data: (allLabels) => LabelPillSelector(
              availableLabels: allLabels,
              selectedLabels: _labels,
              onSelectedLabelsChanged: (labels) {
                setState(() {
                  _labels
                    ..clear()
                    ..addAll(labels);
                  _validationMessage = null;
                });
              },
              onCreateLabel: (label) async {
                return ref.read(exerciseRepositoryProvider).createLabel(label);
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text(
              l10n.format('Failed to load labels: {error}', {'error': error}),
            ),
          ),
          const SizedBox(height: 12),
          if (_labels.isEmpty)
            Text(l10n.tr('No labels selected. Add at least one label.')),
          if (_validationMessage != null) ...[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _validationMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save(ExerciseWithLabels exercise) async {
    if (_labels.isEmpty) {
      setState(
        () => _validationMessage = context.l10n.tr('Add at least one label.'),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(exerciseRepositoryProvider)
          .saveLabels(exerciseId: exercise.id, labels: _labels);
      ref.invalidate(exercisesProvider);
      ref.invalidate(exerciseByIdProvider(exercise.id));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('Labels updated.'))),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(
        () => _validationMessage = context.l10n.format(
          'Could not save labels: {error}',
          {'error': error},
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _restoreStandard(ExerciseWithLabels exercise) async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(exerciseRepositoryProvider)
          .restoreStandardLabels(exercise.id);
      ref.invalidate(exercisesProvider);
      ref.invalidate(exerciseByIdProvider(exercise.id));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('Restored standard labels.'))),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(
        () => _validationMessage = context.l10n.format(
          'Could not restore labels: {error}',
          {'error': error},
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
