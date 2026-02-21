import 'dart:async';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';
import '../../core/db/seed_data.dart';
import '../../core/db/user_exercise_database.dart';
import '../../core/models/exercise_with_labels.dart';

abstract class ExerciseRepository {
  Stream<List<ExerciseWithLabels>> watchExercises();

  Stream<List<String>> watchAllLabels();

  Future<ExerciseWithLabels?> getById(String id);

  Future<List<String>> getAllLabels();

  Future<void> seedIfEmpty();

  Future<String> createExercise({
    required String name,
    required List<String> labels,
  });

  Future<void> saveLabels({
    required String exerciseId,
    required List<String> labels,
  });

  Future<void> restoreStandardLabels(String standardExerciseId);

  Future<void> createLabel(String label);
}

class DriftExerciseRepository implements ExerciseRepository {
  DriftExerciseRepository(
    this._db,
    this._userDb, {
    Uuid? uuid,
    DateTime Function()? now,
  }) : _uuid = uuid ?? const Uuid(),
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final UserExerciseDatabase _userDb;
  final Uuid _uuid;
  final DateTime Function() _now;

  @override
  Stream<List<ExerciseWithLabels>> watchExercises() {
    final standardStream = _watchStandardExercises();
    final userStream = _watchUserExercises();

    return Stream.multi((controller) {
      List<_StandardExercise>? standardRows;
      List<_UserExercise>? userRows;

      void emitIfReady() {
        if (standardRows == null || userRows == null) {
          return;
        }
        controller.add(_mergeExercises(standardRows!, userRows!));
      }

      final standardSub = standardStream.listen(
        (rows) {
          standardRows = rows;
          emitIfReady();
        },
        onError: controller.addError,
      );
      final userSub = userStream.listen(
        (rows) {
          userRows = rows;
          emitIfReady();
        },
        onError: controller.addError,
      );

      controller.onCancel = () async {
        await standardSub.cancel();
        await userSub.cancel();
      };
    }, isBroadcast: true);
  }

  @override
  Stream<List<String>> watchAllLabels() {
    final standardStream = _watchStandardLabelNames();
    final userStream = _watchUserLabelNames();

    return Stream.multi((controller) {
      List<String>? standardLabels;
      List<String>? userLabels;

      void emitIfReady() {
        if (standardLabels == null || userLabels == null) {
          return;
        }
        controller.add(_mergeLabelNames(standardLabels!, userLabels!));
      }

      final standardSub = standardStream.listen(
        (rows) {
          standardLabels = rows;
          emitIfReady();
        },
        onError: controller.addError,
      );
      final userSub = userStream.listen(
        (rows) {
          userLabels = rows;
          emitIfReady();
        },
        onError: controller.addError,
      );

      controller.onCancel = () async {
        await standardSub.cancel();
        await userSub.cancel();
      };
    }, isBroadcast: true);
  }

  @override
  Future<ExerciseWithLabels?> getById(String id) async {
    final exercises = await _getMergedExercises();
    return exercises.firstWhereOrNull((exercise) => exercise.id == id);
  }

  @override
  Future<List<String>> getAllLabels() async {
    final standard = await _getStandardLabelNames();
    final user = await _getUserLabelNames();
    return _mergeLabelNames(standard, user);
  }

