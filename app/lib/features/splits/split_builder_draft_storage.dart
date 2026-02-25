import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/db/app_database.dart';
import 'split_builder_draft.dart';

class SplitBuilderDraftStorage {
  SplitBuilderDraftStorage(this._db);

  static const String _activeDraftId = 'active';
  final AppDatabase _db;

  Future<void> saveDraft(SplitBuilderDraft draft) async {
    final payload = jsonEncode(_toJson(draft));
    await _db.customStatement(
      'INSERT OR REPLACE INTO split_builder_drafts (id, payload, updated_at) '
      'VALUES (?, ?, ?)',
      <Object>[_activeDraftId, payload, draft.updatedAtMs],
    );
  }

  Future<SplitBuilderDraft?> loadDraft() async {
    final result = await _db
        .customSelect(
          'SELECT payload FROM split_builder_drafts WHERE id = ? LIMIT 1',
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
      'DELETE FROM split_builder_drafts WHERE id = ?',
      <Object>[_activeDraftId],
    );
  }

  Map<String, dynamic> _toJson(SplitBuilderDraft draft) {
    return <String, dynamic>{
      'splitName': draft.splitName,
      'setAsActive': draft.setAsActive,
      'selectedVolumeControlLabels': draft.selectedVolumeControlLabels,
      'manuallyCreatedControlLabels': draft.manuallyCreatedControlLabels,
      'updatedAtMs': draft.updatedAtMs,
      'days': draft.days
          .map(
            (day) => <String, dynamic>{
              'title': day.title,
              'plannedExercises': day.plannedExercises
                  .map(
                    (planned) => <String, dynamic>{
                      'selectedExerciseId': planned.selectedExerciseId,
                      'sets': planned.sets,
                      'repMin': planned.repMin,
                      'repMax': planned.repMax,
                      'rest': planned.rest,
                      'rpe': planned.rpe,
                    },
                  )
                  .toList(growable: false),
            },
          )
          .toList(growable: false),
    };
  }

  SplitBuilderDraft _fromJson(Map<String, dynamic> json) {
    final rawDays = (json['days'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    final selectedVolumeControlLabels =
        (json['selectedVolumeControlLabels'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(growable: false);

    final manuallyCreatedControlLabels =
        (json['manuallyCreatedControlLabels'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(growable: false);

    return SplitBuilderDraft(
      splitName: (json['splitName'] as String?) ?? '',
      setAsActive: (json['setAsActive'] as bool?) ?? true,
      selectedVolumeControlLabels: selectedVolumeControlLabels,
      manuallyCreatedControlLabels: manuallyCreatedControlLabels,
      updatedAtMs: (json['updatedAtMs'] as int?) ?? 0,
      days: rawDays
          .map((dayJson) {
            final rawExercises =
                (dayJson['plannedExercises'] as List<dynamic>? ?? const [])
                    .whereType<Map<String, dynamic>>()
                    .toList(growable: false);
            return SplitBuilderDayDraft(
              title: (dayJson['title'] as String?) ?? '',
              plannedExercises: rawExercises
                  .map(
                    (exerciseJson) => SplitBuilderPlannedExerciseDraft(
                      selectedExerciseId:
                          exerciseJson['selectedExerciseId'] as String?,
                      sets: (exerciseJson['sets'] as String?) ?? '3',
                      repMin: (exerciseJson['repMin'] as String?) ?? '8',
                      repMax: (exerciseJson['repMax'] as String?) ?? '12',
                      rest: (exerciseJson['rest'] as String?) ?? '',
                      rpe: (exerciseJson['rpe'] as String?) ?? '',
                    ),
                  )
                  .toList(growable: false),
            );
          })
          .toList(growable: false),
    );
  }
}
