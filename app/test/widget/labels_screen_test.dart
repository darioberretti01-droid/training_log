import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_log_app/core/models/exercise_with_labels.dart';
import 'package:training_log_app/core/state/providers.dart';
import 'package:training_log_app/features/exercises/exercise_repository.dart';
import 'package:training_log_app/features/exercises/labels_screen.dart';

void main() {
  testWidgets('labels description uses ADD LABEL and not +add', (tester) async {
    await _pumpLabelsScreen(
      tester,
      catalog: const [
        LabelCatalogEntry(name: 'push', isStandard: true, isHidden: false),
      ],
    );

    expect(find.textContaining('ADD LABEL'), findsOneWidget);
    expect(find.textContaining('+add'), findsNothing);
  });

  testWidgets('visible labels are rendered as non-selectable pill chips', (
    tester,
  ) async {
    await _pumpLabelsScreen(
      tester,
      catalog: const [
        LabelCatalogEntry(name: 'push', isStandard: true, isHidden: false),
      ],
    );

    expect(find.widgetWithText(InputChip, 'push'), findsOneWidget);
    expect(find.byType(FilterChip), findsNothing);
  });

  testWidgets('standard label remove opens hide dialog copy', (tester) async {
    await _pumpLabelsScreen(
      tester,
      catalog: const [
        LabelCatalogEntry(name: 'push', isStandard: true, isHidden: false),
      ],
    );

    await tester.tap(find.byKey(const Key('label_remove_push')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'This label is is a standard app label. It will not be deleted, but you can hide it.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Hide'), findsOneWidget);
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

  testWidgets('show hidden toggle reveals hidden labels with restore action', (
    tester,
  ) async {
    await _pumpLabelsScreen(
      tester,
      catalog: const [
        LabelCatalogEntry(name: 'push', isStandard: true, isHidden: true),
      ],
    );

    expect(find.text('push'), findsNothing);
    await tester.tap(find.byKey(const Key('labels_toggle_hidden_button')));
    await tester.pumpAndSettle();

    expect(find.text('push'), findsOneWidget);
    expect(find.byKey(const Key('label_restore_push')), findsOneWidget);
  });

  testWidgets('restore then undo re-hides hidden standard label', (tester) async {
    final repository = _FakeExerciseRepository();
    await _pumpLabelsScreen(
      tester,
      catalog: const [
        LabelCatalogEntry(name: 'push', isStandard: true, isHidden: true),
      ],
      repository: repository,
    );

    await tester.tap(find.byKey(const Key('labels_toggle_hidden_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('label_restore_push')));
    await tester.pumpAndSettle();

    expect(repository.unhiddenLabels, contains('push'));

    await tester.tap(find.byKey(const Key('labels_undo_button')));
    await tester.pumpAndSettle();

    expect(repository.hiddenLabels, contains('push'));
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
        exercisesProvider.overrideWith((ref) => Stream.value(const <ExerciseWithLabels>[])),
      ],
      child: const MaterialApp(home: LabelsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeExerciseRepository implements ExerciseRepository {
  final List<String> hiddenLabels = [];
  final List<String> unhiddenLabels = [];

  @override
  Future<String> createExercise({
    required String name,
    required List<String> labels,
  }) async => 'custom';

  @override
  Future<bool> createLabel(String label) async => true;

  @override
  Future<DeletedCustomLabelSnapshot?> deleteCustomLabel(String label) async =>
      DeletedCustomLabelSnapshot(labelName: label, linkedExerciseIds: const []);

  @override
  Future<ExerciseWithLabels?> getById(String id) async => null;

  @override
  Future<List<String>> getAllLabels() async => const [];

  @override
  Future<bool> hideStandardLabel(String label) async {
    hiddenLabels.add(label);
    return true;
  }

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
  Future<bool> unhideStandardLabel(String label) async {
    unhiddenLabels.add(label);
    return true;
  }

  @override
  Stream<List<String>> watchAllLabels() => Stream.value(const []);

  @override
  Stream<List<LabelCatalogEntry>> watchLabelCatalog() => Stream.value(const []);

  @override
  Stream<List<ExerciseWithLabels>> watchExercises() => Stream.value(const []);
}
