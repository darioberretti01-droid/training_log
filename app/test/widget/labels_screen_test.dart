import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/core/models/exercise_with_labels.dart';
import 'package:training_log_app/core/state/providers.dart';
import 'package:training_log_app/features/exercises/exercise_repository.dart';
import 'package:training_log_app/features/exercises/labels_screen.dart';

import '../test_helpers/localized_test_app.dart';

void main() {
  testWidgets('labels description includes delete rule for added labels', (
    tester,
  ) async {
    await _pumpLabelsScreen(
      tester,
      catalog: const [
        LabelCatalogEntry(name: 'push', isStandard: true, isHidden: false),
      ],
    );

    expect(find.textContaining('ADD LABEL'), findsOneWidget);
    expect(find.text('Only added labels can be deleted.'), findsOneWidget);
  });

  testWidgets('standard labels have no remove x action', (tester) async {
    await _pumpLabelsScreen(
      tester,
      catalog: const [
        LabelCatalogEntry(name: 'push', isStandard: true, isHidden: false),
      ],
    );

    final chipFinder = find.widgetWithText(InputChip, 'push');
    expect(chipFinder, findsOneWidget);
    expect(find.byKey(const Key('label_remove_push')), findsNothing);
    final chip = tester.widget<InputChip>(chipFinder);
    expect(chip.materialTapTargetSize, MaterialTapTargetSize.shrinkWrap);
    expect(chip.visualDensity, VisualDensity.compact);
  });

  testWidgets('custom label remove opens delete dialog copy', (tester) async {
    await _pumpLabelsScreen(
      tester,
      catalog: const [
        LabelCatalogEntry(name: 'forearms', isStandard: false, isHidden: false),
      ],
    );

    await tester.tap(find.byKey(const Key('label_remove_forearms')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Are you sure to delete this label? When you exit the Labels screen, it will not be possible to restore it.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Delete'), findsOneWidget);
  });

  testWidgets('show hidden labels button is removed and redo is present', (
    tester,
  ) async {
    await _pumpLabelsScreen(
      tester,
      catalog: const [
        LabelCatalogEntry(name: 'push', isStandard: true, isHidden: false),
      ],
    );

    expect(find.byKey(const Key('labels_toggle_hidden_button')), findsNothing);
    expect(find.byKey(const Key('labels_redo_button')), findsOneWidget);
  });

  testWidgets('undo enables redo for add-label action', (tester) async {
    final repository = _FakeExerciseRepository();
    await _pumpLabelsScreen(
      tester,
      catalog: const [
        LabelCatalogEntry(name: 'push', isStandard: true, isHidden: false),
      ],
      repository: repository,
    );

    await tester.tap(find.byKey(const Key('labels_add_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'forearms');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    final redoBefore = tester.widget<OutlinedButton>(
      find.byKey(const Key('labels_redo_button')),
    );
    expect(redoBefore.onPressed, isNull);

    await tester.tap(find.byKey(const Key('labels_undo_button')));
    await tester.pumpAndSettle();

    final redoAfter = tester.widget<OutlinedButton>(
      find.byKey(const Key('labels_redo_button')),
    );
    expect(redoAfter.onPressed, isNotNull);
  });
}

Future<void> _pumpLabelsScreen(
  WidgetTester tester, {
  required List<LabelCatalogEntry> catalog,
  _FakeExerciseRepository? repository,
}) async {
  final fakeRepository = repository ?? _FakeExerciseRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        seedDataProvider.overrideWith((ref) async {}),
        labelCatalogProvider.overrideWith((ref) => Stream.value(catalog)),
        exerciseRepositoryProvider.overrideWithValue(fakeRepository),
        allLabelsProvider.overrideWith((ref) => Stream.value(const ['push'])),
        exercisesProvider.overrideWith(
          (ref) => Stream.value(const <ExerciseWithLabels>[]),
        ),
      ],
      child: localizedTestApp(home: const LabelsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeExerciseRepository implements ExerciseRepository {
  final List<String> createdLabels = [];
  final List<String> deletedLabels = [];

  @override
  Future<String> createExercise({
    required String name,
    required List<String> labels,
  }) async => 'custom';

  @override
  Future<bool> createLabel(String label) async {
    createdLabels.add(label);
    return true;
  }

  @override
  Future<DeletedCustomLabelSnapshot?> deleteCustomLabel(String label) async {
    deletedLabels.add(label);
    return DeletedCustomLabelSnapshot(
      labelName: label,
      linkedExerciseIds: const [],
    );
  }

  @override
  Future<bool> deleteCustomExercise(String exerciseId) async => true;

  @override
  Future<ExerciseWithLabels?> getById(String id) async => null;

  @override
  Future<List<String>> getAllLabels() async => const [];

  @override
  Future<bool> hideStandardExercise(String standardExerciseId) async => true;

  @override
  Future<bool> hideStandardLabel(String label) async => true;

  @override
  Future<void> restoreDeletedCustomLabel(
    DeletedCustomLabelSnapshot snapshot,
  ) async {}

  @override
  Future<void> restoreStandardLabels(String standardExerciseId) async {}

  @override
  Future<void> saveLabels({
    required String exerciseId,
    required List<String> labels,
  }) async {}

  @override
  Future<void> seedIfEmpty() async {}

  @override
  Future<bool> unhideStandardExercise(String standardExerciseId) async => true;

  @override
  Future<bool> unhideStandardLabel(String label) async => true;

  @override
  Stream<List<String>> watchAllLabels() => Stream.value(const []);

  @override
  Stream<List<LabelCatalogEntry>> watchLabelCatalog() => Stream.value(const []);

  @override
  Stream<List<ExerciseWithLabels>> watchExercises() => Stream.value(const []);
}
