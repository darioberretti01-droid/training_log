import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/db/app_database.dart';
import 'workout_draft.dart';

class WorkoutDraftStorage {
  WorkoutDraftStorage(this._db);

  static const String _activeDraftId = 'active';
  final AppDatabase _db;

  Future<void> saveDraft(WorkoutDraft draft) async {
    final payload = jsonEncode(_toJson(draft));
    await _db.customStatement(
      'INSERT OR REPLACE INTO workout_drafts (id, payload, updated_at) '
      'VALUES (?, ?, ?)',
      <Object>[_activeDraftId, payload, draft.updatedAtMs],
    );
  }

  Future<WorkoutDraft?> loadDraft() async {
    final result = await _db
        .customSelect(
          'SELECT payload FROM workout_drafts WHERE id = ? LIMIT 1',
          variables: [Variable.withString(_activeDraftId)],
        )
        .getSingleOrNull();
    if (result == null) {
      return null;
    }

    final payload = result.read<String>('payload');
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        await clearDraft();
        return null;
      }
      return _fromJson(decoded);
    } catch (_) {
      await clearDraft();
      return null;
    }
  }

  Future<void> clearDraft() async {
    await _db.customStatement(
      'DELETE FROM workout_drafts WHERE id = ?',
      <Object>[_activeDraftId],
    );
  }

  Map<String, dynamic> _toJson(WorkoutDraft draft) {
    return <String, dynamic>{
      'mode': draft.mode,
      'splitId': draft.splitId,
      'dayIndex': draft.dayIndex,
      'startedAtMs': draft.startedAtMs,
      'updatedAtMs': draft.updatedAtMs,
      'exercises': draft.exercises
          .map(
            (exercise) => <String, dynamic>{
              'exerciseId': exercise.exerciseId,
              'exerciseName': exercise.exerciseName,
              'labels': exercise.labels,
              'repMin': exercise.repMin,
              'repMax': exercise.repMax,
              'targetSets': exercise.targetSets,
              'restSeconds': exercise.restSeconds,
              'targetRpe': exercise.targetRpe,
              'rows': exercise.rows
                  .map(
                    (row) => <String, dynamic>{
                      'weightText': row.weightText,
                      'repsText': row.repsText,
                      'rpeText': row.rpeText,
                      'restSeconds': row.restSeconds,
                    },
                  )
                  .toList(growable: false),
            },
          )
          .toList(growable: false),
    };
  }

  WorkoutDraft _fromJson(Map<String, dynamic> json) {
    final rawExercises = (json['exercises'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    return WorkoutDraft(
      mode: (json['mode'] as String?) ?? '',
      splitId: json['splitId'] as String?,
      dayIndex: json['dayIndex'] as int?,
      startedAtMs: (json['startedAtMs'] as int?) ?? 0,
      updatedAtMs: (json['updatedAtMs'] as int?) ?? 0,
      exercises: rawExercises
          .map((exerciseJson) {
            final rowsJson =
                (exerciseJson['rows'] as List<dynamic>? ?? const [])
                    .whereType<Map<String, dynamic>>()
                    .toList(growable: false);
            final labels =
                (exerciseJson['labels'] as List<dynamic>? ?? const [])
                    .whereType<String>()
                    .toList(growable: false);
            return WorkoutDraftExercise(
              exerciseId: (exerciseJson['exerciseId'] as String?) ?? '',
              exerciseName: (exerciseJson['exerciseName'] as String?) ?? '',
              labels: labels,
              repMin: (exerciseJson['repMin'] as int?) ?? 1,
              repMax: (exerciseJson['repMax'] as int?) ?? 1,
              targetSets: (exerciseJson['targetSets'] as int?) ?? 1,
              restSeconds: exerciseJson['restSeconds'] as int?,
              targetRpe: (exerciseJson['targetRpe'] as num?)?.toDouble(),
              rows: rowsJson
                  .map(
                    (rowJson) => WorkoutDraftSetRow(
                      weightText: (rowJson['weightText'] as String?) ?? '',
                      repsText: (rowJson['repsText'] as String?) ?? '',
                      rpeText: (rowJson['rpeText'] as String?) ?? '',
                      restSeconds: rowJson['restSeconds'] as int?,
                    ),
                  )
                  .toList(growable: false),
            );
          })
          .toList(growable: false),
    );
  }
}
