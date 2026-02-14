import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/logged_set_input.dart';
import '../../core/state/providers.dart';

class QuickWorkoutScreen extends ConsumerStatefulWidget {
  const QuickWorkoutScreen({
    required this.exerciseId,
    super.key,
  });

  final String exerciseId;

  @override
  ConsumerState<QuickWorkoutScreen> createState() => _QuickWorkoutScreenState();
}

class _QuickWorkoutScreenState extends ConsumerState<QuickWorkoutScreen> {
  late final DateTime _startedAt;
  late List<_SetControllers> _setControllers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
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
    final exerciseState = ref.watch(exerciseByIdProvider(widget.exerciseId));

    return exerciseState.when(
      data: (exercise) {
        if (exercise == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quick Log')),
            body: const Center(
              child: Text('Exercise not found.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Quick Log: ${exercise.name}'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton(
                  onPressed: _isSaving ? null : () => _save(exercise.name),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Enter reps and weight (kg) for each set. Rest and RPE are optional.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ...List.generate(_setControllers.length, (index) {
                final controllers = _setControllers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SetCard(
                    index: index + 1,
                    controllers: controllers,
                    onRemove: _setControllers.length > 1
                        ? () => _removeSet(index)
                        : null,
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: _addSet,
                icon: const Icon(Icons.add),
                label: const Text('Add Set'),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Quick Log')),
        body: Center(
          child: Text('Failed to load exercise: $error'),
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
    final parsedSets = _parseSets();
    if (parsedSets == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(quickWorkoutRepositoryProvider).saveQuickWorkout(
            exerciseId: widget.exerciseId,
            startedAt: _startedAt,
            endedAt: DateTime.now(),
            sets: parsedSets,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved quick workout for $exerciseName.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save workout: $error')),
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
        _showValidationError('Set ${index + 1}: reps must be a positive integer.');
        return null;
      }
      if (weight == null || weight <= 0) {
        _showValidationError('Set ${index + 1}: weight must be a positive number.');
        return null;
      }
      if (restText.isNotEmpty && (rest == null || rest < 0)) {
        _showValidationError(
          'Set ${index + 1}: rest must be a non-negative integer.',
        );
        return null;
      }
      if (rpeText.isNotEmpty && (rpe == null || rpe < 0 || rpe > 10)) {
        _showValidationError('Set ${index + 1}: RPE must be between 0 and 10.');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard({
    required this.index,
    required this.controllers,
    this.onRemove,
  });

  final int index;
  final _SetControllers controllers;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Set $index',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    tooltip: 'Remove set',
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
                    label: 'Reps *',
                    decimal: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    controller: controllers.weightController,
                    label: 'Weight kg *',
                    decimal: true,
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
                    label: 'Rest sec',
                    decimal: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    controller: controllers.rpeController,
                    label: 'RPE',
                    decimal: true,
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
    required this.label,
    required this.decimal,
  });

  final TextEditingController controller;
  final String label;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: decimal
          ? [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ]
          : [
              FilteringTextInputFormatter.digitsOnly,
            ],
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
