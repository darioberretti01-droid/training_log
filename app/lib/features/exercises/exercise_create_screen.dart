import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/providers.dart';
import '../../core/widgets/label_pill_selector.dart';
import '../../l10n/app_localizations.dart';

class ExerciseCreateScreen extends ConsumerStatefulWidget {
  const ExerciseCreateScreen({super.key});

  @override
  ConsumerState<ExerciseCreateScreen> createState() =>
      _ExerciseCreateScreenState();
}

class _ExerciseCreateScreenState extends ConsumerState<ExerciseCreateScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<String> _labels = [];
  bool _isSaving = false;
  String? _validationMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labelsState = ref.watch(allLabelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('Create Exercise')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              key: const Key('exercise_create_save'),
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
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
          TextField(
            key: const Key('exercise_create_name'),
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.tr('Exercise name *'),
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            onChanged: (_) => _clearValidation(),
          ),
          const SizedBox(height: 12),
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
            Text(l10n.tr('No labels selected yet. Select at least one label.')),
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

  void _clearValidation() {
    if (_validationMessage != null) {
      setState(() => _validationMessage = null);
    }
  }

  Future<void> _save() async {
    _clearValidation();

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(
        () =>
            _validationMessage = context.l10n.tr('Exercise name is required.'),
      );
      return;
    }
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
          .createExercise(name: name, labels: _labels);
      ref.invalidate(exercisesProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('Exercise created.'))),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _validationMessage = context.l10n.format(
          'Could not create exercise: {error}',
          {'error': error},
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
