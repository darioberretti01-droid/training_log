import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/logged_set_input.dart';
import '../../core/state/providers.dart';
import '../../l10n/app_localizations.dart';

class QuickWorkoutScreen extends ConsumerStatefulWidget {
  const QuickWorkoutScreen({required this.exerciseId, super.key});

  final String exerciseId;

  @override
  ConsumerState<QuickWorkoutScreen> createState() => _QuickWorkoutScreenState();
}

class _QuickWorkoutScreenState extends ConsumerState<QuickWorkoutScreen> {
  late final DateTime _startedAt;
  late List<_SetControllers> _setControllers;
  bool _isSaving = false;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _startedAt = ref.read(appClockProvider)();
    _setControllers = List.generate(3, (_) => _SetControllers());
  }

  @override
  void dispose() {
    for (final controllers in _setControllers) {
      controllers.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final exerciseState = ref.watch(exerciseByIdProvider(widget.exerciseId));

    return exerciseState.when(
      data: (exercise) {
        if (exercise == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.tr('Quick Log'))),
            body: Center(child: Text(l10n.tr('Exercise not found.'))),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              l10n.format('Quick Log: {name}', {
                'name': l10n.localizeExerciseName(exercise.name),
              }),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton(
                  key: const Key('quick_workout_save'),
                  onPressed: _isSaving ? null : () => _save(exercise.name),
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
              Text(
                l10n.tr(
                  'Enter reps and weight (kg) for each set. Rest and RPE are optional.',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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
              const SizedBox(height: 12),
              ...List.generate(_setControllers.length, (index) {
                final controllers = _setControllers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SetCard(
                    index: index + 1,
                    controllers: controllers,
                    onChanged: _clearValidationMessage,
                    onRemove: _setControllers.length > 1
                        ? () => _removeSet(index)
                        : null,
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: _addSet,
                icon: const Icon(Icons.add),
                label: Text(l10n.tr('Add Set')),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.tr('Quick Log'))),
        body: Center(
          child: Text(
            l10n.format('Failed to load exercise: {error}', {'error': error}),
          ),
        ),
      ),
    );
  }

  void _addSet() {
    setState(() {
      _setControllers = [..._setControllers, _SetControllers()];
    });
  }

  void _removeSet(int index) {
    final removed = _setControllers[index];
    setState(() {
      _setControllers = [..._setControllers]..removeAt(index);
    });
    removed.dispose();
  }

  Future<void> _save(String exerciseName) async {
    _clearValidationMessage();
    final parsedSets = _parseSets();
    if (parsedSets == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(quickWorkoutRepositoryProvider)
          .saveQuickWorkout(
            exerciseId: widget.exerciseId,
            startedAt: _startedAt,
            endedAt: ref.read(appClockProvider)(),
            sets: parsedSets,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.format('Saved quick workout for {name}.', {
              'name': context.l10n.localizeExerciseName(exerciseName),
            }),
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.format('Could not save workout: {error}', {
              'error': error,
            }),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  List<LoggedSetInput>? _parseSets() {
    final parsed = <LoggedSetInput>[];

    for (var index = 0; index < _setControllers.length; index++) {
      final controllers = _setControllers[index];
      final repsText = controllers.repsController.text.trim();
      final weightText = controllers.weightController.text.trim();
      final restText = controllers.restController.text.trim();
      final rpeText = controllers.rpeController.text.trim();

      final reps = int.tryParse(repsText);
      final weight = double.tryParse(weightText);
      final rest = restText.isEmpty ? null : int.tryParse(restText);
      final rpe = rpeText.isEmpty ? null : double.tryParse(rpeText);

      if (reps == null || reps <= 0) {
        _showValidationError(
          context.l10n.format('Set {index}: reps must be a positive integer.', {
            'index': index + 1,
          }),
        );
        return null;
      }
      if (weight == null || weight <= 0) {
        _showValidationError(
          context.l10n.format(
            'Set {index}: weight must be a positive number.',
            {'index': index + 1},
          ),
        );
        return null;
      }
      if (restText.isNotEmpty && (rest == null || rest < 0)) {
        _showValidationError(
          context.l10n.format(
            'Set {index}: rest must be a non-negative integer.',
            {'index': index + 1},
          ),
        );
        return null;
      }
      if (rpeText.isNotEmpty && (rpe == null || rpe < 0 || rpe > 10)) {
        _showValidationError(
          context.l10n.format('Set {index}: RPE must be between 0 and 10.', {
            'index': index + 1,
          }),
        );
        return null;
      }

      parsed.add(
        LoggedSetInput(
          reps: reps,
          weightKg: weight,
          restSeconds: rest,
          rpe: rpe,
        ),
      );
    }

    return parsed;
  }

  void _showValidationError(String message) {
    setState(() {
      _validationMessage = message;
    });
  }

  void _clearValidationMessage() {
    if (_validationMessage != null) {
      setState(() {
        _validationMessage = null;
      });
    }
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard({
    required this.index,
    required this.controllers,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final _SetControllers controllers;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.format('Set {index}', {'index': index}),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    tooltip: l10n.tr('Remove set'),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: controllers.repsController,
                    fieldKey: Key('set_${index}_reps'),
                    label: l10n.tr('Reps *'),
                    decimal: false,
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    controller: controllers.weightController,
                    fieldKey: Key('set_${index}_weight'),
                    label: l10n.tr('Weight kg *'),
                    decimal: true,
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: controllers.restController,
                    fieldKey: Key('set_${index}_rest'),
                    label: l10n.tr('Rest sec'),
                    decimal: false,
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    controller: controllers.rpeController,
                    fieldKey: Key('set_${index}_rpe'),
                    label: l10n.tr('RPE'),
                    decimal: true,
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.fieldKey,
    required this.label,
    required this.decimal,
    required this.onChanged,
  });

  final TextEditingController controller;
  final Key fieldKey;
  final String label;
  final bool decimal;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: decimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _SetControllers {
  _SetControllers()
    : repsController = TextEditingController(),
      weightController = TextEditingController(),
      restController = TextEditingController(),
      rpeController = TextEditingController();

  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController restController;
  final TextEditingController rpeController;

  void dispose() {
    repsController.dispose();
    weightController.dispose();
    restController.dispose();
    rpeController.dispose();
  }
}
