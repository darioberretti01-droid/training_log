import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/core/db/app_database.dart';
import 'package:training_log_app/core/db/user_exercise_database.dart';
import 'package:training_log_app/features/exercises/exercise_repository.dart';

void main() {
  late AppDatabase database;
  late UserExerciseDatabase userExerciseDatabase;
  late DriftExerciseRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    userExerciseDatabase = UserExerciseDatabase(NativeDatabase.memory());
    repository = DriftExerciseRepository(database, userExerciseDatabase);
  });

  tearDown(() async {
    await userExerciseDatabase.close();
    await database.close();
  });

  test('createExercise stores a custom exercise and mirrors it into main DB', () async {
    final exerciseId = await repository.createExercise(
      name: 'Cable Fly',
      labels: const ['chest', 'isolation'],
    );

    final custom = await repository.getById(exerciseId);
    expect(custom, isNotNull);
    expect(custom!.isStandard, false);
    expect(custom.labels, ['chest', 'isolation']);

    final mirrored = await (database.select(
      database.exercises,
    )..where((tbl) => tbl.id.equals(exerciseId))).getSingleOrNull();
    expect(mirrored, isNotNull);
    expect(mirrored!.isSeeded, false);
  });

  test('standard labels can be overridden and restored', () async {
    await repository.seedIfEmpty();

    final standard = await repository.getById('bench_press');
    expect(standard, isNotNull);
    expect(standard!.isStandard, true);
    expect(standard.hasCustomLabelOverride, false);

    await repository.saveLabels(
      exerciseId: 'bench_press',
      labels: const ['push', 'pecs'],
    );

    final overridden = await repository.getById('bench_press');
    expect(overridden, isNotNull);
    expect(overridden!.isStandard, true);
    expect(overridden.hasCustomLabelOverride, true);
    expect(overridden.labels, ['pecs', 'push']);
    expect(overridden.lookupExerciseIds, hasLength(2));

    await repository.restoreStandardLabels('bench_press');

    final restored = await repository.getById('bench_press');
    expect(restored, isNotNull);
    expect(restored!.isStandard, true);
    expect(restored.hasCustomLabelOverride, false);
    expect(restored.labels, contains('chest'));
    expect(restored.labels, isNot(contains('pecs')));
    expect(restored.lookupExerciseIds, ['bench_press']);
  });

  test('createLabel adds label to global label catalog', () async {
    await repository.seedIfEmpty();

    final created = await repository.createLabel('forearms');

    expect(created, true);
    final labels = await repository.getAllLabels();
    expect(labels, contains('forearms'));
  });

  test('hide and unhide standard label updates visible and catalog states', () async {
    await repository.seedIfEmpty();

    final hidden = await repository.hideStandardLabel('push');
    expect(hidden, true);

    final visibleLabels = await repository.getAllLabels();
    expect(visibleLabels, isNot(contains('push')));

    final catalog = await repository.watchLabelCatalog().first;
    final pushEntry = catalog.firstWhere((entry) => entry.name == 'push');
    expect(pushEntry.isStandard, true);
    expect(pushEntry.isHidden, true);

    final unhidden = await repository.unhideStandardLabel('push');
    expect(unhidden, true);

    final visibleAfterRestore = await repository.getAllLabels();
    expect(visibleAfterRestore, contains('push'));
  });

  test('delete custom label returns snapshot and can be restored', () async {
    await repository.seedIfEmpty();

    final exerciseId = await repository.createExercise(
      name: 'Custom',
      labels: const ['forearms'],
    );

    final beforeDelete = await repository.getById(exerciseId);
    expect(beforeDelete, isNotNull);
    expect(beforeDelete!.labels, contains('forearms'));

    final snapshot = await repository.deleteCustomLabel('forearms');
    expect(snapshot, isNotNull);

    final afterDelete = await repository.getById(exerciseId);
    expect(afterDelete, isNotNull);
    expect(afterDelete!.labels, isNot(contains('forearms')));

    await repository.restoreDeletedCustomLabel(snapshot!);

    final afterRestore = await repository.getById(exerciseId);
    expect(afterRestore, isNotNull);
    expect(afterRestore!.labels, contains('forearms'));
  });

  test('standard exercise can be hidden and unhidden', () async {
    await repository.seedIfEmpty();

    final hidden = await repository.hideStandardExercise('bench_press');
    expect(hidden, true);

    final hiddenEntry = await repository.getById('bench_press');
    expect(hiddenEntry, isNotNull);
    expect(hiddenEntry!.isHidden, true);

    final unhidden = await repository.unhideStandardExercise('bench_press');
    expect(unhidden, true);

    final visibleEntry = await repository.getById('bench_press');
    expect(visibleEntry, isNotNull);
    expect(visibleEntry!.isHidden, false);
  });

  test('custom exercise can be deleted from visible catalog', () async {
    final exerciseId = await repository.createExercise(
      name: 'Custom Pullover',
      labels: const ['back'],
    );

    final beforeDelete = await repository.getById(exerciseId);
    expect(beforeDelete, isNotNull);

    final deleted = await repository.deleteCustomExercise(exerciseId);
    expect(deleted, true);

    final afterDelete = await repository.getById(exerciseId);
    expect(afterDelete, isNull);
  });
}
