import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/exercise_with_labels.dart';
import '../../core/state/providers.dart';
import '../../core/time/app_clock.dart';
import '../../l10n/app_localizations.dart';
import '../exercises/exercise_list_screen.dart';
import 'split_builder_draft.dart';
import 'split_builder_draft_storage.dart';
import 'split_repository.dart';
import 'split_volume.dart';
import 'split_volume_widgets.dart';

class SplitBuilderScreen extends ConsumerStatefulWidget {
  const SplitBuilderScreen({
    super.key,
    this.editingSplitId,
    this.resumeDraft = false,
  });

  final String? editingSplitId;
  final bool resumeDraft;

  @override
  ConsumerState<SplitBuilderScreen> createState() => _SplitBuilderScreenState();
}

class _SplitBuilderScreenState extends ConsumerState<SplitBuilderScreen>
    with WidgetsBindingObserver {
  final TextEditingController _splitNameController = TextEditingController();
  final List<_DayDraft> _days = [_DayDraft()];
  final List<String> _selectedVolumeControlLabels = [
    ...defaultSplitVolumeControlLabels,
  ];
  final Set<String> _manuallyCreatedControlLabels = {};
  bool _setAsActive = true;
  bool _isSaving = false;
  bool _didSaveSplit = false;
  bool _didHydrateFromExisting = false;
  bool _didResumeFromDraft = false;
  bool _isInitializingDraft = true;
  String? _validationMessage;
  late AppClock _appClock;
  late SplitBuilderDraftStorage _splitBuilderDraftStorage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appClock = ref.read(appClockProvider);
    _splitBuilderDraftStorage = ref.read(splitBuilderDraftStorageProvider);
    _initializeDraftState();
  }

  @override
  void dispose() {
    if (!_didSaveSplit) {
      _saveDraftForResume(invalidateProvider: false);
    }
    WidgetsBinding.instance.removeObserver(this);
    _splitNameController.dispose();
    for (final day in _days) {
      day.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_didSaveSplit) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveDraftForResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEditing = widget.editingSplitId != null;
    final splitDetailsState = isEditing
        ? ref.watch(splitDetailsProvider(widget.editingSplitId!))
        : const AsyncValue<SplitDetails?>.data(null);

    return PopScope(
      canPop: !_isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_didSaveSplit) {
          _saveDraftForResume();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isEditing ? l10n.tr('Edit Split') : l10n.tr('Split Builder'),
          ),
          actions: [
            if (!isEditing)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  key: const Key('split_builder_erase_draft'),
                  onPressed: _isSaving ? null : _confirmEraseDraft,
                  tooltip: l10n.tr('Erase draft'),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
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
                    : Text(l10n.tr('Save')),
              ),
            ),
          ],
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: _isInitializingDraft
              ? const Center(child: CircularProgressIndicator())
              : splitDetailsState.when(
                  data: (details) {
                    if (isEditing) {
                      if (details == null) {
                        return _BuilderErrorState(
                          message: l10n.tr('Split not found.'),
                          onRetry: () {
                            ref.invalidate(
                              splitDetailsProvider(widget.editingSplitId!),
                            );
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
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _BuilderErrorState(
                    message: l10n.format(
                      'Failed to load split details: {error}',
                      {'error': error},
                    ),
                    onRetry: () {
                      if (widget.editingSplitId != null) {
                        ref.invalidate(
                          splitDetailsProvider(widget.editingSplitId!),
                        );
                      }
                    },
                  ),
                ),
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
            message: context.l10n.format('Failed to load exercises: {error}', {
              'error': error,
            }),
            onRetry: () => ref.invalidate(exercisesProvider),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _BuilderErrorState(
        message: context.l10n.format(
          'Failed to initialize exercise data: {error}',
          {'error': error},
        ),
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

  Future<void> _initializeDraftState() async {
    if (widget.editingSplitId != null || !widget.resumeDraft) {
      _isInitializingDraft = false;
      return;
    }

    final storedDraft = await _splitBuilderDraftStorage.loadDraft();
    if (!mounted) {
      return;
    }
    if (storedDraft != null) {
      _didResumeFromDraft = true;
      _hydrateFromDraft(storedDraft);
    }

    setState(() {
      _isInitializingDraft = false;
    });
  }

  void _hydrateFromDraft(SplitBuilderDraft draft) {
    _splitNameController.text = draft.splitName;
    _setAsActive = draft.setAsActive;

    _selectedVolumeControlLabels
      ..clear()
      ..addAll(
        normalizeSplitVolumeControlLabels(draft.selectedVolumeControlLabels),
      );
    if (_selectedVolumeControlLabels.isEmpty) {
      _selectedVolumeControlLabels.addAll(defaultSplitVolumeControlLabels);
    }

    _manuallyCreatedControlLabels
      ..clear()
      ..addAll(
        normalizeSplitVolumeControlLabels(draft.manuallyCreatedControlLabels),
      );

    for (final day in _days) {
      day.dispose();
    }
    _days.clear();
    for (final day in draft.days) {
      final plannedExercises = day.plannedExercises
          .map(
            (planned) => _PlannedExerciseDraft(
              selectedExerciseId: planned.selectedExerciseId,
              sets: planned.sets,
              repMin: planned.repMin,
              repMax: planned.repMax,
              rest: planned.rest,
              rpe: planned.rpe,
            ),
          )
          .toList();
      _days.add(
        _DayDraft(
          title: day.title,
          plannedExercises: plannedExercises.isEmpty
              ? <_PlannedExerciseDraft>[_PlannedExerciseDraft()]
              : plannedExercises,
        ),
      );
    }
    if (_days.isEmpty) {
      _days.add(_DayDraft());
    }
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
    final l10n = context.l10n;
    final volumeSummary = _buildMuscleVolumeSummary(exercises);
    final availableControlLabels = _buildAvailableControlLabels(exercises);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.tr(
            'Build a split with ordered training days and planned exercises.',
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('split_name_field'),
          controller: _splitNameController,
          decoration: InputDecoration(
            labelText: l10n.tr('Split name *'),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _clearValidation(),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          key: const Key('split_set_active_switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.tr('Set as active split')),
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
              onChanged: _handleBuilderInputChanged,
              onPickExercise: (selectedExerciseId) =>
                  _pickExerciseForBuilder(exercises, selectedExerciseId),
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
          label: Text(l10n.tr('Add Day')),
        ),
        if (exercises.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              l10n.tr(
                'No exercises available. Seed exercises before creating a split.',
              ),
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

  Future<ExerciseWithLabels?> _pickExerciseForBuilder(
    List<ExerciseWithLabels> exercises,
    String? selectedExerciseId,
  ) {
    return Navigator.of(context).push<ExerciseWithLabels>(
      MaterialPageRoute(
        builder: (context) => ExerciseSelectionScreen(
          exercises: exercises,
          selectedExerciseId: selectedExerciseId,
        ),
      ),
    );
  }

  void _saveDraftForResume({bool invalidateProvider = true}) {
    if (widget.editingSplitId != null) {
      return;
    }
    if (_isInitializingDraft) {
      return;
    }

    if (!_hasDraftableInput()) {
      if (!_didResumeFromDraft) {
        return;
      }
      if (invalidateProvider) {
        ref.invalidate(persistedSplitBuilderDraftProvider);
      }
      unawaited(_splitBuilderDraftStorage.clearDraft());
      return;
    }

    final draft = SplitBuilderDraft(
      splitName: _splitNameController.text.trim(),
      setAsActive: _setAsActive,
      selectedVolumeControlLabels: List<String>.from(
        _selectedVolumeControlLabels,
      ),
      manuallyCreatedControlLabels: List<String>.from(
        _manuallyCreatedControlLabels,
      ),
      updatedAtMs: _appClock().millisecondsSinceEpoch,
      days: _days
          .map(
            (day) => SplitBuilderDayDraft(
              title: day.titleController.text.trim(),
              plannedExercises: day.plannedExercises
                  .map(
                    (planned) => SplitBuilderPlannedExerciseDraft(
                      selectedExerciseId: planned.selectedExerciseId,
                      sets: planned.targetSetsController.text.trim(),
                      repMin: planned.repMinController.text.trim(),
                      repMax: planned.repMaxController.text.trim(),
                      rest: planned.restSecondsController.text.trim(),
                      rpe: planned.targetRpeController.text.trim(),
                    ),
                  )
                  .toList(growable: false),
            ),
          )
          .toList(growable: false),
    );
    if (invalidateProvider) {
      ref.invalidate(persistedSplitBuilderDraftProvider);
    }
    unawaited(_splitBuilderDraftStorage.saveDraft(draft));
  }

  bool _hasDraftableInput() {
    if (_splitNameController.text.trim().isNotEmpty) {
      return true;
    }
    if (!_setAsActive) {
      return true;
    }

    final normalizedSelectedLabels = normalizeSplitVolumeControlLabels(
      _selectedVolumeControlLabels,
    );
    final normalizedDefaults = normalizeSplitVolumeControlLabels(
      defaultSplitVolumeControlLabels,
    );
    if (!_unorderedListEquals(normalizedSelectedLabels, normalizedDefaults)) {
      return true;
    }
    if (_manuallyCreatedControlLabels.isNotEmpty) {
      return true;
    }

    if (_days.length > 1) {
      return true;
    }

    for (final day in _days) {
      if (day.titleController.text.trim().isNotEmpty) {
        return true;
      }
      if (day.plannedExercises.length > 1) {
        return true;
      }
      for (final planned in day.plannedExercises) {
        final selectedExerciseId = planned.selectedExerciseId;
        if (selectedExerciseId != null && selectedExerciseId.isNotEmpty) {
          return true;
        }
        if (planned.targetSetsController.text.trim() != '3' ||
            planned.repMinController.text.trim() != '8' ||
            planned.repMaxController.text.trim() != '12' ||
            planned.restSecondsController.text.trim().isNotEmpty ||
            planned.targetRpeController.text.trim().isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  bool _unorderedListEquals(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    final leftSorted = [...left]..sort();
    final rightSorted = [...right]..sort();
    for (var index = 0; index < leftSorted.length; index++) {
      if (leftSorted[index] != rightSorted[index]) {
        return false;
      }
    }
    return true;
  }

  Future<void> _confirmEraseDraft() async {
    final l10n = context.l10n;
    final shouldErase = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.tr('Erase split draft?')),
        content: Text(
          l10n.tr(
            'You are erasing the current split draft. Do you want to continue?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.tr('Erase')),
          ),
        ],
      ),
    );
    if (shouldErase != true) {
      return;
    }
    await _eraseDraft();
  }

  Future<void> _eraseDraft() async {
    _splitNameController.clear();
    _setAsActive = true;
    _selectedVolumeControlLabels
      ..clear()
      ..addAll(defaultSplitVolumeControlLabels);
    _manuallyCreatedControlLabels.clear();
    _validationMessage = null;
    _didResumeFromDraft = false;

    for (final day in _days) {
      day.dispose();
    }
    _days
      ..clear()
      ..add(_DayDraft());

    setState(() {});
    ref.invalidate(persistedSplitBuilderDraftProvider);
    await _splitBuilderDraftStorage.clearDraft();

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.tr('Split draft erased.'))),
    );
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
      _didSaveSplit = true;
      ref.invalidate(persistedSplitBuilderDraftProvider);
      await _splitBuilderDraftStorage.clearDraft();

      if (!mounted) {
        return;
      }
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _setAsActive
                ? (isEditing
                      ? l10n.tr('Saved split changes and set it active.')
                      : l10n.tr('Saved split and set it active.'))
                : (isEditing
                      ? l10n.tr('Saved split changes.')
                      : l10n.tr('Saved split successfully.')),
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
            context.l10n.format('Could not save split: {error}', {
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

  SplitDraftInput? _parseInput() {
    final l10n = context.l10n;
    final splitName = _splitNameController.text.trim();
    if (splitName.isEmpty) {
      _showValidation(l10n.tr('Split name is required.'));
      return null;
    }
    if (_days.isEmpty) {
      _showValidation(l10n.tr('At least one day is required.'));
      return null;
    }

    final parsedDays = <DayPlanDraftInput>[];

    for (var dayIndex = 0; dayIndex < _days.length; dayIndex++) {
      final day = _days[dayIndex];
      final dayNumber = dayIndex + 1;
      final dayTitle = day.titleController.text.trim();
      if (dayTitle.isEmpty) {
        _showValidation(
          l10n.format('Day {day} title is required.', {'day': dayNumber}),
        );
        return null;
      }
      if (day.plannedExercises.isEmpty) {
        _showValidation(
          l10n.format('Day {day} must include at least one exercise.', {
            'day': dayNumber,
          }),
        );
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
            l10n.format('Day {day}, exercise {exercise}: choose an exercise.', {
              'day': dayNumber,
              'exercise': exerciseNumber,
            }),
          );
          return null;
        }

        final sets = int.tryParse(
          exerciseDraft.targetSetsController.text.trim(),
        );
        if (sets == null || sets <= 0) {
          _showValidation(
            l10n.format(
              'Day {day}, exercise {exercise}: sets must be a positive integer.',
              {'day': dayNumber, 'exercise': exerciseNumber},
            ),
          );
          return null;
        }

        final repMin = int.tryParse(exerciseDraft.repMinController.text.trim());
        final repMax = int.tryParse(exerciseDraft.repMaxController.text.trim());
        if (repMin == null || repMin <= 0) {
          _showValidation(
            l10n.format(
              'Day {day}, exercise {exercise}: minimum reps must be positive.',
              {'day': dayNumber, 'exercise': exerciseNumber},
            ),
          );
          return null;
        }
        if (repMax == null || repMax < repMin) {
          _showValidation(
            l10n.format(
              'Day {day}, exercise {exercise}: maximum reps must be >= minimum reps.',
              {'day': dayNumber, 'exercise': exerciseNumber},
            ),
          );
          return null;
        }

        final restText = exerciseDraft.restSecondsController.text.trim();
        final restSeconds = restText.isEmpty ? null : int.tryParse(restText);
        if (restText.isNotEmpty && (restSeconds == null || restSeconds < 0)) {
          _showValidation(
            l10n.format(
              'Day {day}, exercise {exercise}: rest must be a non-negative integer.',
              {'day': dayNumber, 'exercise': exerciseNumber},
            ),
          );
          return null;
        }

        final rpeText = exerciseDraft.targetRpeController.text.trim();
        final targetRpe = rpeText.isEmpty ? null : double.tryParse(rpeText);
        if (rpeText.isNotEmpty &&
            (targetRpe == null || targetRpe < 0 || targetRpe > 10)) {
          _showValidation(
            l10n.format(
              'Day {day}, exercise {exercise}: target RPE must be between 0 and 10.',
              {'day': dayNumber, 'exercise': exerciseNumber},
            ),
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

  void _handleBuilderInputChanged() {
    setState(() {
      _validationMessage = null;
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
    required this.onPickExercise,
    required this.onAddExercise,
    required this.onRemoveExercise,
    this.onRemoveDay,
  });

  final int dayNumber;
  final _DayDraft dayDraft;
  final List<ExerciseWithLabels> exercises;
  final VoidCallback onChanged;
  final Future<ExerciseWithLabels?> Function(String? selectedExerciseId)
  onPickExercise;
  final VoidCallback onAddExercise;
  final ValueChanged<int> onRemoveExercise;
  final VoidCallback? onRemoveDay;

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
                  l10n.format('Day {day}', {'day': dayNumber}),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (onRemoveDay != null)
                  IconButton(
                    onPressed: onRemoveDay,
                    tooltip: l10n.tr('Remove day'),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: Key('day_${dayNumber}_title'),
              controller: dayDraft.titleController,
              decoration: InputDecoration(
                labelText: l10n.tr('Day title *'),
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
                  onPickExercise: onPickExercise,
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
              label: Text(l10n.tr('Add Exercise')),
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
    required this.onPickExercise,
    this.onRemove,
  });

  final int dayNumber;
  final int exerciseNumber;
  final _PlannedExerciseDraft draft;
  final List<ExerciseWithLabels> exercises;
  final VoidCallback onChanged;
  final Future<ExerciseWithLabels?> Function(String? selectedExerciseId)
  onPickExercise;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ExerciseWithLabels? selectedExercise;
    final selectedId = draft.selectedExerciseId;
    if (selectedId != null && selectedId.isNotEmpty) {
      for (final exercise in exercises) {
        if (exercise.id == selectedId) {
          selectedExercise = exercise;
          break;
        }
      }
    }
    final selectedName = selectedExercise == null
        ? null
        : l10n.localizeExerciseName(selectedExercise.name);
    final selectedLabels = selectedExercise?.labels ?? const <String>[];
    final canSelectExercise = exercises.isNotEmpty;
    final pickerPlaceholder = canSelectExercise
        ? l10n.tr('Choose exercise')
        : l10n.tr('No exercises available');

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
                  l10n.format('Exercise {number}', {'number': exerciseNumber}),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    tooltip: l10n.tr('Remove exercise'),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            InkWell(
              key: Key('day_${dayNumber}_exercise_$exerciseNumber'),
              onTap: !canSelectExercise
                  ? null
                  : () async {
                      final selected = await onPickExercise(
                        draft.selectedExerciseId,
                      );
                      if (selected == null) {
                        return;
                      }
                      draft
                        ..selectedExerciseId = selected.id
                        ..areLabelsExpanded = false;
                      onChanged();
                    },
              borderRadius: BorderRadius.circular(6),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.tr('Exercise *'),
                  border: OutlineInputBorder(),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                isEmpty: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedName ?? pickerPlaceholder,
                            style: selectedName == null
                                ? TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                    if (canSelectExercise)
                      const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ),
            if (selectedLabels.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    l10n.tr('Labels'),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    key: Key(
                      'day_${dayNumber}_exercise_${exerciseNumber}_labels_toggle',
                    ),
                    tooltip: draft.areLabelsExpanded
                        ? l10n.tr('Hide labels')
                        : l10n.tr('Show labels'),
                    onPressed: () {
                      draft.areLabelsExpanded = !draft.areLabelsExpanded;
                      onChanged();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      draft.areLabelsExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 18,
                    ),
                  ),
                ],
              ),
              if (draft.areLabelsExpanded) ...[
                const SizedBox(height: 2),
                Wrap(
                  key: Key(
                    'day_${dayNumber}_exercise_${exerciseNumber}_labels_wrap',
                  ),
                  spacing: 6,
                  runSpacing: 6,
                  children: selectedLabels
                      .map(
                        (label) => _ExerciseLabelTag(
                          label: l10n.localizeLabelName(label),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 12),
              ] else ...[
                const SizedBox(height: 8),
              ],
            ] else ...[
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: _NumericField(
                    fieldKey: Key(
                      'day_${dayNumber}_exercise_${exerciseNumber}_sets',
                    ),
                    controller: draft.targetSetsController,
                    label: l10n.tr('Sets *'),
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
                    label: l10n.tr('Rep min *'),
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
                    label: l10n.tr('Rep max *'),
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
                    label: l10n.tr('Rest sec'),
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
                    label: l10n.tr('Target RPE'),
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

class _ExerciseLabelTag extends StatelessWidget {
  const _ExerciseLabelTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium),
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
  bool areLabelsExpanded = false;
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
