import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/exercise_with_labels.dart';
import '../../core/state/providers.dart';
import 'split_repository.dart';
import 'split_volume.dart';
import 'split_volume_widgets.dart';

class SplitBuilderScreen extends ConsumerStatefulWidget {
  const SplitBuilderScreen({super.key, this.editingSplitId});

  final String? editingSplitId;

  @override
  ConsumerState<SplitBuilderScreen> createState() => _SplitBuilderScreenState();
}

class _SplitBuilderScreenState extends ConsumerState<SplitBuilderScreen> {
  final TextEditingController _splitNameController = TextEditingController();
  final List<_DayDraft> _days = [_DayDraft()];
  final List<String> _selectedVolumeControlLabels = [
    ...defaultSplitVolumeControlLabels,
  ];
  final Set<String> _manuallyCreatedControlLabels = {};
  bool _setAsActive = true;
  bool _isSaving = false;
  bool _didHydrateFromExisting = false;
  String? _validationMessage;

  @override
  void dispose() {
    _splitNameController.dispose();
    for (final day in _days) {
      day.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingSplitId != null;
    final splitDetailsState = isEditing
        ? ref.watch(splitDetailsProvider(widget.editingSplitId!))
        : const AsyncValue<SplitDetails?>.data(null);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Split' : 'Split Builder'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              key: const Key('split_builder_save'),
              onPressed: _isSaving ? null : _save,
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
      body: splitDetailsState.when(
        data: (details) {
          if (isEditing) {
            if (details == null) {
              return _BuilderErrorState(
                message: 'Split not found.',
                onRetry: () {
                  ref.invalidate(splitDetailsProvider(widget.editingSplitId!));
                },
              );
            }

            if (!_didHydrateFromExisting) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _didHydrateFromExisting) {
                  return;
                }
                _hydrateFromSplitDetails(details);
              });
              return const Center(child: CircularProgressIndicator());
            }
          }

