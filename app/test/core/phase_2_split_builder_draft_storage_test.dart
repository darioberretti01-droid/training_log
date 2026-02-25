import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/core/db/app_database.dart';
import 'package:training_log_app/features/splits/split_builder_draft.dart';
import 'package:training_log_app/features/splits/split_builder_draft_storage.dart';

void main() {
  late AppDatabase database;
  late SplitBuilderDraftStorage storage;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    storage = SplitBuilderDraftStorage(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'saveDraft + loadDraft roundtrip persists split builder draft',
    () async {
      final draft = SplitBuilderDraft(
        splitName: 'Upper Lower',
        setAsActive: true,
        selectedVolumeControlLabels: const ['chest', 'back'],
        manuallyCreatedControlLabels: const ['forearms'],
        updatedAtMs: DateTime(2026, 2, 25, 10, 15).millisecondsSinceEpoch,
        days: const [
          SplitBuilderDayDraft(
            title: 'Upper A',
            plannedExercises: [
              SplitBuilderPlannedExerciseDraft(
                selectedExerciseId: 'bench_press',
                sets: '4',
                repMin: '6',
                repMax: '10',
                rest: '120',
                rpe: '8',
              ),
            ],
          ),
        ],
      );

      await storage.saveDraft(draft);
      final loaded = await storage.loadDraft();

      expect(loaded, isNotNull);
      expect(loaded!.splitName, 'Upper Lower');
      expect(loaded.days, hasLength(1));
      expect(loaded.days.first.title, 'Upper A');
      expect(loaded.days.first.plannedExercises, hasLength(1));
      expect(
        loaded.days.first.plannedExercises.first.selectedExerciseId,
        'bench_press',
      );
      expect(loaded.manuallyCreatedControlLabels, contains('forearms'));
    },
  );

  test('clearDraft removes previously saved split builder draft', () async {
    final draft = SplitBuilderDraft(
      splitName: 'PPL',
      setAsActive: false,
      selectedVolumeControlLabels: const ['chest'],
      manuallyCreatedControlLabels: const [],
      updatedAtMs: DateTime(2026, 2, 25, 11, 0).millisecondsSinceEpoch,
      days: const [],
    );

    await storage.saveDraft(draft);
    await storage.clearDraft();
    final loaded = await storage.loadDraft();

    expect(loaded, isNull);
  });
}
