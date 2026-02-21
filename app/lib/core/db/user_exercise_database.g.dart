// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_exercise_database.dart';

// ignore_for_file: type=lint
class $UserExercisesTable extends UserExercises
    with TableInfo<$UserExercisesTable, UserExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isOverrideMeta = const VerificationMeta(
    'isOverride',
  );
  @override
  late final GeneratedColumn<bool> isOverride = GeneratedColumn<bool>(
    'is_override',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_override" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _standardExerciseIdMeta =
      const VerificationMeta('standardExerciseId');
  @override
  late final GeneratedColumn<String> standardExerciseId =
      GeneratedColumn<String>(
        'standard_exercise_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    isOverride,
    standardExerciseId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_override')) {
      context.handle(
        _isOverrideMeta,
        isOverride.isAcceptableOrUnknown(data['is_override']!, _isOverrideMeta),
      );
    }
    if (data.containsKey('standard_exercise_id')) {
      context.handle(
        _standardExerciseIdMeta,
        standardExerciseId.isAcceptableOrUnknown(
          data['standard_exercise_id']!,
          _standardExerciseIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_override'],
      )!,
      standardExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}standard_exercise_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserExercisesTable createAlias(String alias) {
    return $UserExercisesTable(attachedDatabase, alias);
  }
}

class UserExercise extends DataClass implements Insertable<UserExercise> {
  final String id;
  final String name;
  final bool isOverride;
  final String? standardExerciseId;
  final int createdAt;
  final int updatedAt;
  const UserExercise({
    required this.id,
    required this.name,
    required this.isOverride,
    this.standardExerciseId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['is_override'] = Variable<bool>(isOverride);
    if (!nullToAbsent || standardExerciseId != null) {
      map['standard_exercise_id'] = Variable<String>(standardExerciseId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  UserExercisesCompanion toCompanion(bool nullToAbsent) {
    return UserExercisesCompanion(
      id: Value(id),
      name: Value(name),
      isOverride: Value(isOverride),
      standardExerciseId: standardExerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(standardExerciseId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserExercise(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isOverride: serializer.fromJson<bool>(json['isOverride']),
      standardExerciseId: serializer.fromJson<String?>(
        json['standardExerciseId'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'isOverride': serializer.toJson<bool>(isOverride),
      'standardExerciseId': serializer.toJson<String?>(standardExerciseId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  UserExercise copyWith({
    String? id,
    String? name,
    bool? isOverride,
    Value<String?> standardExerciseId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => UserExercise(
    id: id ?? this.id,
    name: name ?? this.name,
    isOverride: isOverride ?? this.isOverride,
    standardExerciseId: standardExerciseId.present
        ? standardExerciseId.value
        : this.standardExerciseId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserExercise copyWithCompanion(UserExercisesCompanion data) {
    return UserExercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isOverride: data.isOverride.present
          ? data.isOverride.value
          : this.isOverride,
      standardExerciseId: data.standardExerciseId.present
          ? data.standardExerciseId.value
          : this.standardExerciseId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserExercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isOverride: $isOverride, ')
          ..write('standardExerciseId: $standardExerciseId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    isOverride,
    standardExerciseId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserExercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.isOverride == this.isOverride &&
          other.standardExerciseId == this.standardExerciseId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserExercisesCompanion extends UpdateCompanion<UserExercise> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> isOverride;
  final Value<String?> standardExerciseId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const UserExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isOverride = const Value.absent(),
    this.standardExerciseId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserExercisesCompanion.insert({
    required String id,
    required String name,
    this.isOverride = const Value.absent(),
    this.standardExerciseId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<UserExercise> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? isOverride,
    Expression<String>? standardExerciseId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isOverride != null) 'is_override': isOverride,
      if (standardExerciseId != null)
        'standard_exercise_id': standardExerciseId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<bool>? isOverride,
    Value<String?>? standardExerciseId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isOverride: isOverride ?? this.isOverride,
      standardExerciseId: standardExerciseId ?? this.standardExerciseId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isOverride.present) {
      map['is_override'] = Variable<bool>(isOverride.value);
    }
    if (standardExerciseId.present) {
      map['standard_exercise_id'] = Variable<String>(standardExerciseId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isOverride: $isOverride, ')
          ..write('standardExerciseId: $standardExerciseId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserExerciseLabelsTable extends UserExerciseLabels
    with TableInfo<$UserExerciseLabelsTable, UserExerciseLabel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserExerciseLabelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_exercise_labels';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserExerciseLabel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserExerciseLabel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserExerciseLabel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $UserExerciseLabelsTable createAlias(String alias) {
    return $UserExerciseLabelsTable(attachedDatabase, alias);
  }
}

class UserExerciseLabel extends DataClass
    implements Insertable<UserExerciseLabel> {
  final String id;
  final String name;
  const UserExerciseLabel({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  UserExerciseLabelsCompanion toCompanion(bool nullToAbsent) {
    return UserExerciseLabelsCompanion(id: Value(id), name: Value(name));
  }

  factory UserExerciseLabel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserExerciseLabel(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  UserExerciseLabel copyWith({String? id, String? name}) =>
      UserExerciseLabel(id: id ?? this.id, name: name ?? this.name);
  UserExerciseLabel copyWithCompanion(UserExerciseLabelsCompanion data) {
    return UserExerciseLabel(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserExerciseLabel(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserExerciseLabel &&
          other.id == this.id &&
          other.name == this.name);
}

class UserExerciseLabelsCompanion extends UpdateCompanion<UserExerciseLabel> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> rowid;
  const UserExerciseLabelsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserExerciseLabelsCompanion.insert({
    required String id,
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<UserExerciseLabel> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserExerciseLabelsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return UserExerciseLabelsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserExerciseLabelsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserExerciseLabelLinksTable extends UserExerciseLabelLinks
    with TableInfo<$UserExerciseLabelLinksTable, UserExerciseLabelLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserExerciseLabelLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES user_exercises (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _labelIdMeta = const VerificationMeta(
    'labelId',
  );
  @override
  late final GeneratedColumn<String> labelId = GeneratedColumn<String>(
    'label_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES user_exercise_labels (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [exerciseId, labelId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_exercise_label_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserExerciseLabelLink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('label_id')) {
      context.handle(
        _labelIdMeta,
        labelId.isAcceptableOrUnknown(data['label_id']!, _labelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_labelIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {exerciseId, labelId};
  @override
  UserExerciseLabelLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserExerciseLabelLink(
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      labelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_id'],
      )!,
    );
  }

  @override
  $UserExerciseLabelLinksTable createAlias(String alias) {
    return $UserExerciseLabelLinksTable(attachedDatabase, alias);
  }
}

class UserExerciseLabelLink extends DataClass
    implements Insertable<UserExerciseLabelLink> {
  final String exerciseId;
  final String labelId;
  const UserExerciseLabelLink({
    required this.exerciseId,
    required this.labelId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exercise_id'] = Variable<String>(exerciseId);
    map['label_id'] = Variable<String>(labelId);
    return map;
  }

  UserExerciseLabelLinksCompanion toCompanion(bool nullToAbsent) {
    return UserExerciseLabelLinksCompanion(
      exerciseId: Value(exerciseId),
      labelId: Value(labelId),
    );
  }

  factory UserExerciseLabelLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserExerciseLabelLink(
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      labelId: serializer.fromJson<String>(json['labelId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'exerciseId': serializer.toJson<String>(exerciseId),
      'labelId': serializer.toJson<String>(labelId),
    };
  }

  UserExerciseLabelLink copyWith({String? exerciseId, String? labelId}) =>
      UserExerciseLabelLink(
        exerciseId: exerciseId ?? this.exerciseId,
        labelId: labelId ?? this.labelId,
      );
  UserExerciseLabelLink copyWithCompanion(
    UserExerciseLabelLinksCompanion data,
  ) {
    return UserExerciseLabelLink(
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      labelId: data.labelId.present ? data.labelId.value : this.labelId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserExerciseLabelLink(')
          ..write('exerciseId: $exerciseId, ')
          ..write('labelId: $labelId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(exerciseId, labelId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserExerciseLabelLink &&
          other.exerciseId == this.exerciseId &&
          other.labelId == this.labelId);
}

class UserExerciseLabelLinksCompanion
    extends UpdateCompanion<UserExerciseLabelLink> {
  final Value<String> exerciseId;
  final Value<String> labelId;
  final Value<int> rowid;
  const UserExerciseLabelLinksCompanion({
    this.exerciseId = const Value.absent(),
    this.labelId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserExerciseLabelLinksCompanion.insert({
    required String exerciseId,
    required String labelId,
    this.rowid = const Value.absent(),
  }) : exerciseId = Value(exerciseId),
       labelId = Value(labelId);
  static Insertable<UserExerciseLabelLink> custom({
    Expression<String>? exerciseId,
    Expression<String>? labelId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (labelId != null) 'label_id': labelId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserExerciseLabelLinksCompanion copyWith({
    Value<String>? exerciseId,
    Value<String>? labelId,
    Value<int>? rowid,
  }) {
    return UserExerciseLabelLinksCompanion(
      exerciseId: exerciseId ?? this.exerciseId,
      labelId: labelId ?? this.labelId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (labelId.present) {
      map['label_id'] = Variable<String>(labelId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserExerciseLabelLinksCompanion(')
          ..write('exerciseId: $exerciseId, ')
          ..write('labelId: $labelId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$UserExerciseDatabase extends GeneratedDatabase {
  _$UserExerciseDatabase(QueryExecutor e) : super(e);
  $UserExerciseDatabaseManager get managers =>
      $UserExerciseDatabaseManager(this);
  late final $UserExercisesTable userExercises = $UserExercisesTable(this);
  late final $UserExerciseLabelsTable userExerciseLabels =
      $UserExerciseLabelsTable(this);
  late final $UserExerciseLabelLinksTable userExerciseLabelLinks =
      $UserExerciseLabelLinksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userExercises,
    userExerciseLabels,
    userExerciseLabelLinks,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'user_exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('user_exercise_label_links', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'user_exercise_labels',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('user_exercise_label_links', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$UserExercisesTableCreateCompanionBuilder =
    UserExercisesCompanion Function({
      required String id,
      required String name,
      Value<bool> isOverride,
      Value<String?> standardExerciseId,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$UserExercisesTableUpdateCompanionBuilder =
    UserExercisesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<bool> isOverride,
      Value<String?> standardExerciseId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$UserExercisesTableReferences
    extends
        BaseReferences<
          _$UserExerciseDatabase,
          $UserExercisesTable,
          UserExercise
        > {
  $$UserExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $UserExerciseLabelLinksTable,
    List<UserExerciseLabelLink>
  >
  _userExerciseLabelLinksRefsTable(_$UserExerciseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.userExerciseLabelLinks,
        aliasName: $_aliasNameGenerator(
          db.userExercises.id,
          db.userExerciseLabelLinks.exerciseId,
        ),
      );

  $$UserExerciseLabelLinksTableProcessedTableManager
  get userExerciseLabelLinksRefs {
    final manager = $$UserExerciseLabelLinksTableTableManager(
      $_db,
      $_db.userExerciseLabelLinks,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _userExerciseLabelLinksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UserExercisesTableFilterComposer
    extends Composer<_$UserExerciseDatabase, $UserExercisesTable> {
  $$UserExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOverride => $composableBuilder(
    column: $table.isOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get standardExerciseId => $composableBuilder(
    column: $table.standardExerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> userExerciseLabelLinksRefs(
    Expression<bool> Function($$UserExerciseLabelLinksTableFilterComposer f) f,
  ) {
    final $$UserExerciseLabelLinksTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.userExerciseLabelLinks,
          getReferencedColumn: (t) => t.exerciseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserExerciseLabelLinksTableFilterComposer(
                $db: $db,
                $table: $db.userExerciseLabelLinks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$UserExercisesTableOrderingComposer
    extends Composer<_$UserExerciseDatabase, $UserExercisesTable> {
  $$UserExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOverride => $composableBuilder(
    column: $table.isOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get standardExerciseId => $composableBuilder(
    column: $table.standardExerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserExercisesTableAnnotationComposer
    extends Composer<_$UserExerciseDatabase, $UserExercisesTable> {
  $$UserExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isOverride => $composableBuilder(
    column: $table.isOverride,
    builder: (column) => column,
  );

  GeneratedColumn<String> get standardExerciseId => $composableBuilder(
    column: $table.standardExerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> userExerciseLabelLinksRefs<T extends Object>(
    Expression<T> Function($$UserExerciseLabelLinksTableAnnotationComposer a) f,
  ) {
    final $$UserExerciseLabelLinksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.userExerciseLabelLinks,
          getReferencedColumn: (t) => t.exerciseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserExerciseLabelLinksTableAnnotationComposer(
                $db: $db,
                $table: $db.userExerciseLabelLinks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$UserExercisesTableTableManager
    extends
        RootTableManager<
          _$UserExerciseDatabase,
          $UserExercisesTable,
          UserExercise,
          $$UserExercisesTableFilterComposer,
          $$UserExercisesTableOrderingComposer,
          $$UserExercisesTableAnnotationComposer,
          $$UserExercisesTableCreateCompanionBuilder,
          $$UserExercisesTableUpdateCompanionBuilder,
          (UserExercise, $$UserExercisesTableReferences),
          UserExercise,
          PrefetchHooks Function({bool userExerciseLabelLinksRefs})
        > {
  $$UserExercisesTableTableManager(
    _$UserExerciseDatabase db,
    $UserExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isOverride = const Value.absent(),
                Value<String?> standardExerciseId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserExercisesCompanion(
                id: id,
                name: name,
                isOverride: isOverride,
                standardExerciseId: standardExerciseId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<bool> isOverride = const Value.absent(),
                Value<String?> standardExerciseId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UserExercisesCompanion.insert(
                id: id,
                name: name,
                isOverride: isOverride,
                standardExerciseId: standardExerciseId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userExerciseLabelLinksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (userExerciseLabelLinksRefs) db.userExerciseLabelLinks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (userExerciseLabelLinksRefs)
                    await $_getPrefetchedData<
                      UserExercise,
                      $UserExercisesTable,
                      UserExerciseLabelLink
                    >(
                      currentTable: table,
                      referencedTable: $$UserExercisesTableReferences
                          ._userExerciseLabelLinksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$UserExercisesTableReferences(
                            db,
                            table,
                            p0,
                          ).userExerciseLabelLinksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.exerciseId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$UserExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserExerciseDatabase,
      $UserExercisesTable,
      UserExercise,
      $$UserExercisesTableFilterComposer,
      $$UserExercisesTableOrderingComposer,
      $$UserExercisesTableAnnotationComposer,
      $$UserExercisesTableCreateCompanionBuilder,
      $$UserExercisesTableUpdateCompanionBuilder,
      (UserExercise, $$UserExercisesTableReferences),
      UserExercise,
      PrefetchHooks Function({bool userExerciseLabelLinksRefs})
    >;
typedef $$UserExerciseLabelsTableCreateCompanionBuilder =
    UserExerciseLabelsCompanion Function({
      required String id,
      required String name,
      Value<int> rowid,
    });
typedef $$UserExerciseLabelsTableUpdateCompanionBuilder =
    UserExerciseLabelsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> rowid,
    });

final class $$UserExerciseLabelsTableReferences
    extends
        BaseReferences<
          _$UserExerciseDatabase,
          $UserExerciseLabelsTable,
          UserExerciseLabel
        > {
  $$UserExerciseLabelsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $UserExerciseLabelLinksTable,
    List<UserExerciseLabelLink>
  >
  _userExerciseLabelLinksRefsTable(_$UserExerciseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.userExerciseLabelLinks,
        aliasName: $_aliasNameGenerator(
          db.userExerciseLabels.id,
          db.userExerciseLabelLinks.labelId,
        ),
      );

  $$UserExerciseLabelLinksTableProcessedTableManager
  get userExerciseLabelLinksRefs {
    final manager = $$UserExerciseLabelLinksTableTableManager(
      $_db,
      $_db.userExerciseLabelLinks,
    ).filter((f) => f.labelId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _userExerciseLabelLinksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UserExerciseLabelsTableFilterComposer
    extends Composer<_$UserExerciseDatabase, $UserExerciseLabelsTable> {
  $$UserExerciseLabelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> userExerciseLabelLinksRefs(
    Expression<bool> Function($$UserExerciseLabelLinksTableFilterComposer f) f,
  ) {
    final $$UserExerciseLabelLinksTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.userExerciseLabelLinks,
          getReferencedColumn: (t) => t.labelId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserExerciseLabelLinksTableFilterComposer(
                $db: $db,
                $table: $db.userExerciseLabelLinks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$UserExerciseLabelsTableOrderingComposer
    extends Composer<_$UserExerciseDatabase, $UserExerciseLabelsTable> {
  $$UserExerciseLabelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserExerciseLabelsTableAnnotationComposer
    extends Composer<_$UserExerciseDatabase, $UserExerciseLabelsTable> {
  $$UserExerciseLabelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> userExerciseLabelLinksRefs<T extends Object>(
    Expression<T> Function($$UserExerciseLabelLinksTableAnnotationComposer a) f,
  ) {
    final $$UserExerciseLabelLinksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.userExerciseLabelLinks,
          getReferencedColumn: (t) => t.labelId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserExerciseLabelLinksTableAnnotationComposer(
                $db: $db,
                $table: $db.userExerciseLabelLinks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$UserExerciseLabelsTableTableManager
    extends
        RootTableManager<
          _$UserExerciseDatabase,
          $UserExerciseLabelsTable,
          UserExerciseLabel,
          $$UserExerciseLabelsTableFilterComposer,
          $$UserExerciseLabelsTableOrderingComposer,
          $$UserExerciseLabelsTableAnnotationComposer,
          $$UserExerciseLabelsTableCreateCompanionBuilder,
          $$UserExerciseLabelsTableUpdateCompanionBuilder,
          (UserExerciseLabel, $$UserExerciseLabelsTableReferences),
          UserExerciseLabel,
          PrefetchHooks Function({bool userExerciseLabelLinksRefs})
        > {
  $$UserExerciseLabelsTableTableManager(
    _$UserExerciseDatabase db,
    $UserExerciseLabelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserExerciseLabelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserExerciseLabelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserExerciseLabelsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  UserExerciseLabelsCompanion(id: id, name: name, rowid: rowid),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => UserExerciseLabelsCompanion.insert(
                id: id,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserExerciseLabelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userExerciseLabelLinksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (userExerciseLabelLinksRefs) db.userExerciseLabelLinks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (userExerciseLabelLinksRefs)
                    await $_getPrefetchedData<
                      UserExerciseLabel,
                      $UserExerciseLabelsTable,
                      UserExerciseLabelLink
                    >(
                      currentTable: table,
                      referencedTable: $$UserExerciseLabelsTableReferences
                          ._userExerciseLabelLinksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$UserExerciseLabelsTableReferences(
                            db,
                            table,
                            p0,
                          ).userExerciseLabelLinksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.labelId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$UserExerciseLabelsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserExerciseDatabase,
      $UserExerciseLabelsTable,
      UserExerciseLabel,
      $$UserExerciseLabelsTableFilterComposer,
      $$UserExerciseLabelsTableOrderingComposer,
      $$UserExerciseLabelsTableAnnotationComposer,
      $$UserExerciseLabelsTableCreateCompanionBuilder,
      $$UserExerciseLabelsTableUpdateCompanionBuilder,
      (UserExerciseLabel, $$UserExerciseLabelsTableReferences),
      UserExerciseLabel,
      PrefetchHooks Function({bool userExerciseLabelLinksRefs})
    >;
typedef $$UserExerciseLabelLinksTableCreateCompanionBuilder =
    UserExerciseLabelLinksCompanion Function({
      required String exerciseId,
      required String labelId,
      Value<int> rowid,
    });
typedef $$UserExerciseLabelLinksTableUpdateCompanionBuilder =
    UserExerciseLabelLinksCompanion Function({
      Value<String> exerciseId,
      Value<String> labelId,
      Value<int> rowid,
    });

final class $$UserExerciseLabelLinksTableReferences
    extends
        BaseReferences<
          _$UserExerciseDatabase,
          $UserExerciseLabelLinksTable,
          UserExerciseLabelLink
        > {
  $$UserExerciseLabelLinksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UserExercisesTable _exerciseIdTable(_$UserExerciseDatabase db) =>
      db.userExercises.createAlias(
        $_aliasNameGenerator(
          db.userExerciseLabelLinks.exerciseId,
          db.userExercises.id,
        ),
      );

  $$UserExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$UserExercisesTableTableManager(
      $_db,
      $_db.userExercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UserExerciseLabelsTable _labelIdTable(_$UserExerciseDatabase db) =>
      db.userExerciseLabels.createAlias(
        $_aliasNameGenerator(
          db.userExerciseLabelLinks.labelId,
          db.userExerciseLabels.id,
        ),
      );

  $$UserExerciseLabelsTableProcessedTableManager get labelId {
    final $_column = $_itemColumn<String>('label_id')!;

    final manager = $$UserExerciseLabelsTableTableManager(
      $_db,
      $_db.userExerciseLabels,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_labelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserExerciseLabelLinksTableFilterComposer
    extends Composer<_$UserExerciseDatabase, $UserExerciseLabelLinksTable> {
  $$UserExerciseLabelLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$UserExercisesTableFilterComposer get exerciseId {
    final $$UserExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.userExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserExercisesTableFilterComposer(
            $db: $db,
            $table: $db.userExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UserExerciseLabelsTableFilterComposer get labelId {
    final $$UserExerciseLabelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labelId,
      referencedTable: $db.userExerciseLabels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserExerciseLabelsTableFilterComposer(
            $db: $db,
            $table: $db.userExerciseLabels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserExerciseLabelLinksTableOrderingComposer
    extends Composer<_$UserExerciseDatabase, $UserExerciseLabelLinksTable> {
  $$UserExerciseLabelLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$UserExercisesTableOrderingComposer get exerciseId {
    final $$UserExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.userExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.userExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UserExerciseLabelsTableOrderingComposer get labelId {
    final $$UserExerciseLabelsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labelId,
      referencedTable: $db.userExerciseLabels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserExerciseLabelsTableOrderingComposer(
            $db: $db,
            $table: $db.userExerciseLabels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserExerciseLabelLinksTableAnnotationComposer
    extends Composer<_$UserExerciseDatabase, $UserExerciseLabelLinksTable> {
  $$UserExerciseLabelLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$UserExercisesTableAnnotationComposer get exerciseId {
    final $$UserExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.userExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.userExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UserExerciseLabelsTableAnnotationComposer get labelId {
    final $$UserExerciseLabelsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.labelId,
          referencedTable: $db.userExerciseLabels,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserExerciseLabelsTableAnnotationComposer(
                $db: $db,
                $table: $db.userExerciseLabels,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$UserExerciseLabelLinksTableTableManager
    extends
        RootTableManager<
          _$UserExerciseDatabase,
          $UserExerciseLabelLinksTable,
          UserExerciseLabelLink,
          $$UserExerciseLabelLinksTableFilterComposer,
          $$UserExerciseLabelLinksTableOrderingComposer,
          $$UserExerciseLabelLinksTableAnnotationComposer,
          $$UserExerciseLabelLinksTableCreateCompanionBuilder,
          $$UserExerciseLabelLinksTableUpdateCompanionBuilder,
          (UserExerciseLabelLink, $$UserExerciseLabelLinksTableReferences),
          UserExerciseLabelLink,
          PrefetchHooks Function({bool exerciseId, bool labelId})
        > {
  $$UserExerciseLabelLinksTableTableManager(
    _$UserExerciseDatabase db,
    $UserExerciseLabelLinksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserExerciseLabelLinksTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$UserExerciseLabelLinksTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserExerciseLabelLinksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> exerciseId = const Value.absent(),
                Value<String> labelId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserExerciseLabelLinksCompanion(
                exerciseId: exerciseId,
                labelId: labelId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String exerciseId,
                required String labelId,
                Value<int> rowid = const Value.absent(),
              }) => UserExerciseLabelLinksCompanion.insert(
                exerciseId: exerciseId,
                labelId: labelId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserExerciseLabelLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exerciseId = false, labelId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable:
                                    $$UserExerciseLabelLinksTableReferences
                                        ._exerciseIdTable(db),
                                referencedColumn:
                                    $$UserExerciseLabelLinksTableReferences
                                        ._exerciseIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (labelId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.labelId,
                                referencedTable:
                                    $$UserExerciseLabelLinksTableReferences
                                        ._labelIdTable(db),
                                referencedColumn:
                                    $$UserExerciseLabelLinksTableReferences
                                        ._labelIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UserExerciseLabelLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$UserExerciseDatabase,
      $UserExerciseLabelLinksTable,
      UserExerciseLabelLink,
      $$UserExerciseLabelLinksTableFilterComposer,
      $$UserExerciseLabelLinksTableOrderingComposer,
      $$UserExerciseLabelLinksTableAnnotationComposer,
      $$UserExerciseLabelLinksTableCreateCompanionBuilder,
      $$UserExerciseLabelLinksTableUpdateCompanionBuilder,
      (UserExerciseLabelLink, $$UserExerciseLabelLinksTableReferences),
      UserExerciseLabelLink,
      PrefetchHooks Function({bool exerciseId, bool labelId})
    >;

class $UserExerciseDatabaseManager {
  final _$UserExerciseDatabase _db;
  $UserExerciseDatabaseManager(this._db);
  $$UserExercisesTableTableManager get userExercises =>
      $$UserExercisesTableTableManager(_db, _db.userExercises);
  $$UserExerciseLabelsTableTableManager get userExerciseLabels =>
      $$UserExerciseLabelsTableTableManager(_db, _db.userExerciseLabels);
  $$UserExerciseLabelLinksTableTableManager get userExerciseLabelLinks =>
      $$UserExerciseLabelLinksTableTableManager(
        _db,
        _db.userExerciseLabelLinks,
      );
}