          return _buildSeedAndExercisesBody();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _BuilderErrorState(
          message: 'Failed to load split details: $error',
          onRetry: () {
            if (widget.editingSplitId != null) {
              ref.invalidate(splitDetailsProvider(widget.editingSplitId!));
            }
          },
        ),
      ),
    );
  }

  Widget _buildSeedAndExercisesBody() {
    final seedState = ref.watch(seedDataProvider);
    return seedState.when(
      data: (_) {
        final exercisesState = ref.watch(exercisesProvider);
        return exercisesState.when(
          data: (exercises) {
            final visibleExercises = _filterExercisesForBuilder(exercises);
            return _buildBody(context, visibleExercises);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _BuilderErrorState(
            message: 'Failed to load exercises: $error',
            onRetry: () => ref.invalidate(exercisesProvider),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _BuilderErrorState(
        message: 'Failed to initialize exercise data: $error',
        onRetry: () => ref.invalidate(seedDataProvider),
      ),
    );
  }

  List<ExerciseWithLabels> _filterExercisesForBuilder(
    List<ExerciseWithLabels> exercises,
  ) {
    final selectedExerciseIds = <String>{};
    for (final day in _days) {
      for (final planned in day.plannedExercises) {
        final selectedExerciseId = planned.selectedExerciseId;
        if (selectedExerciseId != null && selectedExerciseId.isNotEmpty) {
          selectedExerciseIds.add(selectedExerciseId);
        }
      }
    }

    return exercises
        .where(
          (exercise) =>
              !exercise.isHidden || selectedExerciseIds.contains(exercise.id),
        )
        .toList(growable: false);
  }

  void _hydrateFromSplitDetails(SplitDetails details) {
    _splitNameController.text = details.name;
    _setAsActive = details.isActive;

    for (final day in _days) {
      day.dispose();
    }
    _days.clear();
    for (final day in details.days) {
      final plannedExercises = day.plannedExercises
          .map(
            (planned) => _PlannedExerciseDraft(
              selectedExerciseId: planned.exerciseId,
              sets: planned.targetSets.toString(),
              repMin: planned.repMin.toString(),
              repMax: planned.repMax.toString(),
              rest: planned.restSeconds?.toString() ?? '',
              rpe: planned.targetRpe?.toString() ?? '',
            ),
          )
          .toList();

      _days.add(
        _DayDraft(title: day.title, plannedExercises: plannedExercises),
      );
    }
    if (_days.isEmpty) {
      _days.add(_DayDraft());
    }

    setState(() {
      _didHydrateFromExisting = true;
    });
  }

  Widget _buildBody(BuildContext context, List<ExerciseWithLabels> exercises) {
    final volumeSummary = _buildMuscleVolumeSummary(exercises);
    final availableControlLabels = _buildAvailableControlLabels(exercises);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Build a split with ordered training days and planned exercises.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('split_name_field'),
          controller: _splitNameController,
          decoration: const InputDecoration(
            labelText: 'Split name *',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _clearValidation(),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          key: const Key('split_set_active_switch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Set as active split'),
          value: _setAsActive,
          onChanged: (value) {
            setState(() => _setAsActive = value);
          },
        ),
        if (_validationMessage != null) ...[
          const SizedBox(height: 8),
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
        SplitBuilderMuscleVolumeCard(
          summary: volumeSummary,
          availableControlLabels: availableControlLabels,
          selectedControlLabels: _selectedVolumeControlLabels,
          onControlLabelsChanged: (labels) {
            setState(() {
              _selectedVolumeControlLabels
                ..clear()
                ..addAll(normalizeSplitVolumeControlLabels(labels));
            });
          },
          onCreateControlLabel: (label) async {
            final created = await ref
                .read(exerciseRepositoryProvider)
                .createLabel(label);
            if (created) {
              setState(() {
                final normalized = normalizeSplitVolumeControlLabels([label]);
                if (normalized.isNotEmpty) {
                  _manuallyCreatedControlLabels.add(normalized.first);
                }
              });
            }
            return created;
          },
        ),
        const SizedBox(height: 12),
        ...List.generate(_days.length, (dayIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DayCard(
              dayNumber: dayIndex + 1,
              dayDraft: _days[dayIndex],
              exercises: exercises,
              onChanged: _clearValidation,
              onAddExercise: () => _addExercise(dayIndex),
              onRemoveExercise: (exerciseIndex) =>
                  _removeExercise(dayIndex, exerciseIndex),
              onRemoveDay: _days.length > 1 ? () => _removeDay(dayIndex) : null,
            ),
          );
        }),
        OutlinedButton.icon(
          key: const Key('split_add_day'),
          onPressed: _addDay,
          icon: const Icon(Icons.add),
          label: const Text('Add Day'),
        ),
        if (exercises.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'No exercises available. Seed exercises before creating a split.',
            ),
          ),
      ],
    );
  }

  SplitMuscleVolumeSummary _buildMuscleVolumeSummary(
    List<ExerciseWithLabels> exercises,
  ) {
    final exerciseLabelsById = <String, List<String>>{};
    for (final exercise in exercises) {
      exerciseLabelsById[exercise.id] = exercise.labels;
    }

    final dayInputs = <SplitVolumeDayInput>[];
    for (var dayIndex = 0; dayIndex < _days.length; dayIndex++) {
      final day = _days[dayIndex];
      final dayExercises = <SplitVolumeExerciseInput>[];

      for (final planned in day.plannedExercises) {
        final exerciseId = planned.selectedExerciseId;
        if (exerciseId == null || exerciseId.isEmpty) {
          continue;
        }

        final sets =
            int.tryParse(planned.targetSetsController.text.trim()) ?? 0;
        if (sets <= 0) {
          continue;
        }

        dayExercises.add(
          SplitVolumeExerciseInput(exerciseId: exerciseId, targetSets: sets),
        );
      }

      dayInputs.add(
        SplitVolumeDayInput(
          dayIndex: dayIndex + 1,
          dayTitle: day.titleController.text.trim(),
          exercises: dayExercises,
        ),
      );
    }

    return summarizeSplitMuscleVolume(
      days: dayInputs,
      exerciseLabelsById: exerciseLabelsById,
      trackedMuscleLabels: _selectedVolumeControlLabels,
    );
  }

  List<String> _buildAvailableControlLabels(
    List<ExerciseWithLabels> exercises,
  ) {
    final labels = <String>{
      ...defaultSplitVolumeControlLabels,
      ..._selectedVolumeControlLabels,
      ..._manuallyCreatedControlLabels,
    };

    for (final exercise in exercises) {
      labels.addAll(normalizeSplitVolumeControlLabels(exercise.labels));
    }

    final sorted = labels.toList()..sort();
    return sorted;
  }

  void _addDay() {
    setState(() {
      _days.add(_DayDraft());
    });
  }

  void _removeDay(int dayIndex) {
    final removed = _days.removeAt(dayIndex);
    removed.dispose();
    setState(() {});
  }

  void _addExercise(int dayIndex) {
    setState(() {
      _days[dayIndex].plannedExercises.add(_PlannedExerciseDraft());
    });
  }

  void _removeExercise(int dayIndex, int exerciseIndex) {
    final day = _days[dayIndex];
    final removed = day.plannedExercises.removeAt(exerciseIndex);
    removed.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    _clearValidation();
    final input = _parseInput();
    if (input == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repository = ref.read(splitRepositoryProvider);
      final isEditing = widget.editingSplitId != null;
      late final String splitId;
      if (isEditing) {
        splitId = widget.editingSplitId!;
        await repository.updateSplit(splitId, input);
      } else {
        splitId = await repository.createSplit(input);
      }
      if (_setAsActive) {
        await repository.setActiveSplit(splitId);
      }

      ref.invalidate(splitsProvider);
      ref.invalidate(splitDetailsProvider(splitId));

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _setAsActive
                ? (isEditing
                      ? 'Saved split changes and set it active.'
                      : 'Saved split and set it active.')
                : (isEditing
                      ? 'Saved split changes.'
                      : 'Saved split successfully.'),
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save split: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  SplitDraftInput? _parseInput() {
    final splitName = _splitNameController.text.trim();
    if (splitName.isEmpty) {
      _showValidation('Split name is required.');
      return null;
    }
    if (_days.isEmpty) {
      _showValidation('At least one day is required.');
      return null;
    }

    final parsedDays = <DayPlanDraftInput>[];

    for (var dayIndex = 0; dayIndex < _days.length; dayIndex++) {
      final day = _days[dayIndex];
      final dayNumber = dayIndex + 1;
      final dayTitle = day.titleController.text.trim();
      if (dayTitle.isEmpty) {
        _showValidation('Day $dayNumber title is required.');
        return null;
      }
      if (day.plannedExercises.isEmpty) {
        _showValidation('Day $dayNumber must include at least one exercise.');
        return null;
      }

      final parsedExercises = <PlannedExerciseDraftInput>[];
      for (
        var orderIndex = 0;
        orderIndex < day.plannedExercises.length;
        orderIndex++
      ) {
        final exerciseDraft = day.plannedExercises[orderIndex];
        final exerciseNumber = orderIndex + 1;
        final exerciseId = exerciseDraft.selectedExerciseId;
        if (exerciseId == null || exerciseId.isEmpty) {
          _showValidation(
            'Day $dayNumber, exercise $exerciseNumber: choose an exercise.',
          );
          return null;
        }

        final sets = int.tryParse(
          exerciseDraft.targetSetsController.text.trim(),
        );
        if (sets == null || sets <= 0) {
          _showValidation(
            'Day $dayNumber, exercise $exerciseNumber: sets must be a positive integer.',
          );
          return null;
        }

        final repMin = int.tryParse(exerciseDraft.repMinController.text.trim());
        final repMax = int.tryParse(exerciseDraft.repMaxController.text.trim());
        if (repMin == null || repMin <= 0) {
          _showValidation(
            'Day $dayNumber, exercise $exerciseNumber: minimum reps must be positive.',
          );
          return null;
        }
        if (repMax == null || repMax < repMin) {
          _showValidation(
            'Day $dayNumber, exercise $exerciseNumber: maximum reps must be >= minimum reps.',
          );
          return null;
        }

        final restText = exerciseDraft.restSecondsController.text.trim();
        final restSeconds = restText.isEmpty ? null : int.tryParse(restText);
        if (restText.isNotEmpty && (restSeconds == null || restSeconds < 0)) {
          _showValidation(
            'Day $dayNumber, exercise $exerciseNumber: rest must be a non-negative integer.',
          );
          return null;
        }

        final rpeText = exerciseDraft.targetRpeController.text.trim();
        final targetRpe = rpeText.isEmpty ? null : double.tryParse(rpeText);
        if (rpeText.isNotEmpty &&
            (targetRpe == null || targetRpe < 0 || targetRpe > 10)) {
          _showValidation(
            'Day $dayNumber, exercise $exerciseNumber: target RPE must be between 0 and 10.',
          );
          return null;
        }

        parsedExercises.add(
          PlannedExerciseDraftInput(
            orderIndex: exerciseNumber,
            exerciseId: exerciseId,
            targetSets: sets,
            repMin: repMin,
            repMax: repMax,
            restSeconds: restSeconds,
            targetRpe: targetRpe,
          ),
        );
      }

      parsedDays.add(
        DayPlanDraftInput(
          dayIndex: dayNumber,
          title: dayTitle,
          plannedExercises: parsedExercises,
        ),
      );
    }

    return SplitDraftInput(name: splitName, days: parsedDays);
  }

  void _showValidation(String message) {
    setState(() {
      _validationMessage = message;
    });
  }

  void _clearValidation() {
    if (_validationMessage != null) {
      setState(() {
        _validationMessage = null;
      });
    }
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.dayNumber,
    required this.dayDraft,
    required this.exercises,
    required this.onChanged,
    required this.onAddExercise,
    required this.onRemoveExercise,
    this.onRemoveDay,
  });

  final int dayNumber;
  final _DayDraft dayDraft;
  final List<ExerciseWithLabels> exercises;
  final VoidCallback onChanged;
  final VoidCallback onAddExercise;
  final ValueChanged<int> onRemoveExercise;
  final VoidCallback? onRemoveDay;

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
                  'Day $dayNumber',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (onRemoveDay != null)
                  IconButton(
                    onPressed: onRemoveDay,
                    tooltip: 'Remove day',
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: Key('day_${dayNumber}_title'),
              controller: dayDraft.titleController,
              decoration: const InputDecoration(
                labelText: 'Day title *',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 12),
            ...List.generate(dayDraft.plannedExercises.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PlannedExerciseCard(
                  dayNumber: dayNumber,
                  exerciseNumber: index + 1,
                  draft: dayDraft.plannedExercises[index],
                  exercises: exercises,
                  onChanged: onChanged,
                  onRemove: dayDraft.plannedExercises.length > 1
                      ? () => onRemoveExercise(index)
                      : null,
                ),
              );
            }),
            OutlinedButton.icon(
              key: Key('day_${dayNumber}_add_exercise'),
              onPressed: onAddExercise,
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannedExerciseCard extends StatelessWidget {
  const _PlannedExerciseCard({
    required this.dayNumber,
    required this.exerciseNumber,
    required this.draft,
    required this.exercises,
    required this.onChanged,
    this.onRemove,
  });

  final int dayNumber;
  final int exerciseNumber;
  final _PlannedExerciseDraft draft;
  final List<ExerciseWithLabels> exercises;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Exercise $exerciseNumber',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    tooltip: 'Remove exercise',
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              key: Key('day_${dayNumber}_exercise_$exerciseNumber'),
              initialValue: draft.selectedExerciseId,
              items: exercises
                  .map(
                    (exercise) => DropdownMenuItem(
                      value: exercise.id,
                      child: Text(exercise.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                draft.selectedExerciseId = value;
                onChanged();
              },
              decoration: const InputDecoration(
                labelText: 'Exercise *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumericField(
                    fieldKey: Key(
                      'day_${dayNumber}_exercise_${exerciseNumber}_sets',
                    ),
                    controller: draft.targetSetsController,
                    label: 'Sets *',
                    allowDecimal: false,
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumericField(
                    fieldKey: Key(
                      'day_${dayNumber}_exercise_${exerciseNumber}_rep_min',
                    ),
                    controller: draft.repMinController,
                    label: 'Rep min *',
                    allowDecimal: false,
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumericField(
                    fieldKey: Key(
                      'day_${dayNumber}_exercise_${exerciseNumber}_rep_max',
                    ),
                    controller: draft.repMaxController,
                    label: 'Rep max *',
                    allowDecimal: false,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumericField(
                    fieldKey: Key(
                      'day_${dayNumber}_exercise_${exerciseNumber}_rest',
                    ),
                    controller: draft.restSecondsController,
                    label: 'Rest sec',
                    allowDecimal: false,
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumericField(
                    fieldKey: Key(
                      'day_${dayNumber}_exercise_${exerciseNumber}_rpe',
                    ),
                    controller: draft.targetRpeController,
                    label: 'Target RPE',
                    allowDecimal: true,
                    onChanged: onChanged,
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

class _NumericField extends StatelessWidget {
  const _NumericField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.allowDecimal,
    required this.onChanged,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final bool allowDecimal;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        allowDecimal
            ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            : FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

class _BuilderErrorState extends StatelessWidget {
  const _BuilderErrorState({required this.message, required this.onRetry});

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

class _DayDraft {
  _DayDraft({String? title, List<_PlannedExerciseDraft>? plannedExercises})
    : titleController = TextEditingController(text: title ?? ''),
      plannedExercises = plannedExercises ?? [_PlannedExerciseDraft()];

  final TextEditingController titleController;
  final List<_PlannedExerciseDraft> plannedExercises;

  void dispose() {
    titleController.dispose();
    for (final exercise in plannedExercises) {
      exercise.dispose();
    }
  }
}

class _PlannedExerciseDraft {
  _PlannedExerciseDraft({
    this.selectedExerciseId,
    String sets = '3',
    String repMin = '8',
    String repMax = '12',
    String rest = '',
    String rpe = '',
  }) : targetSetsController = TextEditingController(text: sets),
       repMinController = TextEditingController(text: repMin),
       repMaxController = TextEditingController(text: repMax),
       restSecondsController = TextEditingController(text: rest),
       targetRpeController = TextEditingController(text: rpe);

  String? selectedExerciseId;
  final TextEditingController targetSetsController;
  final TextEditingController repMinController;
  final TextEditingController repMaxController;
  final TextEditingController restSecondsController;
  final TextEditingController targetRpeController;

  void dispose() {
    targetSetsController.dispose();
    repMinController.dispose();
    repMaxController.dispose();
    restSecondsController.dispose();
    targetRpeController.dispose();
  }
}