  @override
  Future<void> seedIfEmpty() async {
    final seededExercise =
        await (_db.select(_db.exercises)
              ..where((tbl) => tbl.isSeeded.equals(true))
              ..limit(1))
            .getSingleOrNull();
    if (seededExercise != null) {
      return;
    }

    final now = _now().millisecondsSinceEpoch;
    final uniqueLabels = <String>{};
    for (final exercise in seededExercises) {
      uniqueLabels.addAll(exercise.labels);
    }

    await _db.transaction(() async {
      for (final labelName in uniqueLabels.toList()..sort()) {
        await _db.into(_db.exerciseLabels).insert(
          ExerciseLabelsCompanion.insert(
            id: labelIdFromName(labelName),
            name: labelName,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }

      for (final exercise in seededExercises) {
        await _db.into(_db.exercises).insert(
          ExercisesCompanion.insert(
            id: exercise.id,
            name: exercise.name,
            createdAt: now,
            updatedAt: now,
            isSeeded: const Value(true),
          ),
          mode: InsertMode.insertOrIgnore,
        );

        for (final labelName in exercise.labels) {
          await _db.into(_db.exerciseLabelLinks).insert(
            ExerciseLabelLinksCompanion.insert(
              exerciseId: exercise.id,
              labelId: labelIdFromName(labelName),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    });
  }

  @override
  Future<String> createExercise({
    required String name,
    required List<String> labels,
  }) async {
    final normalizedName = name.trim();
    final normalizedLabels = _normalizeLabels(labels);
    if (normalizedName.isEmpty) {
      throw ArgumentError('Exercise name is required.');
    }
    if (normalizedLabels.isEmpty) {
      throw ArgumentError('At least one label is required.');
    }

    final exerciseId = _uuid.v4();
    final nowMs = _now().millisecondsSinceEpoch;

    await _userDb.transaction(() async {
      await _userDb.into(_userDb.userExercises).insert(
        UserExercisesCompanion.insert(
          id: exerciseId,
          name: normalizedName,
          isOverride: const Value(false),
          standardExerciseId: const Value(null),
          createdAt: nowMs,
          updatedAt: nowMs,
        ),
      );

      await _replaceUserExerciseLabels(exerciseId, normalizedLabels);
    });

    // Mirror custom exercises into the main DB so existing FK references still work.
    await _db.into(_db.exercises).insert(
      ExercisesCompanion.insert(
        id: exerciseId,
        name: normalizedName,
        createdAt: nowMs,
        updatedAt: nowMs,
        isSeeded: const Value(false),
      ),
      mode: InsertMode.insertOrReplace,
    );

    return exerciseId;
  }

  @override
  Future<void> saveLabels({
    required String exerciseId,
    required List<String> labels,
  }) async {
    final normalizedLabels = _normalizeLabels(labels);
    if (normalizedLabels.isEmpty) {
      throw ArgumentError('At least one label is required.');
    }

    final nowMs = _now().millisecondsSinceEpoch;
    final standard = await _getStandardExerciseById(exerciseId);
    if (standard != null) {
      final sameAsStandard = const ListEquality<String>().equals(
        [...standard.labels]..sort(),
        [...normalizedLabels]..sort(),
      );
      if (sameAsStandard) {
        await restoreStandardLabels(exerciseId);
        return;
      }

      await _userDb.transaction(() async {
        final existingOverride = await (_userDb.select(_userDb.userExercises)
              ..where((tbl) => tbl.standardExerciseId.equals(exerciseId))
              ..limit(1))
            .getSingleOrNull();

        final overrideId = existingOverride?.id ?? _uuid.v4();
        if (existingOverride == null) {
          await _userDb.into(_userDb.userExercises).insert(
            UserExercisesCompanion.insert(
              id: overrideId,
              name: standard.name,
              isOverride: const Value(true),
              standardExerciseId: Value(exerciseId),
              createdAt: nowMs,
              updatedAt: nowMs,
            ),
          );
        } else {
          await (_userDb.update(_userDb.userExercises)
                ..where((tbl) => tbl.id.equals(existingOverride.id)))
              .write(
                UserExercisesCompanion(updatedAt: Value(nowMs)),
              );
        }

        await _replaceUserExerciseLabels(overrideId, normalizedLabels);
      });
      return;
    }

    final customExercise = await (_userDb.select(_userDb.userExercises)
          ..where((tbl) => tbl.id.equals(exerciseId))
          ..limit(1))
        .getSingleOrNull();
    if (customExercise == null || customExercise.isOverride) {
      throw ArgumentError('Exercise not found: $exerciseId');
    }

    await _userDb.transaction(() async {
      await (_userDb.update(_userDb.userExercises)
            ..where((tbl) => tbl.id.equals(exerciseId)))
          .write(
            UserExercisesCompanion(updatedAt: Value(nowMs)),
          );
      await _replaceUserExerciseLabels(exerciseId, normalizedLabels);
    });
  }

  @override
  Future<void> restoreStandardLabels(String standardExerciseId) async {
    final overrideExercise = await (_userDb.select(_userDb.userExercises)
          ..where((tbl) => tbl.standardExerciseId.equals(standardExerciseId))
          ..limit(1))
        .getSingleOrNull();
    if (overrideExercise == null) {
      return;
    }

    await (_userDb.delete(_userDb.userExercises)
          ..where((tbl) => tbl.id.equals(overrideExercise.id)))
        .go();
  }

  @override
  Future<void> createLabel(String label) async {
    final normalized = label.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw ArgumentError('Label cannot be empty.');
    }

    await _userDb.into(_userDb.userExerciseLabels).insert(
      UserExerciseLabelsCompanion.insert(
        id: labelIdFromName(normalized),
        name: normalized,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Stream<List<_StandardExercise>> _watchStandardExercises() {
    final query = _db.select(_db.exercises).join([
      leftOuterJoin(
        _db.exerciseLabelLinks,
        _db.exerciseLabelLinks.exerciseId.equalsExp(_db.exercises.id),
      ),
      leftOuterJoin(
        _db.exerciseLabels,
        _db.exerciseLabels.id.equalsExp(_db.exerciseLabelLinks.labelId),
      ),
    ])
      ..where(_db.exercises.isSeeded.equals(true))
      ..orderBy([
        OrderingTerm(expression: _db.exercises.name),
        OrderingTerm(expression: _db.exerciseLabels.name),
      ]);

    return query.watch().map(_mapStandardRows);
  }

  Future<List<_StandardExercise>> _getStandardExercises() {
    final query = _db.select(_db.exercises).join([
      leftOuterJoin(
        _db.exerciseLabelLinks,
        _db.exerciseLabelLinks.exerciseId.equalsExp(_db.exercises.id),
      ),
      leftOuterJoin(
        _db.exerciseLabels,
        _db.exerciseLabels.id.equalsExp(_db.exerciseLabelLinks.labelId),
      ),
    ])
      ..where(_db.exercises.isSeeded.equals(true))
      ..orderBy([
        OrderingTerm(expression: _db.exercises.name),
        OrderingTerm(expression: _db.exerciseLabels.name),
      ]);

    return query.get().then(_mapStandardRows);
  }

  Future<_StandardExercise?> _getStandardExerciseById(String exerciseId) async {
    final standardRows = await _getStandardExercises();
    return standardRows.firstWhereOrNull((entry) => entry.id == exerciseId);
  }

  Stream<List<_UserExercise>> _watchUserExercises() {
    final query = _userDb.select(_userDb.userExercises).join([
      leftOuterJoin(
        _userDb.userExerciseLabelLinks,
        _userDb.userExerciseLabelLinks.exerciseId.equalsExp(
          _userDb.userExercises.id,
        ),
      ),
      leftOuterJoin(
        _userDb.userExerciseLabels,
        _userDb.userExerciseLabels.id.equalsExp(
          _userDb.userExerciseLabelLinks.labelId,
        ),
      ),
    ])
      ..orderBy([
        OrderingTerm(expression: _userDb.userExercises.name),
        OrderingTerm(expression: _userDb.userExerciseLabels.name),
      ]);

    return query.watch().map(_mapUserRows);
  }

  Future<List<_UserExercise>> _getUserExercises() {
    final query = _userDb.select(_userDb.userExercises).join([
      leftOuterJoin(
        _userDb.userExerciseLabelLinks,
        _userDb.userExerciseLabelLinks.exerciseId.equalsExp(
          _userDb.userExercises.id,
        ),
      ),
      leftOuterJoin(
        _userDb.userExerciseLabels,
        _userDb.userExerciseLabels.id.equalsExp(
          _userDb.userExerciseLabelLinks.labelId,
        ),
      ),
    ])
      ..orderBy([
        OrderingTerm(expression: _userDb.userExercises.name),
        OrderingTerm(expression: _userDb.userExerciseLabels.name),
      ]);

    return query.get().then(_mapUserRows);
  }

  Stream<List<String>> _watchStandardLabelNames() {
    final query = _db.select(_db.exerciseLabels)
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]);
    return query.watch().map(
      (rows) => rows
          .map((row) => row.name)
          .toList(growable: false),
    );
  }

  Stream<List<String>> _watchUserLabelNames() {
    final query = _userDb.select(_userDb.userExerciseLabels)
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]);
    return query.watch().map(
      (rows) => rows
          .map((row) => row.name)
          .toList(growable: false),
    );
  }

  Future<List<String>> _getStandardLabelNames() async {
    final query = _db.select(_db.exerciseLabels)
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]);
    final rows = await query.get();
    return rows.map((row) => row.name).toList(growable: false);
  }

  Future<List<String>> _getUserLabelNames() async {
    final query = _userDb.select(_userDb.userExerciseLabels)
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]);
    final rows = await query.get();
    return rows.map((row) => row.name).toList(growable: false);
  }

