import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/app_database.dart';
import '../../core/models/exercise_with_labels.dart';
import '../../core/models/logged_set_input.dart';
import '../../core/state/providers.dart';
import '../../core/time/app_clock.dart';
import '../splits/split_repository.dart';
import 'quick_workout_repository.dart';
import 'workout_draft.dart';
import 'workout_draft_storage.dart';

class WorkoutLoggerScreen extends ConsumerStatefulWidget {
  const WorkoutLoggerScreen({
    required this.mode,
    super.key,
    this.splitId,
    this.dayIndex,
    this.openPickerOnStart = false,
  });

  final String mode;
  final String? splitId;
  final int? dayIndex;
  final bool openPickerOnStart;

  @override
  ConsumerState<WorkoutLoggerScreen> createState() =>
      _WorkoutLoggerScreenState();
}

class _WorkoutLoggerScreenState extends ConsumerState<WorkoutLoggerScreen>
    with WidgetsBindingObserver {
  late DateTime _startedAt;
  final List<_WorkoutExerciseState> _exercises = [];
  bool _didHydrateSplitDay = false;
  bool _isSaving = false;
  bool _didSaveSession = false;
  bool _isOpeningPicker = false;
  int? _restSecondsRemaining;
  int _lastRestSeconds = 90;
  Timer? _restTimer;
  bool _isInitializingDraft = true;
  late AppClock _appClock;
  late WorkoutDraftStorage _workoutDraftStorage;
  late WorkoutDraftNotifier _workoutDraftNotifier;
  WorkoutDraft? _inMemoryDraft;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appClock = ref.read(appClockProvider);
    _workoutDraftStorage = ref.read(workoutDraftStorageProvider);
    _workoutDraftNotifier = ref.read(workoutDraftProvider.notifier);
    _inMemoryDraft = ref.read(workoutDraftProvider);
    _startedAt = _appClock();
    _initializeDraftState();
  }

  @override
  void dispose() {
    if (!_didSaveSession) {
      _saveDraftForResume();
    }
    WidgetsBinding.instance.removeObserver(this);
    _restTimer?.cancel();
    for (final exercise in _exercises) {
      exercise.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_didSaveSession) {
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
    if (_isInitializingDraft) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (widget.mode != WorkoutSessionMode.splitDay &&
        widget.mode != WorkoutSessionMode.free) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: Center(child: Text('Unsupported workout mode: ${widget.mode}')),
      );
    }

    if (widget.mode == WorkoutSessionMode.splitDay) {
      final splitId = widget.splitId;
      final dayIndex = widget.dayIndex;
      if (splitId == null || dayIndex == null || dayIndex <= 0) {
        return Scaffold(
          appBar: AppBar(title: const Text('Workout')),
          body: const Center(child: Text('Missing split workout parameters.')),
        );
      }

      final detailsState = ref.watch(splitDetailsProvider(splitId));
      final exercisesState = ref.watch(exercisesProvider);
      return detailsState.when(
        data: (details) {
          if (details == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Workout')),
              body: const Center(child: Text('Split not found.')),
            );
          }
          final day = details.days
              .where((value) => value.dayIndex == dayIndex)
              .firstOrNull;
          if (day == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Workout')),
              body: const Center(child: Text('Workout day not found.')),
            );
          }

          final exerciseMap = exercisesState.maybeWhen(
            data: (items) => {
              for (final exercise in items) exercise.id: exercise,
            },
            orElse: () => const <String, ExerciseWithLabels>{},
          );
          _hydrateSplitDayIfNeeded(details, day, exerciseMap);
          return _buildScaffold(
            title: day.title,
            subtitle: details.name,
            splitDetails: details,
          );
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Workout')),
          body: Center(child: Text('Failed to load split workout: $error')),
        ),
      );
    }

    return _buildScaffold(
      title: 'Free workout',
      subtitle: 'Build as you go',
      splitDetails: null,
    );
  }

  void _hydrateSplitDayIfNeeded(
    SplitDetails split,
    DayPlanDetails day,
    Map<String, ExerciseWithLabels> exerciseMap,
  ) {
    if (_didHydrateSplitDay) {
      return;
    }

    final matchingDraft = _matchingDraftOrNull();
    if (matchingDraft != null && matchingDraft.exercises.isNotEmpty) {
      _didHydrateSplitDay = true;
      _hydrateFromDraft(matchingDraft);
      return;
    }

    _didHydrateSplitDay = true;
    for (final planned in day.plannedExercises) {
      final exercise = exerciseMap[planned.exerciseId];
      final labelNames = exercise?.labels ?? const <String>[];
      _exercises.add(
        _WorkoutExerciseState(
          exerciseId: planned.exerciseId,
          exerciseName: planned.exerciseName,
          labels: labelNames,
          repMin: planned.repMin,
          repMax: planned.repMax,
          targetSets: planned.targetSets,
          restSeconds: planned.restSeconds,
          targetRpe: planned.targetRpe,
        )..ensureInitialRows(planned.targetSets),
      );
    }
  }

  WorkoutDraft? _matchingDraftOrNull() {
    final draft = _inMemoryDraft;
    final now = _appClock();
    if (draft == null || !draft.isForToday(now)) {
      return null;
    }
    if (draft.mode != widget.mode) {
      return null;
    }
    if (widget.mode == WorkoutSessionMode.splitDay) {
      if (draft.splitId != widget.splitId ||
          draft.dayIndex != widget.dayIndex) {
        return null;
      }
    }
    return draft;
  }

  Future<void> _initializeDraftState() async {
    final storedDraft = await _workoutDraftStorage.loadDraft();
    if (!mounted) {
      return;
    }
    if (storedDraft != null) {
      _setInMemoryDraft(storedDraft);
      ref.invalidate(persistedWorkoutDraftProvider);
    }

    final matchingDraft = _matchingDraftOrNull();
    if (matchingDraft != null &&
        widget.mode == WorkoutSessionMode.free &&
        matchingDraft.exercises.isNotEmpty) {
      _hydrateFromDraft(matchingDraft);
      _startedAt = DateTime.fromMillisecondsSinceEpoch(
        matchingDraft.startedAtMs,
      );
    } else if (matchingDraft != null) {
      _startedAt = DateTime.fromMillisecondsSinceEpoch(
        matchingDraft.startedAtMs,
      );
    }

    if (widget.mode == WorkoutSessionMode.free &&
        widget.openPickerOnStart &&
        _exercises.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAddExercise();
      });
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _isInitializingDraft = false;
    });
  }

  void _hydrateFromDraft(WorkoutDraft draft) {
    if (_exercises.isNotEmpty) {
      for (final exercise in _exercises) {
        exercise.dispose();
      }
      _exercises.clear();
    }

    for (final exercise in draft.exercises) {
      final restoredExercise = _WorkoutExerciseState(
        exerciseId: exercise.exerciseId,
        exerciseName: exercise.exerciseName,
        labels: List<String>.from(exercise.labels),
        repMin: exercise.repMin,
        repMax: exercise.repMax,
        targetSets: exercise.targetSets,
        restSeconds: exercise.restSeconds,
        targetRpe: exercise.targetRpe,
      );
      if (exercise.rows.isEmpty) {
        restoredExercise.ensureInitialRows(exercise.targetSets);
      } else {
        for (final row in exercise.rows) {
          restoredExercise.rows.add(
            _WorkoutSetState(
              weightText: row.weightText,
              repsText: row.repsText,
              rpeText: row.rpeText,
              restSeconds: row.restSeconds,
            ),
          );
        }
      }
      _exercises.add(restoredExercise);
    }
  }

  Widget _buildScaffold({
    required String title,
    required String subtitle,
    required SplitDetails? splitDetails,
  }) {
    return PopScope(
      canPop: !_isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_didSaveSession) {
          _saveDraftForResume();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(24),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          actions: [
            if (_restSecondsRemaining != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Chip(
                  label: Text(
                    'Rest ${_formatRestTime(_restSecondsRemaining!)}',
                  ),
                ),
              ),
            if (widget.mode == WorkoutSessionMode.splitDay)
              IconButton(
                key: const Key('workout_logger_delete_log'),
                tooltip: 'Delete current log',
                onPressed: _isSaving ? null : _deleteCurrentLog,
                icon: const Icon(Icons.delete_outline),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _isSaving ? null : () => _onFinish(splitDetails),
                child: _isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Finish'),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.mode == WorkoutSessionMode.free) ...[
              Row(
                children: [
                  FilledButton.icon(
                    key: const Key('workout_logger_add_exercise'),
                    onPressed: _handleAddExercise,
                    icon: const Icon(Icons.add),
                    label: const Text('Add exercise'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (_exercises.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    widget.mode == WorkoutSessionMode.free
                        ? 'No exercises yet. Add one to start logging sets.'
                        : 'No planned exercises for this day.',
                  ),
                ),
              ),
            ...List.generate(
              _exercises.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ExerciseCard(
                  key: Key('workout_exercise_card_$index'),
                  exercise: _exercises[index],
                  onSwap: widget.mode == WorkoutSessionMode.splitDay
                      ? () => _handleSwapExercise(index)
                      : null,
                  onRemove: widget.mode == WorkoutSessionMode.free
                      ? () => _removeExercise(index)
                      : null,
                  onEditPrescription: () => _editPrescription(index),
                  onCopyPreviousSet: (rowIndex) =>
                      _copyPreviousSet(index, rowIndex),
                  onAddSet: () => _addSet(index),
                  onDeleteSet: () => _deleteLastSet(index),
                  onStartRestTimer: () => _startRestTimerForExercise(index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddExercise() async {
    if (_isOpeningPicker) {
      return;
    }
    _isOpeningPicker = true;
    final selected = await _openExercisePicker();
    _isOpeningPicker = false;
    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _exercises.add(
        _WorkoutExerciseState(
          exerciseId: selected.id,
          exerciseName: selected.name,
          labels: selected.labels,
          repMin: 8,
          repMax: 12,
          targetSets: 1,
          restSeconds: null,
          targetRpe: null,
        )..ensureInitialRows(1),
      );
    });
  }

  Future<void> _handleSwapExercise(int exerciseIndex) async {
    final selected = await _openExercisePicker();
    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _exercises[exerciseIndex]
        ..exerciseId = selected.id
        ..exerciseName = selected.name
        ..labels = selected.labels;
    });
  }

  Future<ExerciseWithLabels?> _openExercisePicker() {
    return showModalBottomSheet<ExerciseWithLabels>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const FractionallySizedBox(
        heightFactor: 0.92,
        child: _ExercisePickerSheet(),
      ),
    );
  }

  void _removeExercise(int exerciseIndex) {
    final removed = _exercises.removeAt(exerciseIndex);
    removed.dispose();
    setState(() {});
  }

  Future<void> _editPrescription(int exerciseIndex) async {
    final exercise = _exercises[exerciseIndex];
    final setsController = TextEditingController(
      text: '${exercise.targetSets}',
    );
    final repMinController = TextEditingController(text: '${exercise.repMin}');
    final repMaxController = TextEditingController(text: '${exercise.repMax}');
    final restController = TextEditingController(
      text: exercise.restSeconds?.toString() ?? '',
    );
    final rpeController = TextEditingController(
      text: exercise.targetRpe?.toString() ?? '',
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${exercise.exerciseName}'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _NumericField(
                controller: setsController,
                label: 'Target sets',
                decimal: false,
              ),
              const SizedBox(height: 8),
              _NumericField(
                controller: repMinController,
                label: 'Rep min',
                decimal: false,
              ),
              const SizedBox(height: 8),
              _NumericField(
                controller: repMaxController,
                label: 'Rep max',
                decimal: false,
              ),
              const SizedBox(height: 8),
              _NumericField(
                controller: restController,
                label: 'Rest sec',
                decimal: false,
              ),
              const SizedBox(height: 8),
              _NumericField(
                controller: rpeController,
                label: 'Target RPE',
                decimal: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave != true) {
      setsController.dispose();
      repMinController.dispose();
      repMaxController.dispose();
      restController.dispose();
      rpeController.dispose();
      return;
    }

    final targetSets = int.tryParse(setsController.text.trim());
    final repMin = int.tryParse(repMinController.text.trim());
    final repMax = int.tryParse(repMaxController.text.trim());
    final rest = restController.text.trim().isEmpty
        ? null
        : int.tryParse(restController.text.trim());
    final rpe = rpeController.text.trim().isEmpty
        ? null
        : double.tryParse(rpeController.text.trim());

    setsController.dispose();
    repMinController.dispose();
    repMaxController.dispose();
    restController.dispose();
    rpeController.dispose();

    if (targetSets == null || targetSets <= 0) {
      _showMessage('Target sets must be greater than zero.');
      return;
    }
    if (repMin == null || repMin <= 0) {
      _showMessage('Rep min must be greater than zero.');
      return;
    }
    if (repMax == null || repMax < repMin) {
      _showMessage('Rep max cannot be lower than rep min.');
      return;
    }
    if (rest != null && rest < 0) {
      _showMessage('Rest cannot be negative.');
      return;
    }
    if (rpe != null && (rpe < 0 || rpe > 10)) {
      _showMessage('Target RPE must be between 0 and 10.');
      return;
    }

    setState(() {
      exercise
        ..targetSets = targetSets
        ..repMin = repMin
        ..repMax = repMax
        ..restSeconds = rest
        ..targetRpe = rpe;
      exercise.ensureInitialRows(targetSets);
    });
  }

  void _copyPreviousSet(int exerciseIndex, int rowIndex) {
    if (rowIndex <= 0) {
      return;
    }
    final exercise = _exercises[exerciseIndex];
    final row = exercise.rows[rowIndex];
    final previous = exercise.rows[rowIndex - 1];
    setState(() {
      row.weightController.text = previous.weightController.text;
      row.repsController.text = previous.repsController.text;
      row.rpeController.text = previous.rpeController.text;
    });
  }

  void _addSet(int exerciseIndex) {
    final exercise = _exercises[exerciseIndex];
    final previous = exercise.rows.isEmpty ? null : exercise.rows.last;
    final next = _WorkoutSetState(
      weightText: previous?.weightController.text,
      repsText: previous?.repsController.text,
      rpeText: previous?.rpeController.text,
    );
    setState(() {
      exercise.rows.add(next);
    });
  }

  Future<void> _deleteLastSet(int exerciseIndex) async {
    final exercise = _exercises[exerciseIndex];
    if (exercise.rows.length <= 1) {
      _showMessage('At least one set is required.');
      return;
    }

    final lastRow = exercise.rows.last;
    if (lastRow.hasAnyInput) {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete last set?'),
          content: const Text(
            'The last set is already logged. Do you really want to delete it?',
          ),
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
      if (shouldDelete != true) {
        return;
      }
    }

    final removed = exercise.rows.removeLast();
    removed.dispose();
    setState(() {});
  }

  void _startRestTimerForExercise(int exerciseIndex) {
    final exercise = _exercises[exerciseIndex];
    final configuredRest = exercise.restSeconds;
    final restSeconds = configuredRest == null || configuredRest <= 0
        ? _lastRestSeconds
        : configuredRest;
    final normalized = restSeconds <= 0 ? 90 : restSeconds;
    _lastRestSeconds = normalized;
    _startRestTimer(normalized);
  }

  void _startRestTimer(int seconds) {
    if (seconds <= 0) {
      return;
    }

    _restTimer?.cancel();
    setState(() => _restSecondsRemaining = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = _restSecondsRemaining ?? 0;
      if (remaining <= 1) {
        timer.cancel();
        setState(() => _restSecondsRemaining = null);
      } else {
        setState(() => _restSecondsRemaining = remaining - 1);
      }
    });
  }

  Future<void> _onFinish(SplitDetails? splitDetails) async {
    final sessionData = _buildSessionPayload();
    if (sessionData == null) {
      return;
    }

    final shouldSave = await _showFinishSheet(sessionData);
    if (shouldSave != true) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final splitId = widget.mode == WorkoutSessionMode.splitDay
          ? splitDetails?.id
          : null;
      final dayIndex = widget.mode == WorkoutSessionMode.splitDay
          ? widget.dayIndex
          : null;
      final sessionName = widget.mode == WorkoutSessionMode.splitDay
          ? splitDetails?.days
                .where((day) => day.dayIndex == widget.dayIndex)
                .firstOrNull
                ?.title
          : 'Free workout';

      await ref
          .read(quickWorkoutRepositoryProvider)
          .saveWorkoutSession(
            mode: widget.mode,
            startedAt: _startedAt,
            endedAt: ref.read(appClockProvider)(),
            splitId: splitId,
            dayIndex: dayIndex,
            sessionName: sessionName,
            exercises: sessionData.logs,
          );

      _didSaveSession = true;
      _clearInMemoryDraft();
      ref.invalidate(persistedWorkoutDraftProvider);
      await _workoutDraftStorage.clearDraft();

      ref.invalidate(recentHomeSessionsProvider);
      ref.invalidate(lastHomeSessionProvider);
      ref.invalidate(lastSplitDaySessionProvider);
      ref.invalidate(suggestedWorkoutCardStateProvider);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Workout saved.')));
      context.go('/home');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Could not save workout: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  _SessionPayload? _buildSessionPayload() {
    final logs = <WorkoutExerciseLogInput>[];
    var totalSets = 0;
    var unfilledSets = 0;

    for (final exercise in _exercises) {
      final loggedSets = <LoggedSetInput>[];
      for (final row in exercise.rows) {
        if (!row.hasAnyInput) {
          unfilledSets += 1;
          continue;
        }

        if (!row.isLoggedSet) {
          unfilledSets += 1;
          continue;
        }

        final reps = row.repsValue!;
        final weight = row.weightValue!;
        final rpe = row.rpeValue;
        loggedSets.add(
          LoggedSetInput(
            reps: reps,
            weightKg: weight,
            restSeconds: row.restSeconds ?? exercise.restSeconds,
            rpe: rpe,
          ),
        );
        totalSets += 1;
      }

      if (loggedSets.isNotEmpty) {
        logs.add(
          WorkoutExerciseLogInput(
            exerciseId: exercise.exerciseId,
            sets: loggedSets,
          ),
        );
      }
    }

    if (logs.isEmpty || totalSets == 0) {
      _showMessage('Log at least one complete set before finishing.');
      return null;
    }
    return _SessionPayload(
      logs: logs,
      totalSets: totalSets,
      unfilledSetCount: unfilledSets,
    );
  }

  Future<bool?> _showFinishSheet(_SessionPayload sessionData) {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Finish workout',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text('${sessionData.logs.length} exercises'),
              Text('${sessionData.totalSets} total sets'),
              if (sessionData.unfilledSetCount > 0) ...[
                const SizedBox(height: 10),
                Text(
                  '${sessionData.unfilledSetCount} unfilled sets will not be counted. Save anyway?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRestTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteCurrentLog() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete current log?'),
        content: const Text(
          'This will clear your in-progress workout. You can start again from Home.',
        ),
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
    if (shouldDelete != true) {
      return;
    }

    _clearInMemoryDraft();
    ref.invalidate(persistedWorkoutDraftProvider);
    await _workoutDraftStorage.clearDraft();

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('In-progress log deleted.')));
    context.go('/home');
  }

  void _saveDraftForResume() {
    final hasAnySetInput = _exercises.any(
      (exercise) => exercise.rows.any((row) => row.hasAnyInput),
    );
    final hasFreeExerciseSelection =
        widget.mode == WorkoutSessionMode.free && _exercises.isNotEmpty;
    if (!hasAnySetInput && !hasFreeExerciseSelection) {
      final existingDraft = _inMemoryDraft;
      final matchesCurrent =
          existingDraft?.matchesLoggerContext(
            mode: widget.mode,
            splitId: widget.splitId,
            dayIndex: widget.dayIndex,
          ) ??
          false;
      if (matchesCurrent) {
        _clearInMemoryDraft();
        unawaited(_workoutDraftStorage.clearDraft());
      }
      return;
    }

    final draft = WorkoutDraft(
      mode: widget.mode,
      splitId: widget.mode == WorkoutSessionMode.splitDay
          ? widget.splitId
          : null,
      dayIndex: widget.mode == WorkoutSessionMode.splitDay
          ? widget.dayIndex
          : null,
      startedAtMs: _startedAt.millisecondsSinceEpoch,
      updatedAtMs: _appClock().millisecondsSinceEpoch,
      exercises: _exercises
          .map(
            (exercise) => WorkoutDraftExercise(
              exerciseId: exercise.exerciseId,
              exerciseName: exercise.exerciseName,
              labels: List<String>.from(exercise.labels),
              repMin: exercise.repMin,
              repMax: exercise.repMax,
              targetSets: exercise.targetSets,
              restSeconds: exercise.restSeconds,
              targetRpe: exercise.targetRpe,
              rows: exercise.rows
                  .map(
                    (row) => WorkoutDraftSetRow(
                      weightText: row.weightController.text.trim(),
                      repsText: row.repsController.text.trim(),
                      rpeText: row.rpeController.text.trim(),
                      restSeconds: row.restSeconds,
                    ),
                  )
                  .toList(growable: false),
            ),
          )
          .toList(growable: false),
    );
    _setInMemoryDraft(draft);
    unawaited(_workoutDraftStorage.saveDraft(draft));
  }

  void _setInMemoryDraft(WorkoutDraft draft) {
    _inMemoryDraft = draft;
    _workoutDraftNotifier.setDraft(draft);
  }

  void _clearInMemoryDraft() {
    _inMemoryDraft = null;
    _workoutDraftNotifier.clearDraft();
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.onEditPrescription,
    required this.onCopyPreviousSet,
    required this.onAddSet,
    required this.onDeleteSet,
    required this.onStartRestTimer,
    this.onSwap,
    this.onRemove,
    super.key,
  });

  final _WorkoutExerciseState exercise;
  final VoidCallback? onSwap;
  final VoidCallback? onRemove;
  final VoidCallback onEditPrescription;
  final void Function(int rowIndex) onCopyPreviousSet;
  final VoidCallback onAddSet;
  final VoidCallback onDeleteSet;
  final VoidCallback onStartRestTimer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = ExerciseHistoryLookup(exerciseIds: [exercise.exerciseId]);
    final lastSetState = ref.watch(lastSetByLookupProvider(lookup));
    final bestSetState = ref.watch(bestSetByLookupProvider(lookup));
    final showProgressHint = _shouldShowProgressHint(exercise);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.exerciseName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (onSwap != null)
                  IconButton(
                    tooltip: 'Swap exercise',
                    onPressed: onSwap,
                    icon: const Icon(Icons.swap_horiz),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEditPrescription();
                    } else if (value == 'remove') {
                      onRemove?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit prescription'),
                    ),
                    if (onRemove != null)
                      const PopupMenuItem<String>(
                        value: 'remove',
                        child: Text('Remove exercise'),
                      ),
                  ],
                ),
              ],
            ),
            if (exercise.labels.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: exercise.labels
                    .take(4)
                    .map((label) => Chip(label: Text(label)))
                    .toList(growable: false),
              ),
            const SizedBox(height: 8),
            Text(
              '${exercise.targetSets} sets • ${exercise.repMin}-${exercise.repMax} reps'
              '${exercise.restSeconds == null ? '' : ' • ${exercise.restSeconds}s rest'}'
              '${exercise.targetRpe == null ? '' : ' • RPE ${exercise.targetRpe}'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            _HistoryStrip(
              lastSetState: lastSetState,
              bestSetState: bestSetState,
            ),
            const SizedBox(height: 8),
            ...List.generate(
              exercise.rows.length,
              (rowIndex) => _SetRow(
                setNumber: rowIndex + 1,
                row: exercise.rows[rowIndex],
                repMin: exercise.repMin,
                onCopyPrevious: rowIndex > 0
                    ? () => onCopyPreviousSet(rowIndex)
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddSet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add set'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDeleteSet,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete set'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onStartRestTimer,
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Start rest timer'),
            ),
            if (showProgressHint)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Next time +2.5 kg',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowProgressHint(_WorkoutExerciseState exercise) {
    final loggedRows = exercise.rows.where((row) => row.isLoggedSet).toList();
    if (loggedRows.isEmpty) {
      return false;
    }

    for (final row in loggedRows) {
      final reps = row.repsValue;
      if (reps == null || reps < exercise.repMax) {
        return false;
      }
    }
    return true;
  }
}

