import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/core/db/app_database.dart';
import 'package:training_log_app/core/models/exercise_with_labels.dart';
import 'package:training_log_app/core/state/providers.dart';
import 'package:training_log_app/features/splits/split_builder_draft.dart';
import 'package:training_log_app/features/splits/split_builder_draft_storage.dart';
import 'package:training_log_app/features/splits/split_builder_screen.dart';
import 'package:training_log_app/features/splits/split_repository.dart';

void main() {
  testWidgets(
    'split builder shows validation when required fields are missing',
    (tester) async {
      final repository = _FakeSplitRepository();
      await _pumpSplitBuilder(tester, repository);

      await tester.tap(find.byKey(const Key('split_builder_save')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('split_builder_volume_overview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('split_volume_control_labels_button')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('split_volume_control_labels_button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('split_volume_control_labels_dialog')),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilterChip, 'chest'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'back'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'glutes'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Split name is required.'), findsOneWidget);
      expect(repository.createCalls, 0);
    },
  );

  testWidgets('split builder saves a split and sets it active by default', (
    tester,
  ) async {
    final repository = _FakeSplitRepository();
    await _pumpSplitBuilder(tester, repository);

    await tester.enterText(
      find.byKey(const Key('split_name_field')),
      'Upper Lower',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('day_1_title')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(const Key('day_1_title')), 'Upper A');

    await tester.scrollUntilVisible(
      find.byKey(const Key('day_1_exercise_1')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('day_1_exercise_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbell Bench Press').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('split_builder_save')));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(repository.setActiveCalls, 1);
    expect(repository.lastInput, isNotNull);
    expect(repository.lastInput!.name, 'Upper Lower');
    expect(repository.lastInput!.days, hasLength(1));
    expect(repository.lastInput!.days.first.dayIndex, 1);
    expect(repository.lastInput!.days.first.title, 'Upper A');
    expect(repository.lastInput!.days.first.plannedExercises, hasLength(1));
    expect(
      repository.lastInput!.days.first.plannedExercises.first.exerciseId,
      'bench_press',
    );
    expect(
      repository.lastInput!.days.first.plannedExercises.first.orderIndex,
      1,
    );
  });

  testWidgets('hidden exercises are excluded from split builder selector', (
    tester,
  ) async {
    final repository = _FakeSplitRepository();
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seedDataProvider.overrideWith((ref) async {}),
          exercisesProvider.overrideWith(
            (ref) => Stream.value(const [
              ExerciseWithLabels(
                id: 'bench_press',
                name: 'Barbell Bench Press',
                labels: ['push', 'chest'],
              ),
              ExerciseWithLabels(
                id: 'pull_up',
                name: 'Pull-Up',
                labels: ['pull', 'back'],
                isHidden: true,
              ),
            ]),
          ),
          splitRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: SplitBuilderScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('day_1_exercise_1')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('day_1_exercise_1')));
    await tester.pumpAndSettle();

    expect(find.text('Barbell Bench Press'), findsWidgets);
    expect(find.text('Pull-Up'), findsNothing);
  });

  testWidgets('editing split preloads values and calls updateSplit', (
    tester,
  ) async {
    final repository = _FakeSplitRepository()
      ..detailsById['split_1'] = const SplitDetails(
        id: 'split_1',
        name: 'Upper Lower',
        isActive: true,
        createdAt: 1,
        updatedAt: 1,
        days: [
          DayPlanDetails(
            id: 'day_1',
            dayIndex: 1,
            title: 'Upper A',
            plannedExercises: [
              PlannedExerciseDetails(
                id: 'planned_1',
                orderIndex: 1,
                exerciseId: 'bench_press',
                exerciseName: 'Barbell Bench Press',
                targetSets: 3,
                repMin: 8,
                repMax: 12,
                restSeconds: null,
                targetRpe: null,
              ),
            ],
          ),
        ],
      );
    final draftDatabase = AppDatabase(NativeDatabase.memory());
    addTearDown(draftDatabase.close);
    final draftStorage = SplitBuilderDraftStorage(draftDatabase);
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seedDataProvider.overrideWith((ref) async {}),
          exercisesProvider.overrideWith(
            (ref) => Stream.value(const [
              ExerciseWithLabels(
                id: 'bench_press',
                name: 'Barbell Bench Press',
                labels: ['push', 'chest'],
              ),
              ExerciseWithLabels(
                id: 'pull_up',
                name: 'Pull-Up',
                labels: ['pull', 'back'],
              ),
            ]),
          ),
          splitRepositoryProvider.overrideWithValue(repository),
          splitBuilderDraftStorageProvider.overrideWithValue(draftStorage),
        ],
        child: const MaterialApp(
          home: SplitBuilderScreen(editingSplitId: 'split_1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Split'), findsOneWidget);
    expect(find.text('Upper Lower'), findsOneWidget);
    expect(find.text('Upper A'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('split_name_field')),
      'Updated UL',
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('day_1_add_exercise')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('day_1_add_exercise')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('day_1_exercise_2')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('day_1_exercise_2')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('day_1_exercise_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pull-Up').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('split_builder_save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(repository.updateCalls, 1);
    expect(repository.lastUpdatedSplitId, 'split_1');
    expect(repository.lastUpdatedInput, isNotNull);
    expect(repository.lastUpdatedInput!.name, 'Updated UL');
    expect(
      repository.lastUpdatedInput!.days.single.plannedExercises,
      hasLength(2),
    );
    expect(
      repository.lastUpdatedInput!.days.single.plannedExercises[1].exerciseId,
      'pull_up',
    );
    expect(
      repository.lastUpdatedInput!.days.single.plannedExercises[1].orderIndex,
      2,
    );
    expect(repository.createCalls, 0);
  });

  testWidgets('split builder resumeDraft restores saved draft values', (
    tester,
  ) async {
    final repository = _FakeSplitRepository();
    final database = AppDatabase(NativeDatabase.memory());
    final storage = SplitBuilderDraftStorage(database);
    await storage.saveDraft(
      const SplitBuilderDraft(
        splitName: 'Saved split draft',
        setAsActive: true,
        selectedVolumeControlLabels: ['back', 'chest'],
        manuallyCreatedControlLabels: ['forearms'],
        updatedAtMs: 1,
        days: [
          SplitBuilderDayDraft(
            title: 'Day from draft',
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
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seedDataProvider.overrideWith((ref) async {}),
          exercisesProvider.overrideWith(
            (ref) => Stream.value(const [
              ExerciseWithLabels(
                id: 'bench_press',
                name: 'Barbell Bench Press',
                labels: ['push', 'chest'],
              ),
            ]),
          ),
          splitRepositoryProvider.overrideWithValue(repository),
          splitBuilderDraftStorageProvider.overrideWithValue(storage),
        ],
        child: const MaterialApp(home: SplitBuilderScreen(resumeDraft: true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saved split draft'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('day_1_exercise_1')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('day_1_exercise_1')), findsOneWidget);
  });

  testWidgets('split builder persists draft when leaving screen', (
    tester,
  ) async {
    final repository = _FakeSplitRepository();
    final database = AppDatabase(NativeDatabase.memory());
    final storage = SplitBuilderDraftStorage(database);

    await _pumpSplitBuilder(
      tester,
      repository,
      storage: storage,
      resumeDraft: false,
    );

    await tester.enterText(
      find.byKey(const Key('split_name_field')),
      'Draft to persist',
    );
    await tester.enterText(find.byKey(const Key('day_1_title')), 'Draft day');
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final loaded = await storage.loadDraft();
    expect(loaded, isNotNull);
    expect(loaded!.splitName, 'Draft to persist');
    expect(loaded.days.first.title, 'Draft day');
  });

  testWidgets('split builder can erase current split draft', (tester) async {
    final repository = _FakeSplitRepository();
    final database = AppDatabase(NativeDatabase.memory());
    final storage = SplitBuilderDraftStorage(database);
    await storage.saveDraft(
      const SplitBuilderDraft(
        splitName: 'Draft to erase',
        setAsActive: true,
        selectedVolumeControlLabels: ['chest'],
        manuallyCreatedControlLabels: [],
        updatedAtMs: 1,
        days: [
          SplitBuilderDayDraft(
            title: 'Day 1',
            plannedExercises: [
              SplitBuilderPlannedExerciseDraft(
                selectedExerciseId: 'bench_press',
                sets: '3',
                repMin: '8',
                repMax: '12',
                rest: '',
                rpe: '',
              ),
            ],
          ),
        ],
      ),
    );

    await _pumpSplitBuilder(
      tester,
      repository,
      storage: storage,
      resumeDraft: true,
    );

    expect(find.text('Draft to erase'), findsOneWidget);

    await tester.tap(find.byKey(const Key('split_builder_erase_draft')));
    await tester.pumpAndSettle();
    expect(find.text('Erase split draft?'), findsOneWidget);
    expect(
      find.text(
        'You are erasing the current split draft. Do you want to continue?',
      ),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Erase'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Draft to erase'), findsOneWidget);

    await tester.tap(find.byKey(const Key('split_builder_erase_draft')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erase'));
    await tester.pumpAndSettle();

    expect(find.text('Draft to erase'), findsNothing);
    final loaded = await storage.loadDraft();
    expect(loaded, isNull);
  });
}

Future<void> _pumpSplitBuilder(
  WidgetTester tester,
  _FakeSplitRepository repository, {
  SplitBuilderDraftStorage? storage,
  bool resumeDraft = false,
}) async {
  AppDatabase? ownedDatabase;
  final effectiveStorage =
      storage ??
      (() {
        ownedDatabase = AppDatabase(NativeDatabase.memory());
        return SplitBuilderDraftStorage(ownedDatabase!);
      })();
  if (ownedDatabase != null) {
    addTearDown(ownedDatabase!.close);
  }

  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        seedDataProvider.overrideWith((ref) async {}),
        exercisesProvider.overrideWith(
          (ref) => Stream.value(const [
            ExerciseWithLabels(
              id: 'bench_press',
              name: 'Barbell Bench Press',
              labels: ['push', 'chest'],
            ),
          ]),
        ),
        splitRepositoryProvider.overrideWithValue(repository),
        splitBuilderDraftStorageProvider.overrideWithValue(effectiveStorage),
      ],
      child: MaterialApp(home: SplitBuilderScreen(resumeDraft: resumeDraft)),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeSplitRepository implements SplitRepository {
  int createCalls = 0;
  int updateCalls = 0;
  int setActiveCalls = 0;
  SplitDraftInput? lastInput;
  String? lastUpdatedSplitId;
  SplitDraftInput? lastUpdatedInput;
  final Map<String, SplitDetails> detailsById = {};

  @override
  Future<String> createSplit(SplitDraftInput input) async {
    createCalls += 1;
    lastInput = input;
    return 'split_1';
  }

  @override
  Future<void> deleteSplit(String splitId) async {}

  @override
  Future<SplitDetails?> getSplitById(String splitId) async =>
      detailsById[splitId];

  @override
  Future<void> setActiveSplit(String splitId) async {
    setActiveCalls += 1;
  }

  @override
  Future<void> updateSplit(String splitId, SplitDraftInput input) async {
    updateCalls += 1;
    lastUpdatedSplitId = splitId;
    lastUpdatedInput = input;
  }

  @override
  Stream<List<SplitSummary>> watchSplits() {
    return Stream.value(const []);
  }
}