  Future<List<ExerciseWithLabels>> _getMergedExercises() async {
    final values = await Future.wait([_getStandardExercises(), _getUserExercises()]);
    final standardRows = values[0] as List<_StandardExercise>;
    final userRows = values[1] as List<_UserExercise>;
    return _mergeExercises(standardRows, userRows);
  }

  List<ExerciseWithLabels> _mergeExercises(
    List<_StandardExercise> standardRows,
    List<_UserExercise> userRows,
  ) {
    final overridesByStandardId = <String, _UserExercise>{};
    final customExercises = <_UserExercise>[];
    for (final user in userRows) {
      if (user.isOverride) {
        if (user.standardExerciseId != null) {
          overridesByStandardId[user.standardExerciseId!] = user;
        }
      } else {
        customExercises.add(user);
      }
    }

    final merged = <ExerciseWithLabels>[];
    for (final standard in standardRows) {
      final override = overridesByStandardId[standard.id];
      merged.add(
        ExerciseWithLabels(
          id: standard.id,
          name: standard.name,
          labels: List.unmodifiable(override?.labels ?? standard.labels),
          isStandard: true,
          hasCustomLabelOverride: override != null,
          overrideExerciseId: override?.id,
          historyExerciseIds: override == null
              ? [standard.id]
              : [standard.id, override.id],
        ),
      );
    }

    for (final custom in customExercises) {
      merged.add(
        ExerciseWithLabels(
          id: custom.id,
          name: custom.name,
          labels: List.unmodifiable(custom.labels),
          isStandard: false,
          hasCustomLabelOverride: false,
          historyExerciseIds: [custom.id],
        ),
      );
    }

    merged.sort((a, b) {
      final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (byName != 0) {
        return byName;
      }
      return a.id.compareTo(b.id);
    });

    return List.unmodifiable(merged);
  }