class _HistoryStrip extends StatelessWidget {
  const _HistoryStrip({required this.lastSetState, required this.bestSetState});

  final AsyncValue<PerformedSet?> lastSetState;
  final AsyncValue<PerformedSet?> bestSetState;

  @override
  Widget build(BuildContext context) {
    final lastText = lastSetState.maybeWhen(
      data: (value) => value == null
          ? 'Last: -'
          : 'Last: ${value.weightKg.toStringAsFixed(1)} x ${value.reps}',
      orElse: () => 'Last: -',
    );
    final bestText = bestSetState.maybeWhen(
      data: (value) => value == null
          ? 'Best (all-time): -'
          : 'Best (all-time): ${value.weightKg.toStringAsFixed(1)} x ${value.reps}',
      orElse: () => 'Best (all-time): -',
    );
    final suggested = lastSetState.maybeWhen(
      data: (value) => value == null
          ? 'Suggested load: -'
          : 'Suggested load: ${value.weightKg}',
      orElse: () => 'Suggested load: -',
    );

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(suggested), Text(lastText), Text(bestText)],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.setNumber,
    required this.row,
    required this.repMin,
    this.onCopyPrevious,
  });

  final int setNumber;
  final _WorkoutSetState row;
  final int repMin;
  final VoidCallback? onCopyPrevious;

  @override
  Widget build(BuildContext context) {
    final reps = row.repsValue;
    final belowRangeHint = row.isLoggedSet && reps != null && reps < repMin;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '$setNumber',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Expanded(
                child: _NumericField(
                  controller: row.weightController,
                  label: 'Weight',
                  decimal: true,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _NumericField(
                  controller: row.repsController,
                  label: 'Reps',
                  decimal: false,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _NumericField(
                  controller: row.rpeController,
                  label: 'RPE',
                  decimal: true,
                ),
              ),
              if (onCopyPrevious != null)
                IconButton(
                  tooltip: 'Copy previous set',
                  onPressed: onCopyPrevious,
                  icon: const Icon(Icons.content_copy_outlined),
                ),
            ],
          ),
          if (belowRangeHint)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Text(
                'Below target range - consider -2.5 kg or more rest.',
                style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
              ),
            ),
        ],
      ),
    );
  }
}

