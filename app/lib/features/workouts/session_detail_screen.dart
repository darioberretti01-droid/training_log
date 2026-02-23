import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/models/logged_set_input.dart';
import '../../core/state/providers.dart';
import 'quick_workout_repository.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  final TextEditingController _sessionNameController = TextEditingController();
  final List<_SessionExerciseEditState> _exerciseStates = [];
  String? _hydratedSessionId;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _sessionNameController.dispose();
    for (final exercise in _exerciseStates) {
      exercise.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailsState = ref.watch(sessionDetailsProvider(widget.sessionId));
    return detailsState.when(
      data: (details) {
        if (details == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Session')),
            body: const Center(child: Text('Session not found.')),
          );
        }
        _hydrateIfNeeded(details);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Session Overview'),
            actions: [
              IconButton(
                key: const Key('session_detail_delete'),
                tooltip: 'Delete session',
                onPressed: _isSaving || _isDeleting ? null : _deleteSession,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton(
                  key: const Key('session_detail_save'),
                  onPressed: _isSaving || _isDeleting ? null : _saveChanges,
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
              _SessionSummaryCard(
                session: details.session,
                totalSets: details.totalSets,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('session_detail_name'),
                controller: _sessionNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Session name',
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(
                _exerciseStates.length,
                (exerciseIndex) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SessionExerciseCard(
                    exercise: _exerciseStates[exerciseIndex],
                    onAddSet: () => _addSet(exerciseIndex),
                    onDeleteLastSet: () => _deleteLastSet(exerciseIndex),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Session')),
        body: Center(child: Text('Failed to load session: $error')),
      ),
    );
  }

  void _hydrateIfNeeded(WorkoutSessionDetails details) {
    if (_hydratedSessionId == details.session.id) {
      return;
    }
    _hydratedSessionId = details.session.id;

    for (final exercise in _exerciseStates) {
      exercise.dispose();
    }
    _exerciseStates.clear();

    _sessionNameController.text = details.session.sessionName ?? '';
    for (final exercise in details.exercises) {
      final editState = _SessionExerciseEditState(
        exerciseId: exercise.exerciseId,
        exerciseName: exercise.exerciseName,
      );
      if (exercise.sets.isEmpty) {
        editState.rows.add(_SessionSetEditState());
      } else {
        for (final set in exercise.sets) {
          editState.rows.add(
            _SessionSetEditState(
              repsText: '${set.reps}',
              weightText: '${set.weightKg}',
              restText: set.restSeconds?.toString() ?? '',
              rpeText: set.rpe?.toString() ?? '',
            ),
          );
        }
      }
      _exerciseStates.add(editState);
    }
  }

  void _addSet(int exerciseIndex) {
    final exercise = _exerciseStates[exerciseIndex];
    final previous = exercise.rows.isEmpty ? null : exercise.rows.last;
    exercise.rows.add(
      _SessionSetEditState(
        repsText: previous?.repsController.text ?? '',
        weightText: previous?.weightController.text ?? '',
        restText: previous?.restController.text ?? '',
        rpeText: previous?.rpeController.text ?? '',
      ),
    );
    setState(() {});
  }

  void _deleteLastSet(int exerciseIndex) {
    final exercise = _exerciseStates[exerciseIndex];
    if (exercise.rows.length <= 1) {
      return;
    }
    final removed = exercise.rows.removeLast();
    removed.dispose();
    setState(() {});
  }

  Future<void> _saveChanges() async {
    final exercises = <WorkoutExerciseLogInput>[];
    for (final exercise in _exerciseStates) {
      final sets = <LoggedSetInput>[];
      for (var index = 0; index < exercise.rows.length; index++) {
        final row = exercise.rows[index];
        if (!row.hasAnyInput) {
          continue;
        }
        final reps = int.tryParse(row.repsController.text.trim());
        final weight = double.tryParse(row.weightController.text.trim());
        final restText = row.restController.text.trim();
        final rest = restText.isEmpty ? null : int.tryParse(restText);
        final rpeText = row.rpeController.text.trim();
        final rpe = rpeText.isEmpty ? null : double.tryParse(rpeText);

        if (reps == null || reps <= 0 || weight == null || weight <= 0) {
          _showMessage(
            '${exercise.exerciseName} set ${index + 1}: reps and weight must be valid.',
          );
          return;
        }
        if (restText.isNotEmpty && (rest == null || rest < 0)) {
          _showMessage(
            '${exercise.exerciseName} set ${index + 1}: rest must be non-negative.',
          );
          return;
        }
        if (rpeText.isNotEmpty && (rpe == null || rpe < 0 || rpe > 10)) {
          _showMessage(
            '${exercise.exerciseName} set ${index + 1}: RPE must be 0-10.',
          );
          return;
        }

        sets.add(
          LoggedSetInput(
            reps: reps,
            weightKg: weight,
            restSeconds: rest,
            rpe: rpe,
          ),
        );
      }
      if (sets.isNotEmpty) {
        exercises.add(
          WorkoutExerciseLogInput(exerciseId: exercise.exerciseId, sets: sets),
        );
      }
    }

    if (exercises.isEmpty) {
      _showMessage('At least one set is required.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(quickWorkoutRepositoryProvider)
          .updateWorkoutSession(
            sessionId: widget.sessionId,
            endedAt: ref.read(appClockProvider)(),
            sessionName: _normalizeSessionName(_sessionNameController.text),
            exercises: exercises,
          );
      ref.invalidate(sessionDetailsProvider(widget.sessionId));
      ref.invalidate(recentHomeSessionsProvider);
      ref.invalidate(lastHomeSessionProvider);
      ref.invalidate(lastSplitDaySessionProvider);
      ref.invalidate(suggestedWorkoutCardStateProvider);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Session updated.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Could not update session: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteSession() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete session?'),
        content: const Text('This will permanently delete the workout record.'),
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

    setState(() => _isDeleting = true);
    try {
      await ref
          .read(quickWorkoutRepositoryProvider)
          .deleteWorkoutSession(widget.sessionId);
      ref.invalidate(recentHomeSessionsProvider);
      ref.invalidate(lastHomeSessionProvider);
      ref.invalidate(lastSplitDaySessionProvider);
      ref.invalidate(suggestedWorkoutCardStateProvider);
      ref.invalidate(sessionDetailsProvider(widget.sessionId));

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Session deleted.')));
      context.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Could not delete session: $error');
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  String? _normalizeSessionName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SessionSummaryCard extends StatelessWidget {
  const _SessionSummaryCard({required this.session, required this.totalSets});

  final WorkoutSession session;
  final int totalSets;

  @override
  Widget build(BuildContext context) {
    final started = DateTime.fromMillisecondsSinceEpoch(session.startedAt);
    final ended = DateTime.fromMillisecondsSinceEpoch(session.endedAt);
    final duration = ended.difference(started).inMinutes;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('MMM d, yyyy HH:mm').format(started)),
            const SizedBox(height: 4),
            Text('Type: ${session.sessionType}'),
            Text('Duration: ${duration < 0 ? 0 : duration} min'),
            Text('Total sets: $totalSets'),
          ],
        ),
      ),
    );
  }
}

class _SessionExerciseCard extends StatelessWidget {
  const _SessionExerciseCard({
    required this.exercise,
    required this.onAddSet,
    required this.onDeleteLastSet,
  });

  final _SessionExerciseEditState exercise;
  final VoidCallback onAddSet;
  final VoidCallback onDeleteLastSet;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.exerciseName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...List.generate(
              exercise.rows.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SessionSetRow(
                  setNumber: index + 1,
                  row: exercise.rows[index],
                ),
              ),
            ),
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
                    onPressed: onDeleteLastSet,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete set'),
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

class _SessionSetRow extends StatelessWidget {
  const _SessionSetRow({required this.setNumber, required this.row});

  final int setNumber;
  final _SessionSetEditState row;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 30, child: Text('$setNumber')),
        Expanded(
          child: _SessionNumberField(
            controller: row.weightController,
            label: 'Weight',
            decimal: true,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _SessionNumberField(
            controller: row.repsController,
            label: 'Reps',
            decimal: false,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _SessionNumberField(
            controller: row.restController,
            label: 'Rest',
            decimal: false,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _SessionNumberField(
            controller: row.rpeController,
            label: 'RPE',
            decimal: true,
          ),
        ),
      ],
    );
  }
}

class _SessionNumberField extends StatelessWidget {
  const _SessionNumberField({
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

class _SessionExerciseEditState {
  _SessionExerciseEditState({
    required this.exerciseId,
    required this.exerciseName,
  });

  final String exerciseId;
  final String exerciseName;
  final List<_SessionSetEditState> rows = [];

  void dispose() {
    for (final row in rows) {
      row.dispose();
    }
  }
}

class _SessionSetEditState {
  _SessionSetEditState({
    String repsText = '',
    String weightText = '',
    String restText = '',
    String rpeText = '',
  }) : repsController = TextEditingController(text: repsText),
       weightController = TextEditingController(text: weightText),
       restController = TextEditingController(text: restText),
       rpeController = TextEditingController(text: rpeText);

  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController restController;
  final TextEditingController rpeController;

  bool get hasAnyInput =>
      repsController.text.trim().isNotEmpty ||
      weightController.text.trim().isNotEmpty ||
      restController.text.trim().isNotEmpty ||
      rpeController.text.trim().isNotEmpty;

  void dispose() {
    repsController.dispose();
    weightController.dispose();
    restController.dispose();
    rpeController.dispose();
  }
}