  List<_StandardExercise> _mapStandardRows(List<TypedResult> rows) {
    final grouped = <String, _StandardExerciseAccumulator>{};

    for (final row in rows) {
      final exercise = row.readTable(_db.exercises);
      final label = row.readTableOrNull(_db.exerciseLabels);

      final entry = grouped.putIfAbsent(
        exercise.id,
        () => _StandardExerciseAccumulator(id: exercise.id, name: exercise.name),
      );

      if (label != null && !entry.labels.contains(label.name)) {
        entry.labels.add(label.name);
      }
    }

    final values = grouped.values
        .map(
          (entry) => _StandardExercise(
            id: entry.id,
            name: entry.name,
            labels: List.unmodifiable(entry.labels),
          ),
        )
        .toList(growable: false);
    values.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return values;
  }

  List<_UserExercise> _mapUserRows(List<TypedResult> rows) {
    final grouped = <String, _UserExerciseAccumulator>{};

    for (final row in rows) {
      final exercise = row.readTable(_userDb.userExercises);
      final label = row.readTableOrNull(_userDb.userExerciseLabels);

      final entry = grouped.putIfAbsent(
        exercise.id,
        () => _UserExerciseAccumulator(
          id: exercise.id,
          name: exercise.name,
          isOverride: exercise.isOverride,
          standardExerciseId: exercise.standardExerciseId,
        ),
      );

      if (label != null && !entry.labels.contains(label.name)) {
        entry.labels.add(label.name);
      }
    }

    final values = grouped.values
        .map(
          (entry) => _UserExercise(
            id: entry.id,
            name: entry.name,
            isOverride: entry.isOverride,
            standardExerciseId: entry.standardExerciseId,
            labels: List.unmodifiable(entry.labels),
          ),
        )
        .toList(growable: false);
    values.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return values;
  }

  Future<void> _replaceUserExerciseLabels(
    String exerciseId,
    List<String> labels,
  ) async {
    await (_userDb.delete(_userDb.userExerciseLabelLinks)
          ..where((tbl) => tbl.exerciseId.equals(exerciseId)))
        .go();

    for (final labelName in labels) {
      final labelId = labelIdFromName(labelName);
      await _userDb.into(_userDb.userExerciseLabels).insert(
        UserExerciseLabelsCompanion.insert(id: labelId, name: labelName),
        mode: InsertMode.insertOrIgnore,
      );
      await _userDb.into(_userDb.userExerciseLabelLinks).insert(
        UserExerciseLabelLinksCompanion.insert(
          exerciseId: exerciseId,
          labelId: labelId,
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  List<String> _normalizeLabels(List<String> labels) {
    final unique = <String>{};
    for (final rawLabel in labels) {
      final normalized = rawLabel.trim().toLowerCase();
      if (normalized.isNotEmpty) {
        unique.add(normalized);
      }
    }
    final output = unique.toList()..sort();
    return output;
  }

  List<String> _mergeLabelNames(List<String> standard, List<String> user) {
    final merged = <String>{...standard, ...user};
    final output = merged.toList()..sort();
    return output;
  }
}

class _StandardExercise {
  const _StandardExercise({
    required this.id,
    required this.name,
    required this.labels,
  });

  final String id;
  final String name;
  final List<String> labels;
}

class _StandardExerciseAccumulator {
  _StandardExerciseAccumulator({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
  final List<String> labels = [];
}

class _UserExercise {
  const _UserExercise({
    required this.id,
    required this.name,
    required this.isOverride,
    required this.standardExerciseId,
    required this.labels,
  });

  final String id;
  final String name;
  final bool isOverride;
  final String? standardExerciseId;
  final List<String> labels;
}

class _UserExerciseAccumulator {
  _UserExerciseAccumulator({
    required this.id,
    required this.name,
    required this.isOverride,
    required this.standardExerciseId,
  });

  final String id;
  final String name;
  final bool isOverride;
  final String? standardExerciseId;
  final List<String> labels = [];
}