class _NumericField extends StatelessWidget {
  const _NumericField({
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
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        isDense: true,
      ),
    );
  }
}

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  const _ExercisePickerSheet();

  @override
  ConsumerState<_ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedLabel;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesState = ref.watch(exercisesProvider);
    final labelsState = ref.watch(allLabelsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add exercise', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Search exercise',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
          const SizedBox(height: 8),
          labelsState.when(
            data: (labels) {
              return DropdownButtonFormField<String?>(
                initialValue: _selectedLabel,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Filter by label',
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All labels'),
                  ),
                  ...labels.map(
                    (label) => DropdownMenuItem<String?>(
                      value: label,
                      child: Text(label),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedLabel = value),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: exercisesState.when(
              data: (exercises) {
                final filtered = exercises
                    .where((exercise) {
                      if (exercise.isHidden) {
                        return false;
                      }
                      if (_query.isNotEmpty &&
                          !exercise.name.toLowerCase().contains(_query)) {
                        return false;
                      }
                      if (_selectedLabel != null &&
                          !exercise.labels.contains(_selectedLabel)) {
                        return false;
                      }
                      return true;
                    })
                    .toList(growable: false);

                if (filtered.isEmpty) {
                  return const Center(child: Text('No exercises found.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final exercise = filtered[index];
                    return ListTile(
                      title: Text(exercise.name),
                      subtitle: Text(exercise.labels.take(3).join(', ')),
                      onTap: () => Navigator.of(context).pop(exercise),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Failed to load exercises: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutExerciseState {
  _WorkoutExerciseState({
    required this.exerciseId,
    required this.exerciseName,
    required this.labels,
    required this.repMin,
    required this.repMax,
    required this.targetSets,
    required this.restSeconds,
    required this.targetRpe,
  });

  String exerciseId;
  String exerciseName;
  List<String> labels;
  int repMin;
  int repMax;
  int targetSets;
  int? restSeconds;
  double? targetRpe;
  final List<_WorkoutSetState> rows = [];

  void ensureInitialRows(int minimumRows) {
    final desiredCount = minimumRows < 1 ? 1 : minimumRows;
    while (rows.length < desiredCount) {
      rows.add(_WorkoutSetState());
    }
  }

  void dispose() {
    for (final row in rows) {
      row.dispose();
    }
  }
}

class _WorkoutSetState {
  _WorkoutSetState({
    String? weightText,
    String? repsText,
    String? rpeText,
    this.restSeconds,
  }) : weightController = TextEditingController(text: weightText ?? ''),
       repsController = TextEditingController(text: repsText ?? ''),
       rpeController = TextEditingController(text: rpeText ?? '');

  final TextEditingController weightController;
  final TextEditingController repsController;
  final TextEditingController rpeController;
  int? restSeconds;

  bool get hasAnyInput =>
      weightController.text.trim().isNotEmpty ||
      repsController.text.trim().isNotEmpty ||
      rpeController.text.trim().isNotEmpty;

  int? get repsValue {
    final raw = repsController.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    return int.tryParse(raw);
  }

  double? get weightValue {
    final raw = weightController.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    return double.tryParse(raw);
  }

  double? get rpeValue {
    final raw = rpeController.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    return double.tryParse(raw);
  }

  bool get isLoggedSet {
    if (!hasAnyInput) {
      return false;
    }
    final reps = repsValue;
    final weight = weightValue;
    if (reps == null || reps <= 0 || weight == null || weight <= 0) {
      return false;
    }
    final rawRpe = rpeController.text.trim();
    if (rawRpe.isEmpty) {
      return true;
    }
    final rpe = rpeValue;
    if (rpe == null) {
      return false;
    }
    return rpe >= 0 && rpe <= 10;
  }

  void dispose() {
    weightController.dispose();
    repsController.dispose();
    rpeController.dispose();
  }
}

class _SessionPayload {
  const _SessionPayload({
    required this.logs,
    required this.totalSets,
    required this.unfilledSetCount,
  });

  final List<WorkoutExerciseLogInput> logs;
  final int totalSets;
  final int unfilledSetCount;
}
